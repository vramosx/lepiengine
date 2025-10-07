import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/collider.dart';
import '../core/game_object.dart';
import '../models/tileset.dart';

class TileLayer {
  TileLayer({
    required this.name,
    required this.tiles,
    Set<math.Point<int>>? solidTiles,
  }) : solidTiles = solidTiles ?? <math.Point<int>>{};

  final String name;
  final List<List<int>> tiles;
  final Set<math.Point<int>> solidTiles; // posições sólidas por camada
}

class Tilemap extends GameObject {
  final Tileset tileset;
  // Suporte legado: mapa único
  final List<List<int>> map;
  // Novo: múltiplas camadas
  final List<TileLayer> layers;
  final int tileWidth; // tamanho de desenho do tile no mundo
  final int tileHeight;
  // Legado: sólidos em um único conjunto
  final Set<math.Point<int>> solidTiles;
  final bool debugCollisions;

  /// Construtor legado (um único `map`). Mantido por compatibilidade.
  Tilemap({
    required this.tileset,
    List<List<int>>? map,
    this.layers = const <TileLayer>[],
    this.tileWidth = 32,
    this.tileHeight = 32,
    Set<math.Point<int>> solidTiles = const <math.Point<int>>{},
    this.debugCollisions = false,
    super.position,
    super.name,
  }) : map = map ?? const <List<int>>[],
       solidTiles = solidTiles;

  /// Novo construtor para múltiplas camadas.
  Tilemap.fromLayers({
    required this.tileset,
    required this.layers,
    this.tileWidth = 32,
    this.tileHeight = 32,
    this.debugCollisions = false,
    super.position,
    super.name,
  }) : map = const <List<int>>[],
       solidTiles = const <math.Point<int>>{};

  int get gridHeight {
    if (layers.isNotEmpty) return layers.first.tiles.length;
    return map.length;
  }

  int get gridWidth {
    if (layers.isNotEmpty) {
      return layers.first.tiles.isNotEmpty
          ? layers.first.tiles.first.length
          : 0;
    }
    return map.isNotEmpty ? map.first.length : 0;
  }

  Set<math.Point<int>> get allSolidTiles {
    if (layers.isEmpty) return solidTiles;
    final Set<math.Point<int>> combined = <math.Point<int>>{};
    for (final layer in layers) {
      combined.addAll(layer.solidTiles);
    }
    // Inclui sólidos legados, se existirem
    combined.addAll(solidTiles);
    return combined;
  }

  @override
  void onAdd() {
    super.onAdd();
    _generateColliders();
  }

  /// Gera colliders mesclados para os tiles sólidos
  void _generateColliders() {
    if (gridWidth == 0 || gridHeight == 0) return;

    final Set<math.Point<int>> solids = allSolidTiles;
    for (int y = 0; y < gridHeight; y++) {
      int? startX;
      for (int x = 0; x < gridWidth; x++) {
        final bool isSolid = solids.contains(math.Point<int>(x, y));

        if (isSolid && startX == null) {
          // inicia uma sequência de sólidos
          startX = x;
        }

        final bool reachedEnd =
            (!isSolid && startX != null) || (isSolid && x == gridWidth - 1);

        if (reachedEnd) {
          final int endX = isSolid ? x : x - 1;
          final int widthPx = (endX - startX! + 1) * tileWidth;
          final int heightPx = tileHeight;

          final collider = AABBCollider(
            gameObject: this,
            size: Size(widthPx.toDouble(), heightPx.toDouble()),
            offset: Offset(
              startX * tileWidth.toDouble(),
              y * tileHeight.toDouble(),
            ),
            anchor: ColliderAnchor.topLeft,
            isStatic: true,
            debugColor: const Color(0xFFFF0000),
          );
          addCollider(collider);
          startX = null;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    if (layers.isNotEmpty) {
      // Desenha todas as camadas na ordem fornecida
      for (final layer in layers) {
        for (int y = 0; y < layer.tiles.length; y++) {
          final row = layer.tiles[y];
          for (int x = 0; x < row.length; x++) {
            final int index = row[x];
            if (index < 0) continue;

            final Rect src = tileset.getTileRect(index);
            final Rect dst = Rect.fromLTWH(
              x * tileWidth.toDouble(),
              y * tileHeight.toDouble(),
              tileWidth.toDouble(),
              tileHeight.toDouble(),
            );
            canvas.drawImageRect(tileset.image, src, dst, paint);
          }
        }
      }
    } else {
      // Renderização legada de mapa único
      for (int y = 0; y < map.length; y++) {
        for (int x = 0; x < map[y].length; x++) {
          final int index = map[y][x];
          if (index < 0) continue;

          final Rect src = tileset.getTileRect(index);
          final Rect dst = Rect.fromLTWH(
            x * tileWidth.toDouble(),
            y * tileHeight.toDouble(),
            tileWidth.toDouble(),
            tileHeight.toDouble(),
          );
          canvas.drawImageRect(tileset.image, src, dst, paint);
        }
      }
    }

    // Overlay de debug de sólidos (pintura única por célula)
    if (debugCollisions) {
      final Set<math.Point<int>> solids = allSolidTiles;
      final Paint debugPaint = Paint()
        ..color = const Color(0x55FF0000)
        ..style = PaintingStyle.fill;
      for (final p in solids) {
        final Rect dst = Rect.fromLTWH(
          p.x * tileWidth.toDouble(),
          p.y * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        );
        canvas.drawRect(dst, debugPaint);
      }

      // Também desenha os colliders mesclados
      for (final collider in colliders) {
        collider.debugRender(canvas);
      }
    }
  }
}
