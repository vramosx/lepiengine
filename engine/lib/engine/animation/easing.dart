import 'dart:math' as math;

/// Tipos de easing comuns para tweens/animacoes.
enum EasingType { linear, easeIn, easeOut, easeInOut, bounce, elastic }

/// Funcoes utilitarias de easing.
class Easing {
  static double apply(double t, EasingType type) {
    switch (type) {
      case EasingType.linear:
        return t;
      case EasingType.easeIn:
        return _easeInCubic(t);
      case EasingType.easeOut:
        return _easeOutCubic(t);
      case EasingType.easeInOut:
        return _easeInOutCubic(t);
      case EasingType.bounce:
        return _bounceOut(t);
      case EasingType.elastic:
        return _elasticOut(t);
    }
  }

  static double _easeInCubic(double t) => t * t * t;
  static double _easeOutCubic(double t) {
    final p = t - 1.0;
    return p * p * p + 1.0;
  }

  static double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      final p = 2 * t - 2;
      return 0.5 * p * p * p + 1.0;
    }
  }

  // Bounce easing (versao out). Fonte baseada em aproximacao popular.
  static double _bounceOut(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      t -= 1.5 / d1;
      return n1 * t * t + 0.75;
    } else if (t < 2.5 / d1) {
      t -= 2.25 / d1;
      return n1 * t * t + 0.9375;
    } else {
      t -= 2.625 / d1;
      return n1 * t * t + 0.984375;
    }
  }

  // Elastic easing (versao out). Parametros padrao razoaveis.
  static double _elasticOut(double t) {
    const c4 = (2 * math.pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return math.pow(2, -10 * t).toDouble() * math.sin((t * 10 - 0.75) * c4) + 1;
  }
}
