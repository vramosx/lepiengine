import 'dart:ui';

class Tileset {
  final Image image;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;

  Tileset({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
  }) : columns = image.width ~/ tileWidth,
       rows = image.height ~/ tileHeight;

  /// Retorna o retângulo (no spritesheet) de um índice de tile
  Rect getTileRect(int index) {
    final col = index % columns;
    final row = index ~/ columns;
    return Rect.fromLTWH(
      col * tileWidth.toDouble(),
      row * tileHeight.toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
  }
}
