import 'dart:ui';

import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/core/scene.dart';
import 'package:lepiengine/engine/game_objects/tilemap.dart';
import 'package:lepiengine/engine/models/tileset.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';

class PlatformGame extends Scene {
  PlatformGame({super.name = 'PlatformGame'});

  @override
  void onEnter() {
    super.onEnter();
    final platformMap = PlatformMap();
    add(platformMap);
  }
}

class PlatformMap extends GameObject {
  PlatformMap({
    super.name = 'PlatformMap',
    super.position = const Offset(0, 0),
  });

  @override
  void onAdd() {
    super.onAdd();
    _loadScene();
  }

  Future<void> _loadScene() async {
    final backgroundImage = await AssetLoader.loadImage(Constants.background);
    final backgroundTileset = Tileset(
      image: backgroundImage,
      tileWidth: 64,
      tileHeight: 64,
    );
    final tilesetImage = await AssetLoader.loadImage(Constants.tileset);
    final tileset = Tileset(image: tilesetImage, tileWidth: 16, tileHeight: 16);

    // generate background map
    final backgroundMap = List.generate(
      50,
      (index) => List.generate(50, (index) => 0),
    );

    final map = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],
      [22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32],
      [33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43],
      [44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54],
      [55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65],
      [66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76],
      [77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87],
      [88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98],
      [99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109],
      [110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120],
      [121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131],
      [132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142],
      [143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153],
      [154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164],
      [165, 166, 167, 168, 169, 170, 171, 172, 173, 174],
    ];

    final backgroundTilemap = Tilemap(
      tileset: backgroundTileset,
      map: backgroundMap,
      position: const Offset(0, 0),
    );

    final tilemap = Tilemap(
      tileset: tileset,
      map: map,
      position: const Offset(0, 0),
      debugCollisions: true,
      solidTiles: {174},
    );
    addChild(backgroundTilemap);
    addChild(tilemap);
  }

  @override
  void render(Canvas canvas) {
    // TODO: implement render
  }
}
