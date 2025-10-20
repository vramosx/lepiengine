import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:lepiengine/engine/core/audio_manager.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/main.dart';
import 'package:lepiengine_playground/examples/platform_game/jumper.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_map.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_player.dart';
import 'package:lepiengine_playground/examples/platform_game/static_objects.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';

Offset playerStartPosition = const Offset(320, 180);

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

    await _loadGems(platformMap);

    await _loadObstacle();

    final gameLimit = GameLimit();
    add(gameLimit);

    await _loadWinCheckpoint();

    setLayerOrder("static_objects", 1);
    setLayerOrder("entities", 2);
  }

  Future<void> _loadGems(PlatformMap platformMap) async {
    final gemsPositions = [
      const Offset(600, 100),
      const Offset(650, 200),
      const Offset(700, 200),
      const Offset(750, 200),
      const Offset(400, 70),
      const Offset(410, 80),
      const Offset(1300, 200),
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
    player.position = playerStartPosition;

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

  Future<void> _loadObstacle() async {
    final obstacleSprite = await AssetLoader.loadImage(Constants.obstacle);
    final obstacle = Obstacle(image: obstacleSprite);
    obstacle.position = const Offset(490, 220);
    add(obstacle);
  }

  Future<void> _loadWinCheckpoint() async {
    late final SpriteSheetWithCollider winCheckpoint;

    winCheckpoint = await SpriteSheetBuilder.buildWithCollider(
      name: "winCheckpoint",
      imagePath: "objects/Checkpoint.png",
      size: Size(24, 24),
      isTrigger: true,
      animations: [
        SpriteAnimation(
          name: "idle",
          frameSize: Size(48, 48),
          frames: [Frame(col: 0, row: 0)],
        ),
        SpriteAnimation(
          name: "win",
          frameSize: Size(48, 48),
          frames: [
            Frame(col: 0, row: 0),
            Frame(col: 1, row: 0),
            Frame(col: 2, row: 0),
            Frame(col: 3, row: 0),
            Frame(col: 4, row: 0),
            Frame(col: 5, row: 0),
            Frame(col: 6, row: 0),
          ],
          loop: false,
          onEnd: () {
            winCheckpoint.play("winAnimation");
          },
        ),
        SpriteAnimation(
          name: "winAnimation",
          frameSize: Size(48, 48),
          frames: [
            Frame(col: 6, row: 0),
            Frame(col: 5, row: 0),
            Frame(col: 4, row: 0),
            Frame(col: 5, row: 0),
            Frame(col: 6, row: 0),
          ],
          loop: true,
        ),
      ],
      initialAnimation: 'idle',
    );

    winCheckpoint.position = Offset(1232, 200);

    add(winCheckpoint);
  }
}

class Obstacle extends SpriteSheet with CollisionCallbacks {
  Obstacle({
    super.name = 'Obstacle',
    required super.image,
    super.size = const Size(32, 32),
  }) : super() {
    addCircleCollider(radius: 10);

    addAnimation(
      SpriteAnimation(
        name: "running",
        frameSize: Size(48, 48),
        frames: [
          Frame(col: 0, row: 0),
          Frame(col: 0, row: 0),
          Frame(col: 0, row: 0),
          Frame(col: 0, row: 0),
          Frame(col: 0, row: 0),
          Frame(col: 0, row: 0),
          Frame(col: 1, row: 0),
          Frame(col: 2, row: 0),
          Frame(col: 3, row: 0),
          Frame(col: 4, row: 0),
          Frame(col: 5, row: 0),
          Frame(col: 3, row: 0),
          Frame(col: 4, row: 0),
          Frame(col: 5, row: 0),
          Frame(col: 3, row: 0),
          Frame(col: 4, row: 0),
          Frame(col: 5, row: 0),
          Frame(col: 6, row: 0),
        ],
      ),
    );

    play("running");
  }

  @override
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    super.onCollisionEnter(other, collision);
    if (other is PlatformPlayer) {
      Animations.blink(
        other,
        Colors.red,
        30,
        0.2,
        onComplete: () {
          other.tintColor = null;
        },
      );

      other.applyKnockback(
        sourcePosition: worldPivot,
        horizontalForce: 250.0,
        verticalImpulse: -200.0,
        duration: 0.25,
      );
    }
  }
}

class GameLimit extends GameObject with CollisionCallbacks {
  GameLimit({
    super.position = const Offset(480, 432),
    super.size = const Size(520, 10),
  }) : super() {
    addAABBCollider(
      size: Size(520, 10),
      isTrigger: true,
      debugColor: Colors.blue,
    );
  }

  @override
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    super.onCollisionEnter(other, collision);
    if (other is PlatformPlayer) {
      other.position = playerStartPosition;
    }
  }
}
