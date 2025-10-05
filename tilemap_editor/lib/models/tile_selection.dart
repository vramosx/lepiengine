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
