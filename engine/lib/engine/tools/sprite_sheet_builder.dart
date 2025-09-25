import 'dart:ui';

import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';

class SpriteSheetBuilder {
  static Future<SpriteSheet> build({
    required String name,
    required String imagePath,
    required Size size,
    required List<SpriteAnimation> animations,
    required String initialAnimation,
  }) async {
    final image = await AssetLoader.loadImage(imagePath);

    final spriteSheet = SpriteSheet(name: name, size: size, image: image);

    for (var animation in animations) {
      spriteSheet.addAnimation(animation);
    }

    spriteSheet.play(initialAnimation);

    return spriteSheet;
  }

  static Future<SpriteSheetWithCollider> buildWithCollider({
    required String name,
    required String imagePath,
    required Size size,
    required List<SpriteAnimation> animations,
    required String initialAnimation,
    ColliderAnchor anchor = ColliderAnchor.center,
    bool isTrigger = false,
    bool isStatic = false,
    Color debugColor = const Color(0xFF00FF00),
  }) async {
    final image = await AssetLoader.loadImage(imagePath);
    final spriteSheet = SpriteSheetWithCollider(
      name: name,
      image: image,
      size: size,
    );
    spriteSheet.addAABBCollider(
      size: size,
      anchor: anchor,
      isTrigger: isTrigger,
      isStatic: isStatic,
      debugColor: debugColor,
    );
    for (var animation in animations) {
      spriteSheet.addAnimation(animation);
    }
    spriteSheet.play(initialAnimation);
    return spriteSheet;
  }
}
