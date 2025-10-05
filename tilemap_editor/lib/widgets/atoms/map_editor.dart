import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';

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
  bool _isDragging = false;
  bool _dragPaint = false; // true pinta (direito), false apaga (esquerdo)
  int? _lastTileX;
  int? _lastTileY;

  void _onHover(PointerHoverEvent event) {
    setState(() => _hoverPosition = event.localPosition);
  }

  void _onExit(PointerExitEvent event) {
    setState(() => _hoverPosition = null);
  }

  void _handlePaintAt(Offset localPos, {required bool paint}) {
    final int x = (localPos.dx / widget.tileSize).floor();
    final int y = (localPos.dy / widget.tileSize).floor();
    if (_lastTileX == x && _lastTileY == y) return;
    _lastTileX = x;
    _lastTileY = y;
    final controller = EditorScope.of(context);
    controller.paintOrErase(x, y, paint: paint);
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.of(context);
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: Listener(
        onPointerDown: (PointerDownEvent e) {
          setState(() {
            _isDragging = true;
            _lastTileX = null;
            _lastTileY = null;
            _hoverPosition = e.localPosition;
            final keys = HardwareKeyboard.instance.logicalKeysPressed;
            final bool ctrlOrMeta =
                keys.contains(LogicalKeyboardKey.controlLeft) ||
                keys.contains(LogicalKeyboardKey.controlRight) ||
                keys.contains(LogicalKeyboardKey.metaLeft) ||
                keys.contains(LogicalKeyboardKey.metaRight);
            if (ctrlOrMeta) {
              // Não desenhar com CTRL/CMD pressionado
              _isDragging = false;
              return;
            }
            final bool right = (e.buttons & kSecondaryMouseButton) != 0;
            // direito = pintar; esquerdo = apagar
            _dragPaint = right;
          });
          if (_isDragging) {
            _handlePaintAt(e.localPosition, paint: _dragPaint);
          }
        },
        onPointerMove: (PointerMoveEvent e) {
          if (_isDragging) {
            setState(() {
              _hoverPosition = e.localPosition;
            });
            final keys = HardwareKeyboard.instance.logicalKeysPressed;
            final bool ctrlOrMeta =
                keys.contains(LogicalKeyboardKey.controlLeft) ||
                keys.contains(LogicalKeyboardKey.controlRight) ||
                keys.contains(LogicalKeyboardKey.metaLeft) ||
                keys.contains(LogicalKeyboardKey.metaRight);
            if (ctrlOrMeta) return; // não desenhar com CTRL/CMD
            final bool right = (e.buttons & kSecondaryMouseButton) != 0;
            _dragPaint = right; // direito = pintar; esquerdo = apagar
            _handlePaintAt(e.localPosition, paint: _dragPaint);
          }
        },
        onPointerUp: (PointerUpEvent e) {
          setState(() {
            _isDragging = false;
            _lastTileX = null;
            _lastTileY = null;
          });
        },
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
            controller: controller,
          ),
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
  final EditorController controller;
  _MapEditorPainter({
    required this.tilesX,
    required this.tilesY,
    required this.tileSize,
    required this.gridColor,
    required this.highlightColor,
    required this.hoverPosition,
    required this.controller,
  }) : super(repaint: controller);

  void _drawTiles(Canvas canvas, Size size, EditorController controller) {
    final tileset = controller.tilesetImage;
    if (tileset == null) return;
    final double srcW = controller.tilePixelWidth;
    final double srcH = controller.tilePixelHeight;
    final paint = Paint();
    for (
      int layerIndex = 0;
      layerIndex < controller.layers.length;
      layerIndex++
    ) {
      final layer = controller.layers[layerIndex];
      for (int y = 0; y < controller.tilesY; y++) {
        for (int x = 0; x < controller.tilesX; x++) {
          final ref = layer.tiles[y][x];
          if (ref == null) continue;
          final Rect src = Rect.fromLTWH(
            ref.tileX * srcW,
            ref.tileY * srcH,
            srcW,
            srcH,
          );
          final Rect dst = Rect.fromLTWH(
            x * tileSize,
            y * tileSize,
            tileSize,
            tileSize,
          );
          canvas.drawImageRect(tileset, src, dst, paint);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawTiles(canvas, size, controller);
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
    return hoverPosition != oldDelegate.hoverPosition ||
        tilesX != oldDelegate.tilesX ||
        tilesY != oldDelegate.tilesY ||
        tileSize != oldDelegate.tileSize ||
        gridColor != oldDelegate.gridColor ||
        highlightColor != oldDelegate.highlightColor ||
        controller != oldDelegate.controller;
  }
}
