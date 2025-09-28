import 'dart:ui';

import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/game_objects/sprite.dart';

class SpriteBuilder {
  static Future<Sprite> build({
    required String name,
    required String imagePath,
    required Size size,
  }) async {
    final image = await AssetLoader.loadImage(imagePath);

    final sprite = Sprite(name: name, size: size, image: image);

    return sprite;
  }
}
