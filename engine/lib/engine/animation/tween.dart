import '../core/game_object.dart';
import 'easing.dart';

typedef TweenUpdate = void Function(double t);
typedef TweenComplete = void Function();

/// Representa uma animacao temporal que interpola de 0..1 ao longo da duracao.
class Tween {
  Tween({
    required this.target,
    required this.duration,
    this.easing = EasingType.linear,
    required this.onUpdate,
    this.onComplete,
    this.autostart = true,
  });

  final GameObject target;
  final double duration; // segundos
  final EasingType easing;
  final TweenUpdate onUpdate;
  final TweenComplete? onComplete;
  final bool autostart;

  double _elapsed = 0.0;
  bool _active = false;
  bool _finished = false;

  bool get isActive => _active && !_finished;
  bool get isFinished => _finished;

  void start() {
    _elapsed = 0.0;
    _active = true;
    _finished = false;
  }

  void stop({bool complete = false}) {
    _active = false;
    if (complete && !_finished) {
      _finished = true;
      onComplete?.call();
    }
  }

  void update(double dt) {
    if (_finished || !_active) return;

    _elapsed += dt;
    double t = (_elapsed / duration).clamp(0.0, 1.0);
    t = Easing.apply(t, easing);
    onUpdate(t);

    if (_elapsed >= duration) {
      _finished = true;
      _active = false;
      onComplete?.call();
    }
  }
}

/// Tween que executa uma lista em sequencia.
class SequenceTween extends Tween {
  SequenceTween({
    required super.target,
    required List<Tween> tweens,
    super.onComplete,
  }) : _tweens = tweens,
       super(duration: _totalDuration(tweens), onUpdate: (_) {});

  final List<Tween> _tweens;
  int _index = 0;

  static double _totalDuration(List<Tween> list) =>
      list.fold(0.0, (p, e) => p + e.duration);

  @override
  void start() {
    super.start();
    _index = 0;
    if (_tweens.isNotEmpty) {
      _tweens[_index].start();
    }
  }

  @override
  void update(double dt) {
    if (isFinished) return;
    if (_tweens.isEmpty) {
      stop(complete: true);
      return;
    }
    final current = _tweens[_index];
    if (!current.isActive && !current.isFinished) current.start();
    current.update(dt);
    if (current.isFinished) {
      _index++;
      if (_index >= _tweens.length) {
        stop(complete: true);
      } else {
        _tweens[_index].start();
      }
    }
  }
}

/// Tween que executa varias animacoes em paralelo (duracao = max das duracoes).
class ParallelTween extends Tween {
  ParallelTween({
    required super.target,
    required List<Tween> tweens,
    super.onComplete,
  }) : _tweens = tweens,
       super(duration: _maxDuration(tweens), onUpdate: (_) {});

  final List<Tween> _tweens;

  static double _maxDuration(List<Tween> list) {
    double m = 0.0;
    for (final t in list) {
      if (t.duration > m) m = t.duration;
    }
    return m;
  }

  @override
  void start() {
    super.start();
    for (final t in _tweens) {
      t.start();
    }
  }

  @override
  void update(double dt) {
    if (isFinished) return;
    bool allFinished = true;
    for (final t in _tweens) {
      if (!t.isFinished) {
        t.update(dt);
      }
      if (!t.isFinished) allFinished = false;
    }
    if (allFinished) {
      stop(complete: true);
    }
  }
}

/// Tween que repete outro tween um numero de vezes ou para sempre.
class RepeatTween extends Tween {
  RepeatTween({
    required super.target,
    required Tween tween,
    int? count,
    super.onComplete,
  }) : _child = tween,
       _count = count,
       super(
         duration: count == null ? double.infinity : tween.duration * count,
         onUpdate: (_) {},
       );

  final Tween _child;
  final int? _count;
  int _played = 0;

  @override
  void start() {
    _played = 0;
    super.start();
    _child.start();
  }

  @override
  void update(double dt) {
    if (isFinished) return;
    _child.update(dt);
    if (_child.isFinished) {
      _played++;
      if (_count != null && _played >= _count) {
        stop(complete: true);
      } else {
        _child.start();
      }
    }
  }
}
