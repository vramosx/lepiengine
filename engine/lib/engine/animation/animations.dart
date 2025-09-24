import 'dart:math' as math;
import 'package:flutter/material.dart' hide Tween;
import 'package:lepiengine/engine/core/scene_manager.dart';
import '../core/game_object.dart';
import '../core/scene.dart';
import 'animation_manager.dart';
import 'easing.dart';
import 'tween.dart' as engine_anim;

/// API de alto nivel com helpers para criar e registrar animacoes.
class Animations {
  static AnimationManager of(Scene scene) => scene.animationManager;

  static engine_anim.Tween moveTo(
    GameObject target,
    Offset position,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.position;
    final delta = position - start;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.position = Offset(
          start.dx + delta.dx * p,
          start.dy + delta.dy * p,
        );
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween moveBy(
    GameObject target,
    Offset offset,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.position;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.position = Offset(
          start.dx + offset.dx * p,
          start.dy + offset.dy * p,
        );
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween rotateTo(
    GameObject target,
    double angle,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.rotation;
    final delta = angle - start;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.rotation = start + delta * p;
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween scaleTo(
    GameObject target,
    Offset scale,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.scale;
    final delta = Offset(scale.dx - start.dx, scale.dy - start.dy);
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.scale = Offset(start.dx + delta.dx * p, start.dy + delta.dy * p);
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween resize(
    GameObject target,
    Size size,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.size;
    final dw = size.width - start.width;
    final dh = size.height - start.height;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.size = Size(start.width + dw * p, start.height + dh * p);
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween fadeIn(
    GameObject target,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.opacity;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.opacity = (start + (1.0 - start) * p).clamp(0.0, 1.0);
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween fadeOut(
    GameObject target,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    final start = target.opacity;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.opacity = (start + (0.0 - start) * p).clamp(0.0, 1.0);
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween colorTo(
    GameObject target,
    Color color,
    double duration, {
    EasingType ease = EasingType.linear,
    BlendMode blendMode = BlendMode.modulate,
  }) {
    final start = target.tintColor ?? const Color(0xFFFFFFFF);
    final sr = start.red.toDouble();
    final sg = start.green.toDouble();
    final sb = start.blue.toDouble();
    final sa = start.alpha.toDouble();
    final er = color.red.toDouble();
    final eg = color.green.toDouble();
    final eb = color.blue.toDouble();
    final ea = color.alpha.toDouble();

    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        target.tintBlendMode = blendMode;
        target.tintColor = Color.fromARGB(
          (sa + (ea - sa) * p).round(),
          (sr + (er - sr) * p).round(),
          (sg + (eg - sg) * p).round(),
          (sb + (eb - sb) * p).round(),
        );
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween blink(
    GameObject target,
    Color color,
    double frequency,
    double duration,
  ) {
    // Alterna entre null e a cor fornecida na frequencia especificada
    bool on = false;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      onUpdate: (p) {
        // Usa dt implícito? Não temos dt aqui. Em vez disso, usa p para estimar ciclos
        final cycles = (p * duration * frequency);
        final whole = cycles.floor();
        final nextOn = whole % 2 == 0;
        if (nextOn != on) {
          on = nextOn;
        }
        target.tintColor = on ? color : null;
        target.tintBlendMode = BlendMode.modulate;
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween shake(
    GameObject target,
    double intensity,
    double duration, {
    EasingType ease = EasingType.easeOut,
  }) {
    final base = target.position;
    final rnd = math.Random();
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        final decay = 1.0 - p; // vai diminuindo
        final dx = (rnd.nextDouble() * 2 - 1) * intensity * decay;
        final dy = (rnd.nextDouble() * 2 - 1) * intensity * decay;
        target.position = Offset(base.dx + dx, base.dy + dy);
        if (p >= 1.0) target.position = base;
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween pulse(
    GameObject target,
    double scaleFactor,
    double duration, {
    int repeat = 1,
    EasingType ease = EasingType.easeInOut,
  }) {
    final start = target.scale;
    final up = engine_anim.Tween(
      target: target,
      duration: duration * 0.5,
      easing: ease,
      onUpdate: (p) {
        target.scale = Offset(
          start.dx * (1 + (scaleFactor - 1) * p),
          start.dy * (1 + (scaleFactor - 1) * p),
        );
      },
    );
    final down = engine_anim.Tween(
      target: target,
      duration: duration * 0.5,
      easing: ease,
      onUpdate: (p) {
        final q = 1 - p;
        target.scale = Offset(
          start.dx * (1 + (scaleFactor - 1) * q),
          start.dy * (1 + (scaleFactor - 1) * q),
        );
      },
    );

    final seq = engine_anim.SequenceTween(target: target, tweens: [up, down]);
    final rep = repeat <= 1
        ? seq
        : engine_anim.RepeatTween(target: target, tween: seq, count: repeat);
    final scene = SceneManager.instance.current!;
    of(scene).add(rep);
    return rep;
  }

  static engine_anim.Tween wiggle(
    GameObject target,
    double maxAngleRadians,
    double frequency,
    double duration, {
    bool decay = true,
  }) {
    final base = target.rotation;
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      onUpdate: (p) {
        final amp = decay ? (1.0 - p) : 1.0;
        final phase = 2 * math.pi * frequency * (p * duration);
        target.rotation = base + math.sin(phase) * maxAngleRadians * amp;
        if (p >= 1.0) target.rotation = base;
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.Tween pathFollow(
    GameObject target,
    List<Offset> points,
    double duration, {
    EasingType ease = EasingType.linear,
  }) {
    assert(points.length >= 2, 'pathFollow requer pelo menos 2 pontos');
    // Prepara comprimentos cumulativos
    final segments = <double>[];
    double totalLen = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final len = (points[i + 1] - points[i]).distance;
      segments.add(len);
      totalLen += len;
    }
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: (p) {
        final s = totalLen * p;
        double acc = 0.0;
        int segIndex = 0;
        while (segIndex < segments.length && acc + segments[segIndex] < s) {
          acc += segments[segIndex];
          segIndex++;
        }
        if (segIndex >= segments.length) {
          target.position = points.last;
          return;
        }
        final segStart = points[segIndex];
        final segEnd = points[segIndex + 1];
        final segLen = segments[segIndex];
        final local = segLen <= 0 ? 0.0 : ((s - acc) / segLen).clamp(0.0, 1.0);
        target.position = Offset(
          segStart.dx + (segEnd.dx - segStart.dx) * local,
          segStart.dy + (segEnd.dy - segStart.dy) * local,
        );
      },
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }

  static engine_anim.SequenceTween sequence(
    List<engine_anim.Tween> tweens,
    GameObject target,
  ) {
    final seq = engine_anim.SequenceTween(target: target, tweens: tweens);
    final scene = SceneManager.instance.current!;
    of(scene).add(seq);
    return seq;
  }

  static engine_anim.ParallelTween parallel(
    List<engine_anim.Tween> tweens,
    GameObject target,
  ) {
    final par = engine_anim.ParallelTween(target: target, tweens: tweens);
    final scene = SceneManager.instance.current!;
    of(scene).add(par);
    return par;
  }

  static engine_anim.RepeatTween repeat(
    engine_anim.Tween tween, {
    int count = 2,
  }) {
    final rep = engine_anim.RepeatTween(
      target: tween.target,
      tween: tween,
      count: count,
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(rep);
    return rep;
  }

  static engine_anim.RepeatTween forever(engine_anim.Tween tween) {
    final rep = engine_anim.RepeatTween(
      target: tween.target,
      tween: tween,
      count: null,
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(rep);
    return rep;
  }

  static engine_anim.Tween custom(
    GameObject target,
    double duration, {
    EasingType ease = EasingType.linear,
    required void Function(double t) onUpdate,
  }) {
    final t = engine_anim.Tween(
      target: target,
      duration: duration,
      easing: ease,
      onUpdate: onUpdate,
    );
    final scene = SceneManager.instance.current!;
    of(scene).add(t);
    return t;
  }
}
