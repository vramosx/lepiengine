import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/viewport.dart';
import 'package:lepiengine/main.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_game.dart';
import 'package:lepiengine_playground/examples/ships_battle/ships_battle.dart';
import 'package:lepiengine_playground/examples/animation_showcase/animation_showcase.dart';

void main() {
  runApp(const MyGame());
}

class MyGame extends StatefulWidget {
  const MyGame({super.key});

  @override
  State<MyGame> createState() => _MyGameState();
}

class _MyGameState extends State<MyGame> {
  final sceneGameConfig = {
    "ShipsBattle": {"width": 1024.0, "height": 768.0},
    "PlatformGame": {"width": 640.0, "height": 480.0},
  };

  String selectedScene = 'PlatformGame';
  final platformGame = PlatformGame();
  final animationShowcase = AnimationShowcase();
  final shipsBattle = ShipsBattle();

  // final scenes = ['LepiStart'];

  DemoFeature _current = DemoFeature.moveTo;

  void _setFeature(DemoFeature f) {
    setState(() => _current = f);
    final scene = SceneManager.instance.current;
    if (scene is AnimationShowcase) {
      scene.setFeature(f);
    }
  }

  void _restart() {
    final scene = SceneManager.instance.current;
    if (scene is AnimationShowcase) {
      scene.restartFeature();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'LepiEngine Playground',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.only(right: 36),
          backgroundColor: Colors.black,
        ),
        // body: LepiGame(
        //   scenes: [animationShowcase, platformGame],
        //   initialScene: selectedScene,
        //   viewportConfig: const ViewportConfig(
        //     referenceWidth: 1024,
        //     referenceHeight: 768,
        //   ),
        // ),
        body: Stack(
          children: [
            LepiGame(
              scenes: [animationShowcase, platformGame, shipsBattle],
              initialScene: selectedScene,
              viewportConfig: ViewportConfig(
                referenceWidth: sceneGameConfig[selectedScene]!["width"]!,
                referenceHeight: sceneGameConfig[selectedScene]!["height"]!,
                mode: ScalingMode.fitHeight,
              ),
            ),
            if (selectedScene == 'AnimationShowcase') ...[
              // Top bar: botões de funcionalidades e título central
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Título central com nome da funcionalidade
                    Text(
                      kDemoNames[_current]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Lista horizontal de botões
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        runSpacing: 8,
                        children: DemoFeature.values.map((f) {
                          final selected = f == _current;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(kDemoNames[f]!),
                              selected: selected,
                              onSelected: (_) => _setFeature(f),
                              selectedColor: Colors.blueAccent,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.white,
                              ),
                              backgroundColor: Colors.black54,
                              side: const BorderSide(color: Colors.white24),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Botão central inferior: Reiniciar
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reiniciar animação'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
