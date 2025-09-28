### 2. Getting Started

Welcome! This guide helps you install LepiEngine and run your first scene in minutes.

#### Installation
Add LepiEngine to your `pubspec.yaml`. If you’re using it locally (like this repo’s structure), use a path dependency; otherwise, use a hosted version when available.

```yaml
dependencies:
  flutter:
    sdk: flutter
  lepiengine:
    path: ../engine   # or a hosted version on pub.dev when published
```

Recommended project folders for clarity:

```
your_game/
  assets/            # images, sounds, tilemaps, data
  engine/            # the engine package (if local, optional)
  lib/
    game/            # your actual game code (scenes, objects)
    main.dart        # app entry point
  pubspec.yaml
```

Tip: In `pubspec.yaml`, ensure your assets are declared so Flutter bundles them.

```yaml
flutter:
  assets:
    - assets/images/
    - assets/sounds/
    - assets/data/
```

#### First Game Setup
Let’s create a minimal `main.dart` that runs at ~60 FPS with a single scene and one object.

1) Create `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/lepi_game.dart';
import 'package:lepiengine/engine/core/scene.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/core/viewport.dart';

void main() {
  runApp(const MyGame());
}

class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    // 1) Define a simple scene with a black background
    final scene = Scene(
      name: 'FirstScene',
      clearColor: const Color(0xFF000000),
    );

    // 2) Add a single object: a green square at the center
    scene.add(
      _GreenBox(
        name: 'Box',
        position: const Offset(512, 384), // center for 1024x768 reference
        size: const Size(80, 80),
        anchor: const Offset(0.5, 0.5),  // center anchor
      ),
    );

    // 3) Create the game widget and run
    return MaterialApp(
      home: Scaffold(
        body: LepiGame(
          scenes: [scene],
          initialScene: 'FirstScene',
          viewportConfig: const ViewportConfig(
            referenceWidth: 1024,
            referenceHeight: 768,
            // mode: ScalingMode.fitHeight, // optional
          ),
        ),
      ),
    );
  }
}

// Minimal GameObject that draws a colored rectangle
class _GreenBox extends GameObject {
  _GreenBox({
    super.name,
    super.position,
    super.size,
    super.anchor,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF00FF66);
    canvas.drawRect(Offset.zero & size, paint);
  }
}
```

Run it:

```bash
flutter run
```

You should see a black screen with a green square in the center.

#### Core Concepts (Quick Overview)
- **LepiGame**: The Flutter widget that hosts the game. It wires together the game loop, scenes, input, and viewport.
- **Scene**: A self-contained space for your game objects. Scenes have layers, a camera, and can paint a clear color each frame.
- **GameLoop**: The engine’s heartbeat—updates logic and renders frames (aims ~60 FPS). You usually don’t call it directly; `LepiGame` handles this.

Think of it like this:

```
[ LepiGame ]
   ├─ manages → [ Scenes ]
   │               └─ contains → [ GameObjects ]
   └─ drives   → [ GameLoop (update + render) ]
```

#### Best Practices from the Start
- **Separate engine/core from gameplay**: Keep your reusable engine or framework code isolated from your game-specific logic.
- **Organize by responsibility**: Group scenes, objects, and systems logically.

Example structure:

```
lib/
  engine_core/        # optional wrappers/util you create around the engine
    input/
    rendering/
  gameplay/
    scenes/
      first_scene.dart
    objects/
      green_box.dart
  main.dart
```

This keeps the engine stable and your gameplay code clean and easy to iterate.

#### Verification
You’re set if one of the following is true:
- You see a black screen updating smoothly at ~60 FPS.
- You see a green square centered on the screen.

If nothing appears:
- Confirm `initialScene` matches your scene’s `name`.
- Check you’re importing the correct engine paths.
- Ensure `referenceWidth/Height` and object positions make sense.
- Check the debug console for errors.

You’re ready to continue—next, we’ll add sprites, input, and collisions.



