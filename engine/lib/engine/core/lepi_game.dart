import 'package:flutter/material.dart';
import 'game_loop.dart';
import 'scene.dart';
import 'scene_manager.dart';

/// Entrypoint do jogo.
/// Junta GameLoop + SceneManager + Scenes iniciais.
class LepiGame extends StatelessWidget {
  final List<Scene> scenes;
  final String initialScene;

  const LepiGame({super.key, required this.scenes, required this.initialScene});

  @override
  Widget build(BuildContext context) {
    // Configura cenas iniciais
    _initScenes();

    return GameLoop(
      onUpdate: (dt) {
        SceneManager.instance.update(dt);
      },
      onRender: (canvas, size) {
        SceneManager.instance.render(canvas, canvasSize: size);
      },
    );
  }

  void _initScenes() {
    // limpa todas as cenas
    SceneManager.instance.clearAllScenes();

    // adiciona todas as cenas
    for (final s in scenes) {
      SceneManager.instance.addScene(s);
    }

    // define a cena inicial
    SceneManager.instance.setScene(initialScene);
  }
}
