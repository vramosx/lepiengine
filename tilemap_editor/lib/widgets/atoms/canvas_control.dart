import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CanvasControl extends StatelessWidget {
  final Widget child;
  final double scale;
  final Offset position;
  final double maxScale;
  final double minScale;
  final Function(double scale)? onScale;
  final Function(Offset newPosition)? onDrag;
  final Function()? onTap;

  const CanvasControl({
    super.key,
    this.maxScale = 8.0,
    this.minScale = 0.2,
    required this.child,
    required this.scale,
    this.onScale,
    this.onTap,
    required this.position,
    this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    var internalScale = scale;
    if (internalScale < minScale) {
      internalScale = minScale;
    }
    if (internalScale > maxScale) {
      internalScale = maxScale;
    }
    var transformMatrix = Matrix4.identity()
      ..scale(internalScale, internalScale)
      ..translate(position.dx / internalScale, position.dy / internalScale);

    return Listener(
      onPointerUp: (event) {
        // debugPrint('[CanvasControl] onPointerUp - ${event.toString()}');
        onTap?.call();
      },
      onPointerSignal: (event) {
        // debugPrint('[CanvasControl] onPointerSignal - ${event.toString()}');
        if (event is PointerScrollEvent) {
          var newScale = internalScale + -event.scrollDelta.dy / 1000;
          onScale?.call(newScale);
        }
      },
      onPointerMove: (event) {
        //debugPrint('[CanvasControl] onPointerMove - ${event.toString()}');
        var dx = position.dx + event.delta.dx;
        var dy = position.dy + event.delta.dy;

        var newPosition = Offset(dx, dy);
        onDrag?.call(newPosition);
      },
      child: Container(
        color: Colors.transparent,
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: Transform(transform: transformMatrix, child: child),
      ),
    );
  }
}
