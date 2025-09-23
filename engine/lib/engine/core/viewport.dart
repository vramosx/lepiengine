import 'dart:ui';
import 'camera.dart';

/// Modos de escala para adaptar a resolução de referência à tela real.
enum ScalingMode { fitWidth, fitHeight, contain, cover, stretch }

/// Insets de área segura (safe area) em pixels de tela.
class SafeAreaInsets {
  const SafeAreaInsets({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  static const zero = SafeAreaInsets();
}

/// Configuração da Viewport.
class ViewportConfig {
  const ViewportConfig({
    required this.referenceWidth,
    required this.referenceHeight,
    this.mode = ScalingMode.contain,
    this.respectSafeArea = true,
    this.debugEnabled = false,
    this.letterboxColor = const Color(0xFF000000),
  }) : assert(referenceWidth > 0 && referenceHeight > 0);

  final double referenceWidth;
  final double referenceHeight;
  final ScalingMode mode;
  final bool respectSafeArea;
  final bool debugEnabled;
  final Color letterboxColor;
}

/// Resultado do cálculo da viewport para um determinado tamanho de tela.
class ViewportMetrics {
  const ViewportMetrics({
    required this.screenSize,
    required this.safeArea,
    required this.scaleX,
    required this.scaleY,
    required this.contentOffset,
    required this.contentSizePx,
    required this.logicalViewportSize,
    required this.aspectRatioScreen,
    required this.aspectRatioReference,
  });

  final Size screenSize; // tamanho total do widget/canvas em px
  final SafeAreaInsets safeArea; // em px

  final double scaleX; // escala aplicada no eixo X
  final double scaleY; // escala aplicada no eixo Y
  final Offset contentOffset; // offset da área de conteúdo (letter/pillar box)
  final Size contentSizePx; // área de conteúdo em px reais
  final Size logicalViewportSize; // área lógica visível na resolução base
  final double aspectRatioScreen; // tela (após safe area se respeitada)
  final double aspectRatioReference; // W/H da referência
}

/// Responsável por mapear a resolução base para a tela real e fornecer
/// utilitários de conversão entre coordenadas de tela e mundo.
class Viewport {
  Viewport(ViewportConfig config) : _config = config;

  ViewportConfig _config;
  ViewportConfig get config => _config;
  set config(ViewportConfig value) {
    _config = value;
  }

  ViewportMetrics? _lastMetrics;
  ViewportMetrics? get lastMetrics => _lastMetrics;

  // ===== Cálculo =====

  void update({
    required Size screenSize,
    SafeAreaInsets safeArea = SafeAreaInsets.zero,
  }) {
    // Calcula área disponível considerando safe area
    final double availLeft = _config.respectSafeArea ? safeArea.left : 0.0;
    final double availTop = _config.respectSafeArea ? safeArea.top : 0.0;
    final double availRight = _config.respectSafeArea ? safeArea.right : 0.0;
    final double availBottom = _config.respectSafeArea ? safeArea.bottom : 0.0;

    final double availWidth = (screenSize.width - availLeft - availRight).clamp(
      0.0,
      double.infinity,
    );
    final double availHeight = (screenSize.height - availTop - availBottom)
        .clamp(0.0, double.infinity);

    final double refW = _config.referenceWidth;
    final double refH = _config.referenceHeight;
    final double refAspect = refW / refH;
    final double screenAspect = availWidth > 0 && availHeight > 0
        ? (availWidth / availHeight)
        : refAspect;

    double scaleX = 1.0;
    double scaleY = 1.0;

    switch (_config.mode) {
      case ScalingMode.fitWidth:
        scaleX = availWidth / refW;
        scaleY = scaleX;
        break;
      case ScalingMode.fitHeight:
        scaleY = availHeight / refH;
        scaleX = scaleY;
        break;
      case ScalingMode.contain:
        final s = _min(availWidth / refW, availHeight / refH);
        scaleX = s;
        scaleY = s;
        break;
      case ScalingMode.cover:
        final s = _max(availWidth / refW, availHeight / refH);
        scaleX = s;
        scaleY = s;
        break;
      case ScalingMode.stretch:
        scaleX = availWidth / refW;
        scaleY = availHeight / refH;
        break;
    }

    // Tamanho da área de conteúdo em px reais após escala
    final contentW = refW * scaleX;
    final contentH = refH * scaleY;

    // Offset para centralizar a área de conteúdo dentro da área disponível
    final double offsetX = availLeft + (availWidth - contentW) * 0.5;
    final double offsetY = availTop + (availHeight - contentH) * 0.5;

    // Tamanho lógico visível em unidades da referência
    final logicalViewportW = contentW / scaleX; // pode ser > refW em cover
    final logicalViewportH = contentH / scaleY;

    _lastMetrics = ViewportMetrics(
      screenSize: screenSize,
      safeArea: safeArea,
      scaleX: scaleX,
      scaleY: scaleY,
      contentOffset: Offset(offsetX, offsetY),
      contentSizePx: Size(contentW, contentH),
      logicalViewportSize: Size(logicalViewportW, logicalViewportH),
      aspectRatioScreen: screenAspect,
      aspectRatioReference: refAspect,
    );
  }

  // ===== Aplicação em Canvas =====

  void applyCanvasTransform(Canvas canvas) {
    final m = _ensureMetrics();
    canvas.translate(m.contentOffset.dx, m.contentOffset.dy);
    canvas.scale(m.scaleX, m.scaleY);
  }

  // ===== Utilitários =====

  double get scaleFactor => _ensureMetrics().scaleX; // uniforme exceto stretch
  double get scaleFactorX => _ensureMetrics().scaleX;
  double get scaleFactorY => _ensureMetrics().scaleY;
  Size get contentSizePixels => _ensureMetrics().contentSizePx;
  Size get logicalViewportSize => _ensureMetrics().logicalViewportSize;
  double get screenAspectRatio => _ensureMetrics().aspectRatioScreen;

  /// Converte coordenadas de tela (px reais) para o mundo (resolução base),
  /// levando em conta offset/escala da viewport e a câmera.
  Offset screenToWorld(Offset screenPos, Camera camera) {
    final m = _ensureMetrics();
    // 1) tela real -> espaço lógico (resolução base)
    final logical = Offset(
      (screenPos.dx - m.contentOffset.dx) / m.scaleX,
      (screenPos.dy - m.contentOffset.dy) / m.scaleY,
    );
    // 2) espaço lógico -> mundo (usa a câmera)
    return camera.screenToWorld(logical, m.logicalViewportSize);
  }

  /// Converte coordenadas do mundo (resolução base) para tela (px reais),
  /// levando em conta a câmera e a viewport.
  Offset worldToScreen(Offset worldPos, Camera camera) {
    final m = _ensureMetrics();
    // 1) mundo -> espaço lógico
    final logical = camera.worldToScreen(worldPos, m.logicalViewportSize);
    // 2) lógico -> tela real
    return Offset(
      m.contentOffset.dx + logical.dx * m.scaleX,
      m.contentOffset.dy + logical.dy * m.scaleY,
    );
  }

  /// Desenha guias visuais da viewport e safe area para debug.
  void debugRender(Canvas canvas) {
    if (!_config.debugEnabled) return;
    final m = _ensureMetrics();

    // Preenche letter/pillar boxes com cor definida
    final paintBg = Paint()..color = _config.letterboxColor.withOpacity(0.8);

    // Áreas fora do conteúdo: top, bottom, left, right
    // Top
    if (m.contentOffset.dy > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, m.screenSize.width, m.contentOffset.dy),
        paintBg,
      );
    }
    // Bottom
    final bottomTop = m.contentOffset.dy + m.contentSizePx.height;
    if (bottomTop < m.screenSize.height) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          bottomTop,
          m.screenSize.width,
          m.screenSize.height - bottomTop,
        ),
        paintBg,
      );
    }
    // Left
    if (m.contentOffset.dx > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, m.contentOffset.dx, m.screenSize.height),
        paintBg,
      );
    }
    // Right
    final rightLeft = m.contentOffset.dx + m.contentSizePx.width;
    if (rightLeft < m.screenSize.width) {
      canvas.drawRect(
        Rect.fromLTWH(
          rightLeft,
          0,
          m.screenSize.width - rightLeft,
          m.screenSize.height,
        ),
        paintBg,
      );
    }

    // Borda do conteúdo
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF00FF00);
    canvas.drawRect(
      Rect.fromLTWH(
        m.contentOffset.dx,
        m.contentOffset.dy,
        m.contentSizePx.width,
        m.contentSizePx.height,
      ),
      border,
    );

    // Borda do safe area (área utilizável)
    final sa = m.safeArea;
    final usable = Rect.fromLTWH(
      sa.left,
      sa.top,
      m.screenSize.width - sa.left - sa.right,
      m.screenSize.height - sa.top - sa.bottom,
    );
    final safePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFD400);
    canvas.drawRect(usable, safePaint);
  }

  ViewportMetrics _ensureMetrics() {
    final m = _lastMetrics;
    assert(
      m != null,
      'Viewport.update() precisa ser chamado antes de usar a viewport.',
    );
    return m!;
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;
}
