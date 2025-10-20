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

/// Layer name constants to avoid string duplication and typos.
const String _layerMap = 'map';
const String _layerStatic = 'static_objects';
const String _layerEntities = 'entities';

/// Common world positions used across the scene.
const Offset playerStartPosition = Offset(320, 180);
const Offset _pointerIdlePosition = Offset(280, 208);
const Offset _jumperPosition = Offset(400, 216);
const Offset _obstaclePosition = Offset(490, 220);
const Offset _winCheckpointPosition = Offset(1232, 200);

/// Predefined gem spawn points to keep scene setup declarative.
const List<Offset> _gemPositions = <Offset>[
  Offset(600, 100),
  Offset(650, 200),
  Offset(700, 200),
  Offset(750, 200),
  Offset(400, 70),
  Offset(410, 80),
  Offset(1300, 200),
];

/// Main platformer example scene demonstrating player, collectibles, hazards,
/// and a simple checkpoint win animation.
class PlatformGame extends Scene {
  PlatformGame({super.name = 'PlatformGame'}) : super(debugCollisions: false);

  @override
  void onEnter() {
    super.onEnter();
    // Ensure no background music remains from previous scenes.
    AudioManager.instance.stopAllMusic();
  }

  @override
  Future<void> loadScene() async {
    super.loadScene();

    final platformMap = PlatformMap();
    add(platformMap, layer: _layerMap);
    setLayerOrder(_layerMap, 0);

    await _loadPointerIdle();

    await _loadJumper();

    await _loadPlayer();

    await _loadGems(platformMap);

    await _loadObstacle();

    final gameLimit = GameLimit();
    add(gameLimit);

    await _loadWinCheckpoint();

    setLayerOrder(_layerStatic, 1);
    setLayerOrder(_layerEntities, 2);
  }

  /// Spawns all collectible gems at predefined positions.
  Future<void> _loadGems(PlatformMap platformMap) async {
    for (final position in _gemPositions) {
      final gem = await playerGemBuilder();
      gem.position = position;
      add(gem);
    }
  }

  /// Places a spring-like jumper that boosts the player on contact.
  Future<void> _loadJumper() async {
    final jumperSprite = await AssetLoader.loadImage(Constants.jumper);
    final jumper = Jumper(image: jumperSprite);
    jumper.position = _jumperPosition;
    add(jumper);
  }

  /// Adds a small pointer as a visual cue for the player start area.
  Future<void> _loadPointerIdle() async {
    final pointerIdle = await buildPointerIdle();
    pointerIdle.position = _pointerIdlePosition;
    add(pointerIdle, layer: _layerStatic);
  }

  /// Loads player, shows a short appearing animation, then hands camera control
  /// to the player character.
  Future<void> _loadPlayer() async {
    final playerSprite = await AssetLoader.loadImage(Constants.character);

    final player = PlatformPlayer(image: playerSprite);
    player.size = const Size(24, 24);
    player.position = playerStartPosition;

    // Use late final to allow referencing playerStart within the onEnd callback.
    late final SpriteSheet playerStart;
    playerStart = await playerStartBuilder(() {
      add(player, layer: _layerEntities);
      player.play('idle');
      camera.follow(player);
      remove(playerStart);
    });

    add(playerStart, layer: _layerEntities);
    playerStart.position = playerStartPosition;
    camera.follow(playerStart);
  }

  /// Spawns a moving obstacle that knocks the player back on collision.
  Future<void> _loadObstacle() async {
    final obstacleSprite = await AssetLoader.loadImage(Constants.obstacle);
    final obstacle = Obstacle(image: obstacleSprite);
    obstacle.position = _obstaclePosition;
    add(obstacle);
  }

  /// Creates the win checkpoint. When the player collides with it, the sprite
  /// plays a short non-looping 'win' sequence and then switches to a looping
  /// 'winAnimation' idle.
  Future<void> _loadWinCheckpoint() async {
    late final SpriteSheetWithCollider winCheckpoint;

    winCheckpoint = await SpriteSheetBuilder.buildWithCollider(
      name: 'winCheckpoint',
      imagePath: 'objects/Checkpoint.png',
      size: const Size(24, 24),
      isTrigger: true,
      animations: [
        SpriteAnimation(
          name: 'idle',
          frameSize: const Size(48, 48),
          frames: [Frame(col: 0, row: 0)],
        ),
        SpriteAnimation(
          name: 'win',
          frameSize: const Size(48, 48),
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
            winCheckpoint.play('winAnimation');
          },
        ),
        SpriteAnimation(
          name: 'winAnimation',
          frameSize: const Size(48, 48),
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

    winCheckpoint.position = _winCheckpointPosition;

    add(winCheckpoint);
  }
}

/// Simple obstacle with a circular collider that applies knockback to the
/// player and triggers a brief tint effect.
class Obstacle extends SpriteSheet with CollisionCallbacks {
  Obstacle({
    super.name = 'Obstacle',
    required super.image,
    super.size = const Size(32, 32),
  }) : super() {
    addCircleCollider(radius: 10);

    addAnimation(
      SpriteAnimation(
        name: 'running',
        frameSize: const Size(48, 48),
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

    play('running');
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

/// Horizontal world limit. When the player falls out of bounds, reset
/// their position to the start point.
class GameLimit extends GameObject with CollisionCallbacks {
  GameLimit({
    super.position = const Offset(480, 432),
    super.size = const Size(520, 10),
  }) : super() {
    addAABBCollider(
      size: const Size(520, 10),
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
