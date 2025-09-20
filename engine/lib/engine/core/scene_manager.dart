import 'dart:ui';
import 'scene.dart';

class SceneManager {
  SceneManager._();

  static final SceneManager instance = SceneManager._();

  final List<Scene> _scenes = [];

  Scene? _currentScene;

  Scene? get current => _currentScene;

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
    scene.onEnter();
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
    current?.render(canvas, canvasSize: canvasSize);
  }
}
