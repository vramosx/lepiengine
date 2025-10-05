import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class MapEditor extends StatefulWidget {
  final int tilesX;
  final int tilesY;
  final double tileSize;
  final Color gridColor;
  final Color highlightColor;

  const MapEditor({
    super.key,
    required this.tilesX,
    required this.tilesY,
    this.tileSize = 32.0,
    this.gridColor = const Color(0xFFCCCCCC),
    this.highlightColor = const Color.fromARGB(84, 68, 189, 245),
  });

  @override
  State<MapEditor> createState() => _MapEditorState();
}

class _MapEditorState extends State<MapEditor> {
  Offset? _hoverPosition;

  void _onHover(PointerHoverEvent event) {
    setState(() => _hoverPosition = event.localPosition);
  }

  void _onExit(PointerExitEvent event) {
    setState(() => _hoverPosition = null);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: CustomPaint(
        size: Size(
          widget.tilesX * widget.tileSize,
          widget.tilesY * widget.tileSize,
        ),
        painter: _MapEditorPainter(
          tilesX: widget.tilesX,
          tilesY: widget.tilesY,
          tileSize: widget.tileSize,
          gridColor: widget.gridColor,
          highlightColor: widget.highlightColor,
          hoverPosition: _hoverPosition,
        ),
      ),
    );
  }
}

class _MapEditorPainter extends CustomPainter {
  final int tilesX;
  final int tilesY;
  final double tileSize;
  final Color gridColor;
  final Color highlightColor;
  final Offset? hoverPosition;

  _MapEditorPainter({
    required this.tilesX,
    required this.tilesY,
    required this.tileSize,
    required this.gridColor,
    required this.highlightColor,
    required this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;

    // Desenha o grid
    for (int x = 0; x <= tilesX; x++) {
      final dx = x * tileSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }

    for (int y = 0; y <= tilesY; y++) {
      final dy = y * tileSize;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }

    // Destaque do tile sob o mouse
    if (hoverPosition != null) {
      final tileX = (hoverPosition!.dx / tileSize).floor().clamp(0, tilesX - 1);
      final tileY = (hoverPosition!.dy / tileSize).floor().clamp(0, tilesY - 1);

      final rect = Rect.fromLTWH(
        tileX * tileSize,
        tileY * tileSize,
        tileSize,
        tileSize,
      );

      final highlightPaint = Paint()
        ..color = highlightColor.withAlpha(100)
        ..style = PaintingStyle.fill;

      // desenha borda do tile
      final borderPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(rect, borderPaint);

      canvas.drawRect(rect, highlightPaint);

      // Opcional: desenha a posição do tile
      // final textPainter = TextPainter(
      //   text: TextSpan(
      //     text: '($tileX, $tileY)',
      //     style: const TextStyle(
      //       color: Colors.black,
      //       fontSize: 12,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   textDirection: TextDirection.ltr,
      // );
      // textPainter.layout();
      // textPainter.paint(canvas, Offset(rect.left + 4, rect.top + 4));
    }
  }

  @override
  bool shouldRepaint(_MapEditorPainter oldDelegate) {
    return hoverPosition != oldDelegate.hoverPosition;
  }
}
