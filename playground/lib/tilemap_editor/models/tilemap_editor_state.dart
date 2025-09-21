import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';

class TilemapEditorState extends ChangeNotifier {
  // Tileset properties
  String? tilesetPath;
  ui.Image? tilesetImage;
  int tileWidth = 32;
  int tileHeight = 32;

  // Map dimensions
  int width = 10;
  int height = 10;

  // Map layers
  late List<List<int>> tiles; // -1 = empty, >= 0 = tile index
  late Set<String> collisions; // "x,y" coordinates of solid tiles

  // Interface state
  int? selectedTileIndex; // selected tile index in tileset
  bool editingCollision = false; // true = collision mode, false = tiles mode

  // Calculated tileset properties
  int get tilesPerRow =>
      tilesetImage != null ? (tilesetImage!.width ~/ tileWidth) : 0;
  int get tilesPerColumn =>
      tilesetImage != null ? (tilesetImage!.height ~/ tileHeight) : 0;
  int get totalTiles => tilesPerRow * tilesPerColumn;

  TilemapEditorState() {
    _initializeMap();
  }

  void _initializeMap() {
    tiles = List.generate(height, (y) => List.generate(width, (x) => -1));
    collisions = <String>{};
  }

  void setMapSize(int newWidth, int newHeight) {
    if (newWidth != width || newHeight != height) {
      width = newWidth;
      height = newHeight;
      _initializeMap();
      notifyListeners();
    }
  }

  void setTileSize(int newTileWidth, int newTileHeight) {
    if (newTileWidth != tileWidth || newTileHeight != tileHeight) {
      tileWidth = newTileWidth;
      tileHeight = newTileHeight;
      selectedTileIndex = null; // Reset selection
      notifyListeners();
    }
  }

  void setTilesetImage(ui.Image image, String path) {
    tilesetImage = image;
    tilesetPath = path;
    selectedTileIndex = null; // Reset selection
    notifyListeners();
  }

  void selectTile(int index) {
    if (index >= 0 && index < totalTiles) {
      selectedTileIndex = index;
      notifyListeners();
    }
  }

  void toggleEditingMode() {
    editingCollision = !editingCollision;
    notifyListeners();
  }

  void setEditingMode(bool collision) {
    editingCollision = collision;
    notifyListeners();
  }

  void paintTile(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;

    if (editingCollision) {
      final key = '$x,$y';
      if (collisions.contains(key)) {
        collisions.remove(key);
      } else {
        collisions.add(key);
      }
    } else {
      if (selectedTileIndex != null) {
        tiles[y][x] = selectedTileIndex!;
      }
    }
    notifyListeners();
  }

  void eraseTile(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;

    if (editingCollision) {
      collisions.remove('$x,$y');
    } else {
      tiles[y][x] = -1;
    }
    notifyListeners();
  }

  void clearMap() {
    _initializeMap();
    notifyListeners();
  }

  bool hasCollision(int x, int y) {
    return collisions.contains('$x,$y');
  }

  int getTile(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return -1;
    return tiles[y][x];
  }

  // JSON conversion
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
      'tilesetPath': tilesetPath,
      'tiles': tiles,
      'collisions': collisions.toList(),
    };
  }

  // Load from JSON
  void fromJson(Map<String, dynamic> json) {
    width = json['width'] ?? 10;
    height = json['height'] ?? 10;
    tileWidth = json['tileWidth'] ?? 32;
    tileHeight = json['tileHeight'] ?? 32;
    tilesetPath = json['tilesetPath'];

    // Load tiles
    if (json['tiles'] != null) {
      final tilesData = json['tiles'] as List;
      tiles = tilesData.map((row) => List<int>.from(row as List)).toList();
    } else {
      tiles = List.generate(height, (y) => List.generate(width, (x) => -1));
    }

    // Load collisions
    if (json['collisions'] != null) {
      collisions = Set<String>.from(json['collisions'] as List);
    } else {
      collisions = <String>{};
    }

    notifyListeners();
  }

  String exportToJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
