import 'dart:ui';

import 'package:lepiengine/engine/core/asset_loader.dart';
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
}
