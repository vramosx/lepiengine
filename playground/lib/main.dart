import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/viewport.dart';
import 'package:lepiengine/main.dart';
import 'package:lepiengine_playground/examples/platform_game.dart';
import 'package:lepiengine_playground/tilemap_editor/tilemap_editor_screen.dart';

void main() {
  runApp(const MyGame());
}

class MyGame extends StatefulWidget {
  const MyGame({super.key});

  @override
  State<MyGame> createState() => _MyGameState();
}

class _MyGameState extends State<MyGame> {
  String selectedScene = 'PlatformGame';
  final platformGame = PlatformGame();

  final scenes = ['PlatformGame', 'TilemapEditor'];

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
          actions: [
            // DropdownButton(
            //   value: selectedScene,
            //   dropdownColor: Colors.black,
            //   icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            //   style: const TextStyle(color: Colors.white),
            //   items: scenes
            //       .map(
            //         (scene) =>
            //             DropdownMenuItem(value: scene, child: Text(scene)),
            //       )
            //       .toList(),
            //   onChanged: (value) {
            //     setState(() {
            //       selectedScene = value ?? '';
            //     });
            //   },
            // ),
          ],
        ),
        body: selectedScene == 'TilemapEditor'
            ? const TilemapEditorScreen()
            : LepiGame(
                scenes: [platformGame],
                initialScene: 'PlatformGame',
                viewportConfig: ViewportConfig(
                  referenceWidth: 800,
                  referenceHeight: 600,
                  mode: ScalingMode.fitWidth,
                ),
              ),
      ),
    );
  }
}
