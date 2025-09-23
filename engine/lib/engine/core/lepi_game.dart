import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/input_handler.dart';
import 'game_loop.dart';
import 'scene.dart';
import 'scene_manager.dart';
import 'viewport.dart';

/// Entrypoint do jogo.
/// Junta GameLoop + SceneManager + Scenes iniciais.
class LepiGame extends StatefulWidget {
  final List<Scene> scenes;
  final String initialScene;
  final ViewportConfig viewportConfig;
  final SafeAreaInsets? safeAreaInsets;

  const LepiGame({
    super.key,
    required this.scenes,
    required this.initialScene,
    this.viewportConfig = const ViewportConfig(
      referenceWidth: 1920,
      referenceHeight: 1080,
    ),
    this.safeAreaInsets,
  });

  @override
  State<LepiGame> createState() => _LepiGameState();
}

class _LepiGameState extends State<LepiGame> {
  @override
  void initState() {
    super.initState();
    _initScenes();
    // Configura viewport
    SceneManager.instance.configureViewport(widget.viewportConfig);
  }

  @override
  Widget build(BuildContext context) {
    // Configura cenas iniciais

    // Atualiza safe area a cada build (pode variar com rotação, etc.)
    final media = MediaQuery.maybeOf(context);
    if (media != null) {
      final padding = media.padding;
      SceneManager.instance.setSafeAreaInsets(
        SafeAreaInsets(
          left: padding.left,
          top: padding.top,
          right: padding.right,
          bottom: padding.bottom,
        ),
      );
    } else if (widget.safeAreaInsets != null) {
      SceneManager.instance.setSafeAreaInsets(widget.safeAreaInsets!);
    }

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
