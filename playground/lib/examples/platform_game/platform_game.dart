import 'dart:ui';
import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/core/audio_manager.dart';
import 'package:lepiengine/engine/core/scene.dart';
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';
import 'package:lepiengine_playground/examples/platform_game/jumper.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_map.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_player.dart';
import 'package:lepiengine_playground/examples/platform_game/static_objects.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';

class PlatformGame extends Scene {
  PlatformGame({super.name = 'PlatformGame'}) : super(debugCollisions: false);

  @override
  void onEnter() {
    super.onEnter();
    AudioManager.instance.stopAllMusic();

    // AudioManager.instance.playMusic(Constants.backgroundMusic);
  }

  @override
  Future<void> loadScene() async {
    super.loadScene();

    final platformMap = PlatformMap();
    add(platformMap, layer: 'map');
    setLayerOrder("map", 0);

    await _loadPointerIdle();

    await _loadJumper();

    await _loadPlayer();

    await _loadGems();

    setLayerOrder("static_objects", 1);

    setLayerOrder("entities", 2);
  }

  Future<void> _loadGems() async {
    final gemsPositions = [
      const Offset(600, 100),
      const Offset(650, 200),
      const Offset(700, 200),
      const Offset(750, 200),
      const Offset(400, 70),
      const Offset(410, 80),
    ];

    for (var position in gemsPositions) {
      final gem = await playerGemBuilder();
      gem.position = position;
      add(gem);
    }
  }

  Future<void> _loadJumper() async {
    final jumperSprite = await AssetLoader.loadImage(Constants.jumper);
    final jumper = Jumper(image: jumperSprite);
    jumper.position = const Offset(400, 216);
    add(jumper);
  }

  Future<void> _loadPointerIdle() async {
    final pointerIdle = await pointerIdleBuilder;
    pointerIdle.position = const Offset(280, 192);
    add(pointerIdle, layer: 'static_objects');
  }

  Future<void> _loadPlayer() async {
    final playerSprite = await AssetLoader.loadImage(Constants.character);

    final player = PlatformPlayer(image: playerSprite);
    player.size = const Size(24, 24);
    player.position = const Offset(320, 180);

    late SpriteSheet playerStart;
    playerStart = await playerStartBuilder(() {
      add(player, layer: 'entities');
      player.play('idle');
      camera.follow(player);
      remove(playerStart);
    });

    add(playerStart, layer: 'entities');
    playerStart.position = const Offset(320, 180);
    camera.follow(playerStart);
  }
}
