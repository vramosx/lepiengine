import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:lepiengine_tilemap_editor/models/index.dart';

enum EditingTool { brush, bucket, collision }

class EditorController extends ChangeNotifier {
  // Estado de projeto
  bool isDirty = false;
  String? currentFilePath;
  bool showGrid = true;

  // Grid/display configuration
  int tilesX = 16;
  int tilesY = 16;
  double tileSize = 32; // display size in editor canvas

  // Tileset slicing (source tiles) - global para o projeto
  double tilePixelWidth = 32;
  double tilePixelHeight = 32;

  // Ferramenta atual
  EditingTool currentTool = EditingTool.brush;

  // Registro de tilesets
  final List<TilesetDef> _tilesets = [];

  // Seleção legacy (mantida por compatibilidade com UI antiga)
  int? selectedTileX;
  int? selectedTileY;

  // Layers
  final List<LayerData> _layers = [
    LayerData(name: 'Over Ground', width: 16, height: 16),
    LayerData(name: 'Ground', width: 16, height: 16),
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

  bool get hasSelectionOnSelectedLayer => selectedLayer?.selection != null;
  bool get hasTilesetOnSelectedLayer =>
      getTilesetById(selectedLayer?.tilesetId) != null;

  void selectLayer(int index) {
    if (index < 0 || index >= _layers.length) return;
    _selectedLayerIndex = index;
    notifyListeners();
  }

  // --- Config setters ---
  void setMapSize({required int widthInTiles, required int heightInTiles}) {
    if (widthInTiles <= 0 || heightInTiles <= 0) return;
    tilesX = widthInTiles;
    tilesY = heightInTiles;
    // Redimensiona buffers das layers preservando o que for possível
    for (final layer in _layers) {
      layer.resize(width: tilesX, height: tilesY);
    }
    isDirty = true;
    notifyListeners();
  }

  void setTilePixelSize({required double width, required double height}) {
    if (width <= 0 || height <= 0) return;
    tilePixelWidth = width;
    tilePixelHeight = height;
    // Mantém o grid do editor coerente com o tamanho de tile definido
    // Assumimos tiles quadrados na maioria dos casos; usamos a largura como base
    tileSize = width;
    isDirty = true;
    notifyListeners();
  }

  void setTileSize(double size) {
    if (size <= 0) return;
    tileSize = size;
    notifyListeners();
  }

  void setTool(EditingTool tool) {
    if (currentTool == tool) return;
    currentTool = tool;
    notifyListeners();
  }

  void setShowGrid(bool value) {
    if (showGrid == value) return;
    showGrid = value;
    notifyListeners();
  }

  String addTileset({
    required String name,
    required ui.Image image,
    required ImageProvider provider,
    double? tileWidth,
    double? tileHeight,
    String? path,
  }) {
    final String id = '${DateTime.now().microsecondsSinceEpoch}-$name';
    _tilesets.add(
      TilesetDef(
        id: id,
        name: name,
        image: image,
        provider: provider,
        path: path,
      ),
    );
    if (tileWidth != null) tilePixelWidth = tileWidth;
    if (tileHeight != null) tilePixelHeight = tileHeight;
    isDirty = true;
    notifyListeners();
    return id;
  }

  /// Adiciona um tileset preservando o ID (para reabrir projetos)
  void addTilesetWithId({
    required String id,
    required String name,
    required ui.Image image,
    required ImageProvider provider,
    String? path,
  }) {
    _tilesets.removeWhere((t) => t.id == id);
    _tilesets.add(
      TilesetDef(
        id: id,
        name: name,
        image: image,
        provider: provider,
        path: path,
      ),
    );
    notifyListeners();
  }

  void setLayerTileset(String tilesetId) {
    final layer = selectedLayer;
    if (layer == null) return;
    if (getTilesetById(tilesetId) == null) return;
    layer.tilesetId = tilesetId;
    isDirty = true;
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
    isDirty = true;
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
    isDirty = true;
    notifyListeners();
  }

  /// Reordena as layers preservando instâncias por nome e mantém a seleção atual quando possível
  void reorderLayersByNames(List<String> names) {
    final String? selectedName = selectedLayer?.name;
    setLayersByNames(names);
    if (selectedName != null) {
      final int idx = _layers.indexWhere((l) => l.name == selectedName);
      if (idx != -1 && idx != _selectedLayerIndex) {
        _selectedLayerIndex = idx;
        notifyListeners();
      }
    }
  }

  /// Remove a layer pelo índice e ajusta o índice selecionado
  void removeLayer(int index) {
    if (index < 0 || index >= _layers.length) return;
    _layers.removeAt(index);
    if (_layers.isEmpty) {
      _selectedLayerIndex = -1;
    } else if (_selectedLayerIndex >= _layers.length) {
      _selectedLayerIndex = _layers.length - 1;
    }
    isDirty = true;
    notifyListeners();
  }

  // --- Layers helpers ---
  void addLayer(String name) {
    if (name.trim().isEmpty) return;
    String finalName = name.trim();
    // Garante nome único
    if (_layers.any((l) => l.name == finalName)) {
      int n = 2;
      while (_layers.any((l) => l.name == '$finalName ($n)')) {
        n++;
      }
      finalName = '$finalName ($n)';
    }
    _layers.add(LayerData(name: finalName, width: tilesX, height: tilesY));
    _selectedLayerIndex = _layers.length - 1;
    isDirty = true;
    notifyListeners();
  }

  void renameLayer(int index, String newName) {
    if (index < 0 || index >= _layers.length) return;
    if (newName.trim().isEmpty) return;
    final String finalName = newName.trim();
    // Evita duplicatas com outros índices
    if (_layers.any((l) => l.name == finalName && l != _layers[index])) {
      return; // ignora rename inválido
    }
    _layers[index].name = finalName;
    isDirty = true;
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
      isDirty = true;
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
    isDirty = true;
    notifyListeners();
  }

  void floodFillAt(int x, int y, {required bool paint}) {
    if (_selectedLayerIndex < 0 || _selectedLayerIndex >= _layers.length) {
      return;
    }
    if (x < 0 || y < 0 || x >= tilesX || y >= tilesY) return;

    final layer = _layers[_selectedLayerIndex];

    // Se apagando, alvo é o conteúdo atual; novo valor é null
    TileRef? replacement;
    if (paint) {
      // Pintando requer tileset e seleção
      if (getTilesetById(layer.tilesetId) == null || layer.selection == null)
        return;
      final sel = layer.selection!.normalized();
      replacement = TileRef(tileX: sel.startX, tileY: sel.startY);
    } else {
      replacement = null;
    }

    final TileRef? target = layer.tiles[y][x];
    // Se replacement e target são iguais, nada a fazer
    if (target == replacement ||
        (target != null &&
            replacement != null &&
            target.tileX == replacement.tileX &&
            target.tileY == replacement.tileY)) {
      return;
    }

    final List<List<bool>> visited = List.generate(
      tilesY,
      (_) => List<bool>.filled(tilesX, false, growable: false),
      growable: false,
    );

    final List<(int, int)> stack = <(int, int)>[(x, y)];
    while (stack.isNotEmpty) {
      final (int cx, int cy) = stack.removeLast();
      if (cx < 0 || cy < 0 || cx >= tilesX || cy >= tilesY) continue;
      if (visited[cy][cx]) continue;
      visited[cy][cx] = true;

      final TileRef? current = layer.tiles[cy][cx];
      final bool sameAsTarget =
          (current == null && target == null) ||
          (current != null &&
              target != null &&
              current.tileX == target.tileX &&
              current.tileY == target.tileY);
      if (!sameAsTarget) continue;

      layer.tiles[cy][cx] = replacement;

      stack.add((cx + 1, cy));
      stack.add((cx - 1, cy));
      stack.add((cx, cy + 1));
      stack.add((cx, cy - 1));
    }
    isDirty = true;
    notifyListeners();
  }

  // --- Collision editing ---
  void setCollisionAt(int x, int y, {required bool add}) {
    if (_selectedLayerIndex < 0 || _selectedLayerIndex >= _layers.length) {
      return;
    }
    if (x < 0 || y < 0 || x >= tilesX || y >= tilesY) return;
    final layer = _layers[_selectedLayerIndex];
    layer.collisions[y][x] = add;
    isDirty = true;
    notifyListeners();
  }

  void setLayerCollisionVisibility(int index, bool visible) {
    if (index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    if (layer.showCollisions == visible) return;
    layer.showCollisions = visible;
    notifyListeners();
  }

  void toggleLayerCollisionVisibility(int index) {
    if (index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    layer.showCollisions = !layer.showCollisions;
    notifyListeners();
  }

  // --- Layer visibility ---
  void setLayerVisibility(int index, bool visible) {
    if (index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    if (layer.visible == visible) return;
    layer.visible = visible;
    isDirty = true;
    notifyListeners();
  }

  void toggleLayerVisibility(int index) {
    if (index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    layer.visible = !layer.visible;
    isDirty = true;
    notifyListeners();
  }

  // --- Projeto: New / Open helpers ---
  /// Restaura o projeto para o estado padrão (16x16, tile 32x32, layers Ground/Over Ground)
  void newMap({bool resetFilePath = true}) {
    tilesX = 16;
    tilesY = 16;
    tilePixelWidth = 32;
    tilePixelHeight = 32;
    tileSize = 32;

    _layers
      ..clear()
      ..add(LayerData(name: 'Ground', width: tilesX, height: tilesY))
      ..add(LayerData(name: 'Over Ground', width: tilesX, height: tilesY));
    _selectedLayerIndex = _layers.isEmpty ? -1 : _layers.length - 1;

    _tilesets.clear();
    selectedTileX = null;
    selectedTileY = null;
    currentTool = EditingTool.brush;

    if (resetFilePath) currentFilePath = null;
    isDirty = false;
    notifyListeners();
  }

  /// Aplica um mapa desserializado no estado do editor (v1 esparso)
  void applySerializedMap(Map<String, dynamic> json, {String? filePath}) {
    final int schema = (json['schemaVersion'] as int?) ?? 1;
    if (schema != 1) {
      throw ArgumentError('Schema não suportado: $schema');
    }

    final Map<String, dynamic> map = (json['map'] as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> size = (map['size'] as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> tilePx = (map['tilePixelSize'] as Map)
        .cast<String, dynamic>();

    tilesX = (size['width'] as num).toInt();
    tilesY = (size['height'] as num).toInt();
    tilePixelWidth = (tilePx['width'] as num).toDouble();
    tilePixelHeight = (tilePx['height'] as num).toDouble();
    tileSize = tilePixelWidth;

    // Layers (esparsos)
    final List<dynamic> layersJson = (json['layers'] as List<dynamic>);
    _layers.clear();
    for (final dynamic l in layersJson) {
      final Map<String, dynamic> ld = (l as Map).cast<String, dynamic>();
      final String name = ld['name'] as String;
      final bool visible = (ld['visible'] as bool?) ?? true;
      final bool showCollisions = (ld['showCollisions'] as bool?) ?? true;
      final String? tilesetId = ld['tilesetId'] as String?;

      final layer = LayerData(name: name, width: tilesX, height: tilesY)
        ..visible = visible
        ..showCollisions = showCollisions
        ..tilesetId = tilesetId;

      final List<dynamic>? tilesSparse = ld['tiles'] as List<dynamic>?;
      if (tilesSparse != null) {
        for (final dynamic cell in tilesSparse) {
          final Map<String, dynamic> c = (cell as Map).cast<String, dynamic>();
          final int x = (c['x'] as num).toInt();
          final int y = (c['y'] as num).toInt();
          if (x < 0 || y < 0 || x >= tilesX || y >= tilesY) continue;
          final int tx = (c['tx'] as num).toInt();
          final int ty = (c['ty'] as num).toInt();
          layer.tiles[y][x] = TileRef(tileX: tx, tileY: ty);
        }
      }

      final List<dynamic>? collisionsSparse =
          ld['collisions'] as List<dynamic>?;
      if (collisionsSparse != null) {
        for (final dynamic cell in collisionsSparse) {
          final Map<String, dynamic> c = (cell as Map).cast<String, dynamic>();
          final int x = (c['x'] as num).toInt();
          final int y = (c['y'] as num).toInt();
          if (x < 0 || y < 0 || x >= tilesX || y >= tilesY) continue;
          layer.collisions[y][x] = true;
        }
      }

      _layers.add(layer);
    }
    _selectedLayerIndex = _layers.isEmpty ? -1 : _layers.length - 1;

    currentFilePath = filePath;
    isDirty = false;
    notifyListeners();
  }

  /// Retorna true se qualquer layer possui pelo menos um tile preenchido
  bool hasAnyTilePlaced() {
    for (final layer in _layers) {
      for (int y = 0; y < layer.tiles.length; y++) {
        final row = layer.tiles[y];
        for (int x = 0; x < row.length; x++) {
          if (row[x] != null) return true;
        }
      }
    }
    return false;
  }

  void markSaved(String path) {
    currentFilePath = path;
    isDirty = false;
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
