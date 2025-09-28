### 1. Introduction

#### What is LepiEngine?
LepiEngine is a simple, lightweight 2D game engine built with Flutter and pure Dart. It focuses on clarity, performance, and ease of use, so you can start building games quickly without heavy setup.

- **Simplicity**: Clean APIs, minimal boilerplate, and straightforward concepts.
- **Performance**: Efficient loop, layered scenes, basic culling, and camera transforms targeting ~60 FPS on typical devices.
- **Ease of use**: Works the Flutter way—compose with widgets, hot reload your game loop, and iterate fast.

#### Philosophy
We built LepiEngine because most options sit at two extremes:

- **Heavyweights (Unity/Unreal)**: Powerful but complex, slow iteration for small 2D projects, and often overkill for indie scopes.
- **Lightweight toolkits**: Fast and minimal, but you end up stitching missing parts or reinventing basics.

LepiEngine aims for the sweet spot: the essentials you actually need (game loop, scenes, camera, input, collisions, sprites, viewport scaling) with a fluid development experience. The goal is to make the act of creating enjoyable—short feedback loops, easy-to-read code, and an engine that stays out of your way.

#### Why Flutter + Dart
Flutter and Dart offer a uniquely productive stack for 2D games:

- **Cross‑platform**: Build once, run on mobile (iOS/Android), desktop (macOS/Windows/Linux), and web.
- **Hot reload**: Tweak gameplay, assets, and scenes with near‑instant feedback.
- **Developer productivity**: Strong tooling, a reactive UI layer, and a modern language—great for rapid iteration.

#### Who is this for?
Indie developers, hobbyists, students, or anyone who wants a lightweight and fast way to build polished 2D games without wrestling with a massive engine. If you value iteration speed and clean architecture over endless configuration, you’ll feel at home.

#### Hello World
The smallest possible setup: a black screen rendering at ~60 FPS using a single empty scene.

```dart
import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/lepi_game.dart';
import 'package:lepiengine/engine/core/scene.dart';
import 'package:lepiengine/engine/core/viewport.dart';

void main() {
  runApp(const MyGame());
}

class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: LepiGame(
          scenes: [
            Scene(
              name: 'HelloWorld',
              // Clear color paints the background each frame (black here)
              clearColor: const Color(0xFF000000),
            ),
          ],
          initialScene: 'HelloWorld',
          viewportConfig: const ViewportConfig(
            referenceWidth: 1024,
            referenceHeight: 768,
          ),
        ),
      ),
    );
  }
}
```

That’s it—you’re running the engine. From here, add sprites, input, collisions, and multiple layers as you grow the scene.


