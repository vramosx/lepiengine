import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TileRef {
  final int tileX;
  final int tileY;

  const TileRef({required this.tileX, required this.tileY});
}

class LayerData {
  final String name;
  final List<List<TileRef?>> tiles; // [y][x]

  LayerData({required this.name, required int width, required int height})
    : tiles = List.generate(
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

  // Tileset configuration (source tiles)
  ui.Image? tilesetImage; // required for drawing
  double tilePixelWidth = 32;
  double tilePixelHeight = 32;

  // Tileset selection
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

  void selectLayer(int index) {
    if (index < 0 || index >= _layers.length) return;
    _selectedLayerIndex = index;
    notifyListeners();
  }

  void setTileset({
    required ui.Image image,
    required double tileWidth,
    required double tileHeight,
  }) {
    tilesetImage = image;
    tilePixelWidth = tileWidth;
    tilePixelHeight = tileHeight;
    notifyListeners();
  }

  void selectTile(int x, int y) {
    selectedTileX = x;
    selectedTileY = y;
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
    if (paint) {
      if (tilesetImage == null ||
          selectedTileX == null ||
          selectedTileY == null)
        return;
      layer.tiles[y][x] = TileRef(tileX: selectedTileX!, tileY: selectedTileY!);
    } else {
      layer.tiles[y][x] = null;
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
