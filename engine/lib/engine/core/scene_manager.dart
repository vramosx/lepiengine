import 'dart:ui';
import 'scene.dart';
import 'viewport.dart';

class SceneManager {
  SceneManager._();

  static final SceneManager instance = SceneManager._();

  final List<Scene> _scenes = [];

  Scene? _currentScene;

  Scene? get current => _currentScene;

  // ----------------- Viewport -----------------
  Viewport _viewport = Viewport(
    ViewportConfig(referenceWidth: 1920, referenceHeight: 1080),
  );
  SafeAreaInsets _safeAreaInsets = SafeAreaInsets.zero;

  Viewport get viewport => _viewport;

  void configureViewport(ViewportConfig config) {
    _viewport = Viewport(config);
  }

  void setSafeAreaInsets(SafeAreaInsets insets) {
    _safeAreaInsets = insets;
  }

  // Getters úteis
  double get scaleFactor => _viewport.scaleFactor;
  double get scaleFactorX => _viewport.scaleFactorX;
  double get scaleFactorY => _viewport.scaleFactorY;
  Size get logicalViewportSize => _viewport.logicalViewportSize;
  Size get viewportSizePixels => _viewport.contentSizePixels;
  double get screenAspectRatio => _viewport.screenAspectRatio;

  // Conversões utilitárias
  Offset screenToWorld(Offset screenPos) {
    final scene = _currentScene;
    if (scene == null) return screenPos;
    return _viewport.screenToWorld(screenPos, scene.camera);
  }

  Offset worldToScreen(Offset worldPos) {
    final scene = _currentScene;
    if (scene == null) return worldPos;
    return _viewport.worldToScreen(worldPos, scene.camera);
  }

  // ----------------- Stack -----------------

  void addScene(Scene scene) {
    _scenes.add(scene);
  }

  void removeScene(Scene scene) {
    _scenes.remove(scene);
  }

  void setScene(String name) {
    final scene = _scenes.firstWhere((s) => s.name == name);
    current?.onExit();
    _currentScene = scene;
    if (!scene.mounted) {
      scene.mounted = true;
      scene.onEnter();
    } else {
      scene.clearAll();
      scene.onEnter();
    }
  }

  void clearAllScenes() {
    _scenes.clear();
    _currentScene = null;
  }

  // ----------------- Loop -----------------

  void update(double dt) {
    current?.update(dt);
  }

  void render(Canvas canvas, {Size? canvasSize}) {
    final scene = current;
    if (scene == null || canvasSize == null) return;

    // Atualiza métricas da viewport
    _viewport.update(screenSize: canvasSize, safeArea: _safeAreaInsets);

    scene.render(canvas, canvasSize: canvasSize, viewport: _viewport);

    // Debug overlays de viewport (letterbox/safe area)
    _viewport.debugRender(canvas);
  }
}
