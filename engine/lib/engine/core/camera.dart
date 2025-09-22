import 'dart:math' as math;
import 'dart:ui';
import 'game_object.dart';

/// Sistema de câmera 2D com funcionalidades de posição, zoom, follow e transformações.
///
/// A câmera mantém uma posição no mundo que representa o ponto focal (centro da tela).
/// Suporta zoom com limites, seguimento suave de objetos e conversões de coordenadas.
class Camera {
  Camera({
    Offset? position,
    double zoom = 1.0,
    this.minZoom = 0.1,
    this.maxZoom = 10.0,
    this.followLerp = 0.05,
  }) : _position = position ?? Offset.zero,
       _zoom = zoom.clamp(minZoom, maxZoom);

  // ============= Posição =============

  /// Posição da câmera no mundo (ponto focal que fica no centro da tela)
  Offset _position;
  Offset get position => _position;

  // ============= Zoom =============

  /// Fator de zoom atual (1.0 = escala normal, >1.0 = aproxima, <1.0 = afasta)
  double _zoom;
  double get zoom => _zoom;

  /// Limite mínimo de zoom
  final double minZoom;

  /// Limite máximo de zoom
  final double maxZoom;

  /// Opacidade atual do fade (0.0 = completamente transparente, 1.0 = opaco)
  double get fadeOpacity => _fadeOpacity;

  /// Define o zoom respeitando os limites
  void setZoom(double value) {
    _zoom = value.clamp(minZoom, maxZoom);
  }

  /// Ajusta o zoom incrementalmente
  void addZoom(double delta) {
    setZoom(_zoom + delta);
  }

  // ============= Sistema de Follow =============

  /// Objeto que a câmera está seguindo
  GameObject? _followTarget;
  GameObject? get followTarget => _followTarget;

  /// Velocidade de interpolação para o follow (0.0-1.0)
  /// 1.0 = cola direto no alvo, valores menores = movimento suave
  final double followLerp;

  // ============= Efeitos de Câmera =============

  /// Efeito de shake (tremor)
  Offset _shakeOffset = Offset.zero;
  double _shakeIntensity = 0.0;
  double _shakeDuration = 0.0;
  double _shakeTimer = 0.0;

  /// Efeito de fade
  double _fadeOpacity = 1.0;
  double _fadeDuration = 0.0;
  double _fadeTimer = 0.0;
  double _fadeStartOpacity = 1.0;
  double _fadeTargetOpacity = 1.0;

  /// Efeito de zoom pulse
  double _pulseZoomOffset = 0.0;
  double _pulseIntensity = 0.0;
  double _pulseDuration = 0.0;
  double _pulseTimer = 0.0;

  // ============= Limites do Mundo =============

  /// Limites do mundo que a câmera não pode ultrapassar.
  /// Se for null, a câmera é livre (sem restrição).
  Rect? worldBounds;

  /// Define qual objeto a câmera deve seguir
  void follow(GameObject? target) {
    _followTarget = target;
  }

  /// Para de seguir qualquer objeto
  void stopFollowing() {
    _followTarget = null;
  }

  /// Define os limites do mundo para a câmera
  void setWorldBounds(Rect bounds) {
    worldBounds = bounds;
  }

  /// Remove os limites (câmera livre)
  void clearWorldBounds() {
    worldBounds = null;
  }

  // ============= Métodos dos Efeitos =============

  /// Inicia um efeito de shake (tremor) na câmera
  /// [intensity] - intensidade do tremor em pixels
  /// [duration] - duração do efeito em segundos
  void startShake(double intensity, double duration) {
    _shakeIntensity = intensity;
    _shakeDuration = duration;
    _shakeTimer = 0.0;
  }

  /// Para o efeito de shake imediatamente
  void stopShake() {
    _shakeIntensity = 0.0;
    _shakeDuration = 0.0;
    _shakeTimer = 0.0;
    _shakeOffset = Offset.zero;
  }

  /// Inicia um efeito de fade
  /// [targetOpacity] - opacidade final (0.0 = transparente, 1.0 = opaco)
  /// [duration] - duração do efeito em segundos
  void startFade(double targetOpacity, double duration) {
    _fadeStartOpacity = _fadeOpacity;
    _fadeTargetOpacity = targetOpacity.clamp(0.0, 1.0);
    _fadeDuration = duration;
    _fadeTimer = 0.0;
  }

  /// Fade in (aparecer gradualmente)
  void fadeIn(double duration) {
    startFade(1.0, duration);
  }

  /// Fade out (desaparecer gradualmente)
  void fadeOut(double duration) {
    startFade(0.0, duration);
  }

  /// Para o efeito de fade e define a opacidade imediatamente
  void stopFade([double? opacity]) {
    _fadeDuration = 0.0;
    _fadeTimer = 0.0;
    if (opacity != null) {
      _fadeOpacity = opacity.clamp(0.0, 1.0);
      _fadeStartOpacity = _fadeOpacity;
      _fadeTargetOpacity = _fadeOpacity;
    }
  }

  /// Inicia um efeito de zoom pulse
  /// [intensity] - intensidade do pulse (quanto o zoom vai variar)
  /// [duration] - duração do efeito em segundos
  void startZoomPulse(double intensity, double duration) {
    _pulseIntensity = intensity;
    _pulseDuration = duration;
    _pulseTimer = 0.0;
  }

  /// Para o efeito de zoom pulse imediatamente
  void stopZoomPulse() {
    _pulseIntensity = 0.0;
    _pulseDuration = 0.0;
    _pulseTimer = 0.0;
    _pulseZoomOffset = 0.0;
  }

  // ============= Efeitos Pré-definidos =============

  /// Shake leve para impactos pequenos
  void lightShake() {
    startShake(5.0, 0.3);
  }

  /// Shake médio para explosões
  void mediumShake() {
    startShake(15.0, 0.6);
  }

  /// Shake forte para impactos grandes
  void heavyShake() {
    startShake(30.0, 1.0);
  }

  /// Zoom pulse rápido para impacto
  void impactPulse() {
    startZoomPulse(0.2, 0.4);
  }

  /// Zoom pulse suave para efeitos especiais
  void softPulse() {
    startZoomPulse(0.1, 0.8);
  }

  // ============= Update e Lógica =============

  /// Atualiza a câmera (deve ser chamado a cada frame)
  void update(double dt) {
    // Aplica limites de zoom
    _zoom = _zoom.clamp(minZoom, maxZoom);

    // Atualiza efeitos de câmera
    _updateEffects(dt);

    // Sistema de follow com interpolação frame-rate aware
    if (_followTarget != null) {
      final targetPos = Offset(
        _followTarget!.position.dx,
        _followTarget!.position.dy,
      );

      // Interpolação exponencial frame-rate independent
      final alpha = _expLerpAlpha(followLerp, dt);
      _position = Offset(
        _lerpDouble(_position.dx, targetPos.dx, alpha),
        _lerpDouble(_position.dy, targetPos.dy, alpha),
      );
    }

    // Aplica restrições de worldBounds se definidas
    _applyWorldBounds();
  }

  /// Calcula alpha para interpolação exponencial frame-rate independent
  double _expLerpAlpha(double rate, double dt) {
    return 1.0 - math.exp(-rate * dt * 60.0); // 60 FPS como base
  }

  /// Interpolação linear entre dois doubles
  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Aplica restrições de worldBounds à posição da câmera
  void _applyWorldBounds() {
    if (worldBounds == null) return;

    // Simplesmente limita a posição da câmera aos worldBounds
    _position = Offset(
      _position.dx.clamp(worldBounds!.left, worldBounds!.right),
      _position.dy.clamp(worldBounds!.top, worldBounds!.bottom),
    );
  }

  /// Atualiza todos os efeitos de câmera
  void _updateEffects(double dt) {
    _updateShakeEffect(dt);
    _updateFadeEffect(dt);
    _updateZoomPulseEffect(dt);
  }

  /// Atualiza o efeito de shake
  void _updateShakeEffect(double dt) {
    if (_shakeDuration <= 0 || _shakeIntensity <= 0) {
      _shakeOffset = Offset.zero;
      return;
    }

    _shakeTimer += dt;

    if (_shakeTimer >= _shakeDuration) {
      // Efeito terminou
      _shakeIntensity = 0.0;
      _shakeDuration = 0.0;
      _shakeOffset = Offset.zero;
      return;
    }

    // Calcula intensidade diminuindo ao longo do tempo
    final progress = _shakeTimer / _shakeDuration;
    final currentIntensity = _shakeIntensity * (1.0 - progress);

    // Gera offset aleatório
    final angle = math.Random().nextDouble() * math.pi * 2;
    final distance = math.Random().nextDouble() * currentIntensity;

    _shakeOffset = Offset(
      math.cos(angle) * distance,
      math.sin(angle) * distance,
    );
  }

  /// Atualiza o efeito de fade
  void _updateFadeEffect(double dt) {
    if (_fadeDuration <= 0) return;

    _fadeTimer += dt;

    if (_fadeTimer >= _fadeDuration) {
      // Efeito terminou
      _fadeOpacity = _fadeTargetOpacity;
      _fadeDuration = 0.0;
      return;
    }

    // Interpolação linear
    final progress = _fadeTimer / _fadeDuration;
    _fadeOpacity = _lerpDouble(_fadeStartOpacity, _fadeTargetOpacity, progress);
  }

  /// Atualiza o efeito de zoom pulse
  void _updateZoomPulseEffect(double dt) {
    if (_pulseDuration <= 0 || _pulseIntensity <= 0) {
      _pulseZoomOffset = 0.0;
      return;
    }

    _pulseTimer += dt;

    if (_pulseTimer >= _pulseDuration) {
      // Efeito terminou
      _pulseIntensity = 0.0;
      _pulseDuration = 0.0;
      _pulseZoomOffset = 0.0;
      return;
    }

    // Calcula pulse usando uma função senoidal
    final progress = _pulseTimer / _pulseDuration;
    final sineWave = math.sin(progress * math.pi * 4); // 2 pulsos completos
    final decay = 1.0 - progress; // Diminui a intensidade ao longo do tempo

    _pulseZoomOffset = sineWave * _pulseIntensity * decay;
  }

  // ============= Transformações de Render =============

  /// Aplica a transformação da câmera no Canvas
  /// Deve ser chamado antes de desenhar os objetos do mundo
  void applyTransform(Canvas canvas, Size viewport) {
    // 1. Translada para colocar o centro da tela na origem
    // canvas.translate(viewport.width * 0.5, viewport.height * 0.5);

    // 2. Aplica o zoom (incluindo efeito de pulse)
    final effectiveZoom = _zoom + _pulseZoomOffset;
    canvas.scale(effectiveZoom);

    // 3. Translada para a posição da câmera (invertida) incluindo shake
    final effectivePosition = _position + _shakeOffset;
    canvas.translate(-effectivePosition.dx, -effectivePosition.dy);
  }

  // ============= Conversões de Coordenadas =============

  /// Converte coordenadas do mundo para coordenadas da tela
  Offset worldToScreen(Offset worldPos, Size viewport) {
    // Aplica a transformação da câmera (incluindo efeitos)
    final effectivePosition = _position + _shakeOffset;
    final effectiveZoom = _zoom + _pulseZoomOffset;

    final camRelative = worldPos - effectivePosition;
    final scaled = Offset(
      camRelative.dx * effectiveZoom,
      camRelative.dy * effectiveZoom,
    );
    final screenPos =
        scaled + Offset(viewport.width * 0.5, viewport.height * 0.5);
    return screenPos;
  }

  /// Converte coordenadas da tela para coordenadas do mundo
  Offset screenToWorld(Offset screenPos, Size viewport) {
    // Inverte a transformação da câmera (incluindo efeitos)
    final effectivePosition = _position + _shakeOffset;
    final effectiveZoom = _zoom + _pulseZoomOffset;

    final centered =
        screenPos - Offset(viewport.width * 0.5, viewport.height * 0.5);
    final unscaled = Offset(
      centered.dx / effectiveZoom,
      centered.dy / effectiveZoom,
    );
    final worldPos = unscaled + effectivePosition;
    return worldPos;
  }

  /// Renderiza o efeito de fade sobre toda a tela
  /// Deve ser chamado APÓS desenhar todos os objetos do mundo
  void renderFadeEffect(Canvas canvas, Size viewport) {
    if (_fadeOpacity >= 1.0) {
      return; // Não precisa renderizar se totalmente opaco
    }

    final paint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, 1.0 - _fadeOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, viewport.width, viewport.height),
      paint,
    );
  }

  // ============= Viewport e Área Visível =============

  /// Retorna o retângulo do mundo que está visível na tela
  Rect viewRect(Size viewport) {
    final effectiveZoom = _zoom + _pulseZoomOffset;
    final effectivePosition = _position + _shakeOffset;

    final halfWidth = (viewport.width * 0.5) / effectiveZoom;
    final halfHeight = (viewport.height * 0.5) / effectiveZoom;

    return Rect.fromCenter(
      center: effectivePosition,
      width: halfWidth * 2,
      height: halfHeight * 2,
    );
  }

  /// Verifica se um ponto do mundo está visível na câmera
  bool isWorldPointVisible(Offset worldPos, Size viewport) {
    return viewRect(viewport).contains(worldPos);
  }

  /// Verifica se um retângulo do mundo está (pelo menos parcialmente) visível
  bool isWorldRectVisible(Rect worldRect, Size viewport) {
    return viewRect(viewport).overlaps(worldRect);
  }

  /// Verifica se um GameObject está visível na câmera
  bool isGameObjectVisible(GameObject obj, Size viewport) {
    return isWorldRectVisible(obj.worldAABB(), viewport);
  }

  // ============= Utilitários =============

  /// Move a câmera para uma posição específica instantaneamente
  void moveTo(Offset newPosition) {
    _position = newPosition;
    _applyWorldBounds();
  }

  /// Move a câmera por um delta
  void moveBy(Offset delta) {
    _position += delta;
    _applyWorldBounds();
  }

  /// Foca a câmera em um GameObject específico instantaneamente
  void focusOn(GameObject obj) {
    final targetPos = obj.localToWorld(
      Offset(obj.size.width * 0.5, obj.size.height * 0.5),
    );
    moveTo(targetPos);
  }

  /// Centraliza a câmera na origem do mundo
  void centerOnOrigin() {
    moveTo(Offset.zero);
  }

  /// Retorna informações de debug da câmera
  Map<String, dynamic> getDebugInfo() {
    return {
      'position':
          '(${_position.dx.toStringAsFixed(1)}, ${_position.dy.toStringAsFixed(1)})',
      'zoom': _zoom.toStringAsFixed(2),
      'followTarget': _followTarget?.name ?? 'none',
      'followLerp': followLerp,
      'zoomLimits':
          '${minZoom.toStringAsFixed(1)} - ${maxZoom.toStringAsFixed(1)}',
      'worldBounds': worldBounds != null
          ? '(${worldBounds!.left.toStringAsFixed(1)}, ${worldBounds!.top.toStringAsFixed(1)}, ${worldBounds!.width.toStringAsFixed(1)}x${worldBounds!.height.toStringAsFixed(1)})'
          : 'none',
      'effects': {
        'shake': _shakeIntensity > 0
            ? 'intensity: ${_shakeIntensity.toStringAsFixed(1)}, time: ${(_shakeDuration - _shakeTimer).toStringAsFixed(2)}s'
            : 'none',
        'fade': _fadeDuration > 0
            ? 'opacity: ${_fadeOpacity.toStringAsFixed(2)}, target: ${_fadeTargetOpacity.toStringAsFixed(2)}'
            : 'opacity: ${_fadeOpacity.toStringAsFixed(2)}',
        'zoomPulse': _pulseIntensity > 0
            ? 'intensity: ${_pulseIntensity.toStringAsFixed(2)}, time: ${(_pulseDuration - _pulseTimer).toStringAsFixed(2)}s'
            : 'none',
      },
    };
  }

  @override
  String toString() {
    return 'Camera(pos: $_position, zoom: ${_zoom.toStringAsFixed(2)}, target: ${_followTarget?.name ?? 'none'})';
  }
}
