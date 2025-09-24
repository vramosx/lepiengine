import 'tween.dart';

/// Gerencia tweens ativos na cena.
class AnimationManager {
  final List<Tween> _tweens = <Tween>[];

  void add(Tween tween) {
    _tweens.add(tween);
    if (tween.autostart) tween.start();
  }

  void remove(Tween tween) {
    _tweens.remove(tween);
  }

  void clear() {
    _tweens.clear();
  }

  void update(double dt) {
    // Atualiza copia para permitir remocoes durante iteracao
    final list = List<Tween>.from(_tweens);
    for (final t in list) {
      t.update(dt);
      if (t.isFinished) {
        _tweens.remove(t);
      }
    }
  }
}
