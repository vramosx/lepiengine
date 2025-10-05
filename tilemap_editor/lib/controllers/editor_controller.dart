import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' show ImageProvider;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TileRef {
  final int tileX;
  final int tileY;

  const TileRef({required this.tileX, required this.tileY});
}

class TileSelection {
  final int startX;
  final int startY;
  final int endX;
  final int endY;

  const TileSelection({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  int get width => (endX - startX).abs() + 1;
  int get height => (endY - startY).abs() + 1;

  TileSelection normalized() {
    final int nx = startX <= endX ? startX : endX;
    final int ny = startY <= endY ? startY : endY;
    final int ex = startX <= endX ? endX : startX;
    final int ey = startY <= endY ? endY : startY;
    return TileSelection(startX: nx, startY: ny, endX: ex, endY: ey);
  }
}

class TilesetDef {
  final String id;
  final String name;
  final ui.Image image;
  final ImageProvider provider;

  const TilesetDef({
    required this.id,
    required this.name,
    required this.image,
    required this.provider,
  });
}

class LayerData {
  final String name;
  final List<List<TileRef?>> tiles; // [y][x]
  String? tilesetId; // referência ao tileset selecionado
  TileSelection? selection; // seleção de tiles no tileset

  LayerData({
    required this.name,
    required int width,
    required int height,
    this.tilesetId,
    this.selection,
  }) : tiles = List.generate(
         height,
         (_) => List<TileRef?>.filled(width, null, growable: false),
         growable: false,
       );
}

class EditorController extends ChangeNotifier {
  // Grid/display configuration
  int tilesX = 32;
  int tilesY = 32;
  double tileSize = 32; // display size in editor canvas

  // Tileset slicing (source tiles) - global para o projeto
  double tilePixelWidth = 32;
  double tilePixelHeight = 32;

  // Registro de tilesets
  final List<TilesetDef> _tilesets = [];

  // Seleção legacy (mantida por compatibilidade com UI antiga)
  int? selectedTileX;
  int? selectedTileY;

  // Layers
  final List<LayerData> _layers = [
    LayerData(name: 'Sky', width: 32, height: 32),
    LayerData(name: 'Building', width: 32, height: 32),
    LayerData(name: 'Over Ground', width: 32, height: 32),
    LayerData(name: 'Ground', width: 32, height: 32),
  ];
  int _selectedLayerIndex = 0;

  List<LayerData> get layers => _layers;
  List<String> get layerNames =>
      _layers.map((e) => e.name).toList(growable: false);
  int get selectedLayerIndex => _selectedLayerIndex;

  LayerData? get selectedLayer =>
      (_selectedLayerIndex >= 0 && _selectedLayerIndex < _layers.length)
      ? _layers[_selectedLayerIndex]
      : null;

  bool get hasAnyTileset => _tilesets.isNotEmpty;

  List<TilesetDef> get tilesets => List.unmodifiable(_tilesets);

  TilesetDef? getTilesetById(String? id) {
    if (id == null) return null;
    try {
      return _tilesets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  ImageProvider? get selectedLayerTilesetProvider =>
      getTilesetById(selectedLayer?.tilesetId)?.provider;
  ui.Image? get selectedLayerTilesetImage =>
      getTilesetById(selectedLayer?.tilesetId)?.image;
  TileSelection? get selectedLayerSelection => selectedLayer?.selection;

  void selectLayer(int index) {
    if (index < 0 || index >= _layers.length) return;
    _selectedLayerIndex = index;
    notifyListeners();
  }

  String addTileset({
    required String name,
    required ui.Image image,
    required ImageProvider provider,
    double? tileWidth,
    double? tileHeight,
  }) {
    final String id = '${DateTime.now().microsecondsSinceEpoch}-$name';
    _tilesets.add(
      TilesetDef(id: id, name: name, image: image, provider: provider),
    );
    if (tileWidth != null) tilePixelWidth = tileWidth;
    if (tileHeight != null) tilePixelHeight = tileHeight;
    notifyListeners();
    return id;
  }

  void setLayerTileset(String tilesetId) {
    final layer = selectedLayer;
    if (layer == null) return;
    if (getTilesetById(tilesetId) == null) return;
    layer.tilesetId = tilesetId;
    notifyListeners();
  }

  void removeTileset(String tilesetId) {
    _tilesets.removeWhere((t) => t.id == tilesetId);
    final String? fallbackId = _tilesets.isNotEmpty ? _tilesets.first.id : null;
    for (final layer in _layers) {
      if (layer.tilesetId == tilesetId) {
        layer.tilesetId = fallbackId;
      }
    }
    notifyListeners();
  }

  void selectTile(int x, int y) {
    // Seleção 1x1 na layer atual
    final layer = selectedLayer;
    if (layer == null) return;
    layer.selection = TileSelection(startX: x, startY: y, endX: x, endY: y);
    // Atualiza legado
    selectedTileX = x;
    selectedTileY = y;
    notifyListeners();
  }

  void setSelectionRange(int startX, int startY, int endX, int endY) {
    final layer = selectedLayer;
    if (layer == null) return;
    layer.selection = TileSelection(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
    ).normalized();
    // Atualiza legado como canto superior esquerdo
    selectedTileX = layer.selection!.startX;
    selectedTileY = layer.selection!.startY;
    notifyListeners();
  }

  void setLayersByNames(List<String> names) {
    // Preserve existing layers where names match, rebuild others
    final Map<String, LayerData> byName = {for (final l in _layers) l.name: l};
    _layers
      ..clear()
      ..addAll(
        names.map((name) {
          final existing = byName[name];
          if (existing != null &&
              existing.tiles.length == tilesY &&
              existing.tiles.first.length == tilesX) {
            return existing;
          }
          return LayerData(name: name, width: tilesX, height: tilesY);
        }),
      );
    if (_selectedLayerIndex >= _layers.length) {
      _selectedLayerIndex = _layers.isEmpty ? -1 : _layers.length - 1;
    }
    notifyListeners();
  }

  void paintOrErase(int x, int y, {required bool paint}) {
    if (_selectedLayerIndex < 0 || _selectedLayerIndex >= _layers.length)
      return;
    if (x < 0 || y < 0 || x >= tilesX || y >= tilesY) return;

    final layer = _layers[_selectedLayerIndex];
    if (!paint) {
      // apagar sempre 1x1
      layer.tiles[y][x] = null;
      notifyListeners();
      return;
    }

    // pintar: requer tileset na layer e uma seleção atual
    if (getTilesetById(layer.tilesetId) == null || layer.selection == null)
      return;
    final sel = layer.selection!.normalized();

    final int selW = sel.width;
    final int selH = sel.height;

    for (int dy = 0; dy < selH; dy++) {
      final int ty = y + dy;
      if (ty < 0 || ty >= tilesY) continue; // recorte vertical
      for (int dx = 0; dx < selW; dx++) {
        final int tx = x + dx;
        if (tx < 0 || tx >= tilesX) continue; // recorte horizontal
        final int srcX = sel.startX + dx;
        final int srcY = sel.startY + dy;
        layer.tiles[ty][tx] = TileRef(tileX: srcX, tileY: srcY);
      }
    }
    notifyListeners();
  }
}

class EditorScope extends InheritedNotifier<EditorController> {
  const EditorScope({
    super.key,
    required EditorController controller,
    required super.child,
  }) : super(notifier: controller);

  static EditorController of(context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EditorScope>();
    assert(scope != null, 'EditorScope not found in context');
    return scope!.notifier!;
  }
}
