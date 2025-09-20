import 'package:flutter/material.dart';

import 'scene.dart';
import 'scene_manager.dart';

class FadeTransitionScene extends Scene {
  final Scene from;
  final Scene to;
  double progress = 0.0; // 0 → 1
  final double duration;

  FadeTransitionScene(this.from, this.to, {this.duration = 1.0})
    : super(name: 'FadeTransition');

  @override
  void update(double dt) {
    progress += dt / duration;
    if (progress >= 1.0) {
      // fim: troca de fato para a cena "to"
      SceneManager.instance.setScene(to.name);
    }
  }

  @override
  void render(Canvas canvas, {Size? canvasSize}) {
    // desenha cena antiga
    from.render(canvas, canvasSize: canvasSize);

    // aplica fade sobre a cena nova
    final paint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, progress.clamp(0, 1).toDouble());
    to.render(canvas, canvasSize: canvasSize);
    if (canvasSize != null) {
      canvas.drawRect(Offset.zero & canvasSize, paint);
    }
  }
}
