import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/input_handler.dart';
import 'game_loop.dart';
import 'scene.dart';
import 'scene_manager.dart';

/// Entrypoint do jogo.
/// Junta GameLoop + SceneManager + Scenes iniciais.
class LepiGame extends StatefulWidget {
  final List<Scene> scenes;
  final String initialScene;

  const LepiGame({super.key, required this.scenes, required this.initialScene});

  @override
  State<LepiGame> createState() => _LepiGameState();
}

class _LepiGameState extends State<LepiGame> {
  @override
  void initState() {
    super.initState();
    _initScenes();
  }

  @override
  Widget build(BuildContext context) {
    // Configura cenas iniciais

    return InputHandler(
      child: Stack(
        children: [
          GameLoop(
            onUpdate: (dt) {
              SceneManager.instance.update(dt);
            },
            onRender: (canvas, size) {
              SceneManager.instance.render(canvas, canvasSize: size);
            },
          ),
        ],
      ),
    );
  }

  void _initScenes() {
    // limpa todas as cenas
    SceneManager.instance.clearAllScenes();

    // adiciona todas as cenas
    for (final s in widget.scenes) {
      SceneManager.instance.addScene(s);
    }

    // define a cena inicial
    SceneManager.instance.setScene(widget.initialScene);
  }
}
