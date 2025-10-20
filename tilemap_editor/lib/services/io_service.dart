import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';
import 'package:lepiengine_tilemap_editor/models/index.dart';

Future<void> saveProject(BuildContext context, EditorController c) async {
  String? targetPath = c.currentFilePath;

  if (targetPath == null) {
    targetPath = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      dialogTitle: 'Save Tilemap Project',
      fileName: 'tilemap.json',
    );
    if (targetPath == null) return; // usuário cancelou
  }

  final String baseDir = File(targetPath).parent.path;
  final Map<String, dynamic> json = _serializeProject(c, baseDir: baseDir);
  final String content = const JsonEncoder.withIndent('  ').convert(json);
  await File(targetPath).writeAsString(content);
  c.markSaved(targetPath);
  _showSaveToast(context, targetPath);
}

Future<void> saveProjectAs(BuildContext context, EditorController c) async {
  final String? targetPath = await FilePicker.platform.saveFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    dialogTitle: 'Save Tilemap Project As',
    fileName: 'tilemap.json',
  );
  if (targetPath == null) return;

  final String baseDir = File(targetPath).parent.path;
  final Map<String, dynamic> json = _serializeProject(c, baseDir: baseDir);
  final String content = const JsonEncoder.withIndent('  ').convert(json);
  await File(targetPath).writeAsString(content);
  c.markSaved(targetPath);
  _showSaveToast(context, targetPath);
}

Future<void> openProject(BuildContext context, EditorController c) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    allowMultiple: false,
    withData: true,
  );
  if (result == null) return;
  final file = result.files.single;
  final String? path = file.path;
  Uint8List? bytes = file.bytes;
  if (bytes == null && path != null) {
    bytes = await File(path).readAsBytes();
  }
  if (bytes == null) return;

  final Map<String, dynamic> decoded =
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

  // Carrega tilesets antes de aplicar camadas
  final String baseDir = path != null
      ? File(path).parent.path
      : Directory.current.path;
  final List<dynamic> tilesetsJson =
      (decoded['tilesets'] as List<dynamic>? ?? const []);

  // Limpa tilesets atuais e recarrega
  for (final t in tilesetsJson) {
    final Map<String, dynamic> tj = (t as Map).cast<String, dynamic>();
    final String id = tj['id'] as String;
    final String name = tj['name'] as String? ?? id;
    final Map<String, dynamic>? px = (tj['tilePixelSize'] as Map?)
        ?.cast<String, dynamic>();
    final double? tileW = (px?['width'] as num?)?.toDouble();
    final double? tileH = (px?['height'] as num?)?.toDouble();
    final String rel = tj['path'] as String;
    final String abs = _resolveRelativePath(baseDir, rel);
    final _ImageWithProvider img = await _loadImageFromFile(abs);
    c.addTilesetWithId(
      id: id,
      name: name,
      image: img.image,
      provider: img.provider,
      path: abs,
    );
    if (tileW != null && tileH != null) {
      c.setTilePixelSize(width: tileW, height: tileH);
    }
  }

  c.applySerializedMap(decoded, filePath: path);
}

void _showSaveToast(BuildContext context, String path) {
  showToast(
    context: context,
    builder: (ctx, overlay) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            spacing: 8,
            children: [
              const Icon(lucide.LucideIcons.check, size: 14),
              Expanded(child: Text('Saved to $path').small),
            ],
          ),
        ),
      );
    },
    location: ToastLocation.bottomRight,
  );
}

Map<String, dynamic> _serializeProject(
  EditorController c, {
  required String baseDir,
}) {
  return <String, dynamic>{
    'schemaVersion': 1,
    'meta': <String, dynamic>{
      'app': 'lepiengine_tilemap_editor',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
    'map': <String, dynamic>{
      'size': <String, dynamic>{'width': c.tilesX, 'height': c.tilesY},
      'tilePixelSize': <String, dynamic>{
        'width': c.tilePixelWidth,
        'height': c.tilePixelHeight,
      },
      'worldTileSize': <String, dynamic>{
        'width': c.tilePixelWidth,
        'height': c.tilePixelHeight,
      },
    },
    'tilesets': c.tilesets
        .map(
          (t) => <String, dynamic>{
            'id': t.id,
            'name': t.name,
            // Sempre grava caminho absoluto quando disponível
            'path': _toAbsolute(t.path, baseDir) ?? t.name,
            'tilePixelSize': <String, dynamic>{
              'width': c.tilePixelWidth,
              'height': c.tilePixelHeight,
            },
          },
        )
        .toList(),
    'layers': c.layers.map((l) => _serializeLayerSparse(l)).toList(),
  };
}

Map<String, dynamic> _serializeLayerSparse(LayerData l) {
  return <String, dynamic>{
    'name': l.name,
    'visible': l.visible,
    'showCollisions': l.showCollisions,
    'tilesetId': l.tilesetId,
    'tiles': _collectFilledTiles(l),
    'collisions': _collectCollisions(l),
  };
}

List<Map<String, int>> _collectFilledTiles(LayerData l) {
  final List<Map<String, int>> out = <Map<String, int>>[];
  for (int y = 0; y < l.tiles.length; y++) {
    final row = l.tiles[y];
    for (int x = 0; x < row.length; x++) {
      final t = row[x];
      if (t != null) {
        out.add(<String, int>{'x': x, 'y': y, 'tx': t.tileX, 'ty': t.tileY});
      }
    }
  }
  return out;
}

List<Map<String, int>> _collectCollisions(LayerData l) {
  final List<Map<String, int>> out = <Map<String, int>>[];
  for (int y = 0; y < l.collisions.length; y++) {
    final row = l.collisions[y];
    for (int x = 0; x < row.length; x++) {
      if (row[x] == true) out.add(<String, int>{'x': x, 'y': y});
    }
  }
  return out;
}

String _resolveRelativePath(String baseDir, String relative) {
  return File(relative).isAbsolute ? relative : File('$baseDir/$relative').path;
}

String? _toAbsolute(String? tilesetPath, String baseDir) {
  if (tilesetPath == null || tilesetPath.isEmpty) return null;
  return File(tilesetPath).isAbsolute
      ? tilesetPath
      : File('$baseDir/$tilesetPath').path;
}

class _ImageWithProvider {
  final ui.Image image;
  final ImageProvider provider;
  _ImageWithProvider(this.image, this.provider);
}

Future<_ImageWithProvider> _loadImageFromFile(String path) async {
  final bytes = await File(path).readAsBytes();
  final uiImage = await _decodeImage(bytes);
  return _ImageWithProvider(uiImage, MemoryImage(bytes));
}

Future<ui.Image> _decodeImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
