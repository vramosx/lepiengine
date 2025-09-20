import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

class GameLoop extends StatefulWidget {
  final void Function(double dt)? onUpdate;
  final void Function(Canvas canvas, Size size)? onRender;

  const GameLoop({super.key, this.onUpdate, this.onRender});

  @override
  State<GameLoop> createState() => _GameLoopState();
}

class _GameLoopState extends State<GameLoop>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;
  double fps = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (_lastTime == Duration.zero)
        ? 0
        : (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;

    if (dt > 0) fps = 1 / dt;

    widget.onUpdate?.call(dt.toDouble()); // chama callback de update
    setState(() {}); // dispara repaint
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GamePainter(fps: fps, onRender: widget.onRender),
      child: Container(),
    );
  }
}

class _GamePainter extends CustomPainter {
  final double fps;
  final void Function(Canvas canvas, Size size)? onRender;

  _GamePainter({required this.fps, this.onRender});

  @override
  void paint(Canvas canvas, Size size) {
    // fundo preto
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // chama callback de render (ex: SceneManager)
    onRender?.call(canvas, size);

    // debug FPS
    if (kDebugMode) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "FPS: ${fps.toStringAsFixed(0)}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(10, 10));
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}
