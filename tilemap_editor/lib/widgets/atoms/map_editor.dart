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
  bool _dragPaint = false; // true pinta, false apaga (Alt/direito)
  int? _lastTileX;
  int? _lastTileY;
  EditorController? _controller;

  void _onControllerChanged() {
    // Rebuild para atualizar tamanho do canvas e grid quando tilesX/Y/tileSize mudarem
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = EditorScope.of(context);
    if (_controller != c) {
      _controller?.removeListener(_onControllerChanged);
      _controller = c;
      _controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

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
    if (controller.currentTool == EditingTool.bucket) {
      controller.floodFillAt(x, y, paint: paint);
    } else if (controller.currentTool == EditingTool.collision) {
      controller.setCollisionAt(x, y, add: paint);
    } else {
      controller.paintOrErase(x, y, paint: paint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller ?? EditorScope.of(context);
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
            final bool alt =
                keys.contains(LogicalKeyboardKey.altLeft) ||
                keys.contains(LogicalKeyboardKey.altRight);
            // esquerdo pinta; direito OU Alt apaga
            final bool erase = right || alt;
            _dragPaint = !erase;
          });
          if (_isDragging) {
            _handlePaintAt(e.localPosition, paint: _dragPaint);
            // Se for balde, não seguimos arrastando
            if (controller.currentTool == EditingTool.bucket) {
              setState(() {
                _isDragging = false;
              });
            }
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
            if (controller.currentTool == EditingTool.bucket)
              return; // sem drag com balde
            final bool right = (e.buttons & kSecondaryMouseButton) != 0;
            final bool alt =
                keys.contains(LogicalKeyboardKey.altLeft) ||
                keys.contains(LogicalKeyboardKey.altRight);
            final bool erase = right || alt; // direito/Alt apaga
            _dragPaint = !erase; // esquerdo pinta
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
        child: RepaintBoundary(
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
  final Path _gridPath;
  _MapEditorPainter({
    required this.tilesX,
    required this.tilesY,
    required this.tileSize,
    required this.gridColor,
    required this.highlightColor,
    required this.hoverPosition,
    required this.controller,
  }) : _gridPath = _buildGridPath(tilesX, tilesY, tileSize),
       super(repaint: controller);

  static Path _buildGridPath(int tilesX, int tilesY, double tileSize) {
    final Path path = Path();
    for (int x = 0; x <= tilesX; x++) {
      final double dx = x * tileSize;
      path.moveTo(dx, 0);
      path.lineTo(dx, tilesY * tileSize);
    }
    for (int y = 0; y <= tilesY; y++) {
      final double dy = y * tileSize;
      path.moveTo(0, dy);
      path.lineTo(tilesX * tileSize, dy);
    }
    return path;
  }

  void _drawTiles(Canvas canvas, Size size, EditorController controller) {
    final double srcW = controller.tilePixelWidth;
    final double srcH = controller.tilePixelHeight;
    final paint = Paint();
    // Desenha do fundo para o topo: o item que aparece no topo da lista
    // deve ser pintado por último (ficar acima dos demais).
    for (
      int layerIndex = controller.layers.length - 1;
      layerIndex >= 0;
      layerIndex--
    ) {
      final layer = controller.layers[layerIndex];
      if (!layer.visible) continue;
      final tilesetDef = controller.getTilesetById(layer.tilesetId);
      if (tilesetDef == null) continue;
      final tileset = tilesetDef.image;
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
    // Desenha overlay de colisões por layer
    _drawCollisions(canvas, size, controller);
    // Grid
    if (controller.showGrid) {
      final paint = Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke;
      canvas.drawPath(_gridPath, paint);
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

extension on _MapEditorPainter {
  void _drawCollisions(Canvas canvas, Size size, EditorController controller) {
    final Paint fill = Paint()..color = const Color(0x88FF0000);
    final Paint stroke = Paint()
      ..color = const Color(0xCCFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final layer in controller.layers) {
      if (!layer.visible || !layer.showCollisions) continue;
      final rects = _computeCollisionRects(layer.collisions);
      for (final r in rects) {
        final Rect canvasRect = Rect.fromLTWH(
          r.left * tileSize,
          r.top * tileSize,
          r.width * tileSize,
          r.height * tileSize,
        );
        canvas.drawRect(canvasRect, fill);
        canvas.drawRect(canvasRect, stroke);
      }
    }
  }

  List<RectInt> _computeCollisionRects(List<List<bool>> collisions) {
    final int h = collisions.length;
    if (h == 0) return const [];
    final int w = collisions[0].length;
    final List<List<bool>> visited = List.generate(
      h,
      (_) => List<bool>.filled(w, false, growable: false),
      growable: false,
    );
    final List<RectInt> rects = [];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (!collisions[y][x] || visited[y][x]) continue;
        // Expande retângulo máximo (unindo por linhas e colunas contíguas)
        int maxW = 1;
        while (x + maxW < w &&
            collisions[y][x + maxW] &&
            !visited[y][x + maxW]) {
          maxW++;
        }
        int maxH = 1;
        bool canExpandDown = true;
        while (y + maxH < h && canExpandDown) {
          for (int dx = 0; dx < maxW; dx++) {
            if (!collisions[y + maxH][x + dx] || visited[y + maxH][x + dx]) {
              canExpandDown = false;
              break;
            }
          }
          if (canExpandDown) {
            maxH++;
          }
        }
        // Marca visitados e adiciona retângulo
        for (int yy = y; yy < y + maxH; yy++) {
          for (int xx = x; xx < x + maxW; xx++) {
            visited[yy][xx] = true;
          }
        }
        rects.add(RectInt(left: x, top: y, width: maxW, height: maxH));
      }
    }
    return rects;
  }
}

class RectInt {
  final int left;
  final int top;
  final int width;
  final int height;
  const RectInt({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
