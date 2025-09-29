import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/collider.dart';
import '../core/game_object.dart';
import '../models/tileset.dart';

class Tilemap extends GameObject {
  final Tileset tileset;
  final List<List<int>> map;
  final int tileWidth;
  final int tileHeight;
  final Set<int> solidTiles; // tiles que têm colisão
  final bool debugCollisions;

  Tilemap({
    required this.tileset,
    required this.map,
    this.tileWidth = 32,
    this.tileHeight = 32,
    this.solidTiles = const {},
    this.debugCollisions = false,
    super.position,
    super.name,
  });

  @override
  void onAdd() {
    super.onAdd();
    _generateColliders();
  }

  /// Gera colliders mesclados para os tiles sólidos
  void _generateColliders() {
    for (int y = 0; y < map.length; y++) {
      int? startX;
      for (int x = 0; x < map[y].length; x++) {
        final isSolid = solidTiles.contains(map[y][x]);

        if (isSolid && startX == null) {
          // inicia uma sequência de sólidos
          startX = x;
        }

        final reachedEnd =
            (!isSolid && startX != null) || // fim de sequência
            (isSolid && x == map[y].length - 1); // última célula da linha

        if (reachedEnd) {
          final endX = isSolid ? x : x - 1;
          final width = (endX - startX! + 1) * tileWidth;
          final height = tileHeight;

          final collider = AABBCollider(
            gameObject: this,
            size: Size(width.toDouble(), height.toDouble()),
            offset: Offset(
              startX * tileWidth.toDouble(),
              y * tileHeight.toDouble(),
            ), // posição dentro do mapa
            anchor: ColliderAnchor.topLeft,
            isStatic: true,
            debugColor: const Color(0xFFFF0000), // vermelho
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
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        final index = map[y][x];
        if (index < 0) continue;

        final src = tileset.getTileRect(index);
        final dst = Rect.fromLTWH(
          x * tileWidth.toDouble(),
          y * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        );

        canvas.drawImageRect(tileset.image, src, dst, paint);

        // Modo debug: pinta tiles sólidos
        if (debugCollisions && solidTiles.contains(index)) {
          final debugPaint = Paint()
            ..color =
                const Color(0x55FF0000) // vermelho semi-transparente
            ..style = PaintingStyle.fill;
          canvas.drawRect(dst, debugPaint);
        }
      }
    }

    // Opcional: também desenhar os colliders mesclados
    if (debugCollisions) {
      for (final collider in colliders) {
        collider.debugRender(canvas);
      }
    }
  }
}
