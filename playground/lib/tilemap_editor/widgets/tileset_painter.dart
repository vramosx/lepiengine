import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TilesetPainter extends CustomPainter {
  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final int? selectedTileIndex;

  TilesetPainter({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    this.selectedTileIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;

    // Desenhar a imagem completa do tileset
    canvas.drawImage(image, Offset.zero, paint);

    // Desenhar grade
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final tilesPerRow = (image.width / tileWidth).floor();
    final tilesPerColumn = (image.height / tileHeight).floor();

    // Linhas verticais
    for (int x = 0; x <= tilesPerRow; x++) {
      final xPos = x * tileWidth.toDouble();
      canvas.drawLine(
        Offset(xPos, 0),
        Offset(xPos, tilesPerColumn * tileHeight.toDouble()),
        gridPaint,
      );
    }

    // Linhas horizontais
    for (int y = 0; y <= tilesPerColumn; y++) {
      final yPos = y * tileHeight.toDouble();
      canvas.drawLine(
        Offset(0, yPos),
        Offset(tilesPerRow * tileWidth.toDouble(), yPos),
        gridPaint,
      );
    }

    // Destacar tile selecionado
    if (selectedTileIndex != null) {
      final tileX = selectedTileIndex! % tilesPerRow;
      final tileY = selectedTileIndex! ~/ tilesPerRow;

      final selectionPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTWH(
        tileX * tileWidth.toDouble(),
        tileY * tileHeight.toDouble(),
        tileWidth.toDouble(),
        tileHeight.toDouble(),
      );

      canvas.drawRect(rect, selectionPaint);

      // Overlay semi-transparente azul
      final overlayPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(TilesetPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.selectedTileIndex != selectedTileIndex;
  }
}
