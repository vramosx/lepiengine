## LepiEngine Playground

### Overview
The LepiEngine Playground is a small Flutter application that showcases and tests features of the LepiEngine.

### Requirements
- Flutter SDK installed and configured
- Dart SDK (bundled with Flutter)
- For now, this monorepo checked out (the playground depends on the local `engine` package)

### Getting Started
1. Navigate to the playground folder:
```bash
cd playground
```
2. Fetch dependencies:
```bash
flutter pub get
```
3. Run on your preferred platform (examples):
```bash
# macOS desktop
flutter run -d macos

# Windows desktop (not tested)
flutter run -d windows

# Linux desktop (not tested)
flutter run -d linux

# Web 
flutter run -d chrome

# iOS / Android (not tested)
flutter run
```

### Available demos
- **PlatformGame**: A minimal platformer demonstrating tiles, collisions, entities, and camera/viewport.
- **AnimationShowcase**: A gallery of character animations to validate timing, easing, and sprite sequencing.
- (Experimental) **TilemapEditor**: A simple in-app editor for tilemaps. It is present in the codebase but commented out in the default UI. - not working properly

### Switching scenes
The playground boots with `PlatformGame` by default. To switch the initial scene, open `playground/lib/main.dart` and change the value of `selectedScene` to one of the available scene names:
- `PlatformGame`
- `AnimationShowcase`
- `TilemapEditor` (requires enabling the commented UI code in `main.dart`)

### Assets
Assets used by the playground are declared in `pubspec.yaml` under the `flutter/assets` section:
- `assets/images/background/`
- `assets/images/character/`
- `assets/images/objects/`
- `assets/images/tileset/`
- `assets/images/lepi/`
- `assets/music/`
- `assets/sounds/`
- `assets/data/`

If you add new assets, remember to update `pubspec.yaml` and run `flutter pub get`.

### Project structure (high level)
- `lib/examples/platform_game/`: Platform game demo code
- `lib/examples/animation_showcase/`: Animation showcase demo
- `lib/tilemap_editor/`: Basic tilemap editor screens and models
- `assets/`: Images, sounds, music, and data files used by the demos

### License
This playground is part of the LepiDreams/LepiEngine repository and follows the repository's license. See the root `LICENSE.md` for details.
