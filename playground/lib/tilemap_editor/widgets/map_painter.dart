import 'package:flutter/material.dart';
import '../models/tilemap_editor_state.dart';

class MapPainter extends CustomPainter {
  final TilemapEditorState editorState;

  MapPainter({required this.editorState});

  @override
  void paint(Canvas canvas, Size size) {
    final tileWidth = editorState.tileWidth.toDouble();
    final tileHeight = editorState.tileHeight.toDouble();

    // Desenhar fundo
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Desenhar grade
    _drawGrid(canvas, size, tileWidth, tileHeight);

    // Desenhar tiles visuais
    if (editorState.tilesetImage != null && !editorState.editingCollision) {
      _drawTiles(canvas, tileWidth, tileHeight);
    }

    // Desenhar colisões
    if (editorState.editingCollision) {
      _drawCollisions(canvas, tileWidth, tileHeight);
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double tileWidth,
    double tileHeight,
  ) {
    final gridPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Linhas verticais
    for (int x = 0; x <= editorState.width; x++) {
      final xPos = x * tileWidth;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), gridPaint);
    }

    // Linhas horizontais
    for (int y = 0; y <= editorState.height; y++) {
      final yPos = y * tileHeight;
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), gridPaint);
    }
  }

  void _drawTiles(Canvas canvas, double tileWidth, double tileHeight) {
    final image = editorState.tilesetImage!;
    final tilesPerRow = editorState.tilesPerRow;

    final paint = Paint()..filterQuality = FilterQuality.none;

    for (int y = 0; y < editorState.height; y++) {
      for (int x = 0; x < editorState.width; x++) {
        final tileIndex = editorState.getTile(x, y);

        if (tileIndex >= 0 && tileIndex < editorState.totalTiles) {
          // Calcular posição do tile no tileset
          final sourceTileX = tileIndex % tilesPerRow;
          final sourceTileY = tileIndex ~/ tilesPerRow;

          final sourceRect = Rect.fromLTWH(
            sourceTileX * editorState.tileWidth.toDouble(),
            sourceTileY * editorState.tileHeight.toDouble(),
            editorState.tileWidth.toDouble(),
            editorState.tileHeight.toDouble(),
          );

          final destRect = Rect.fromLTWH(
            x * tileWidth,
            y * tileHeight,
            tileWidth,
            tileHeight,
          );

          canvas.drawImageRect(image, sourceRect, destRect, paint);
        }
      }
    }
  }

  void _drawCollisions(Canvas canvas, double tileWidth, double tileHeight) {
    final collisionPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Desenhar tiles visuais com transparência
    if (editorState.tilesetImage != null) {
      final image = editorState.tilesetImage!;
      final tilesPerRow = editorState.tilesPerRow;

      final tilePaint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(0.3),
          BlendMode.modulate,
        );

      for (int y = 0; y < editorState.height; y++) {
        for (int x = 0; x < editorState.width; x++) {
          final tileIndex = editorState.getTile(x, y);

          if (tileIndex >= 0 && tileIndex < editorState.totalTiles) {
            final sourceTileX = tileIndex % tilesPerRow;
            final sourceTileY = tileIndex ~/ tilesPerRow;

            final sourceRect = Rect.fromLTWH(
              sourceTileX * editorState.tileWidth.toDouble(),
              sourceTileY * editorState.tileHeight.toDouble(),
              editorState.tileWidth.toDouble(),
              editorState.tileHeight.toDouble(),
            );

            final destRect = Rect.fromLTWH(
              x * tileWidth,
              y * tileHeight,
              tileWidth,
              tileHeight,
            );

            canvas.drawImageRect(image, sourceRect, destRect, tilePaint);
          }
        }
      }
    }

    // Desenhar colisões
    for (final collision in editorState.collisions) {
      final coords = collision.split(',');
      if (coords.length == 2) {
        final x = int.tryParse(coords[0]);
        final y = int.tryParse(coords[1]);

        if (x != null && y != null) {
          final rect = Rect.fromLTWH(
            x * tileWidth,
            y * tileHeight,
            tileWidth,
            tileHeight,
          );

          canvas.drawRect(rect, collisionPaint);
          canvas.drawRect(rect, borderPaint);

          // Desenhar ícone de colisão
          final iconSize = (tileWidth * 0.6).clamp(16.0, 32.0);
          final iconOffset = Offset(
            x * tileWidth + (tileWidth - iconSize) / 2,
            y * tileHeight + (tileHeight - iconSize) / 2,
          );

          _drawCollisionIcon(canvas, iconOffset, iconSize);
        }
      }
    }
  }

  void _drawCollisionIcon(Canvas canvas, Offset offset, double size) {
    final iconPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = offset + Offset(size / 2, size / 2);
    final radius = size / 3;

    // Desenhar círculo com X
    canvas.drawCircle(center, radius, iconPaint);

    final crossSize = radius * 0.7;
    canvas.drawLine(
      center + Offset(-crossSize, -crossSize),
      center + Offset(crossSize, crossSize),
      iconPaint,
    );
    canvas.drawLine(
      center + Offset(crossSize, -crossSize),
      center + Offset(-crossSize, crossSize),
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.editorState != editorState;
  }
}
