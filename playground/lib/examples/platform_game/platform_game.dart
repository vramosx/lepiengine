import 'dart:ui';

import 'package:flutter/material.dart' show Colors, debugPrint;
import 'package:lepiengine/engine/animation/animations.dart';
import 'package:lepiengine/engine/animation/easing.dart';
import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/core/audio_manager.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/engine/core/collision_manager.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/core/input_manager.dart';
import 'package:lepiengine/engine/core/scene.dart';
import 'package:lepiengine/engine/core/scene_manager.dart';
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';
import 'package:lepiengine/engine/game_objects/tilemap.dart';
import 'package:lepiengine/engine/models/tileset.dart';
import 'package:lepiengine_playground/examples/platform_game/static_objects.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';
import 'package:lepiengine_playground/examples/utils/json_utils.dart';

class PlatformGame extends Scene {
  PlatformGame({super.name = 'PlatformGame'}) : super(debugCollisions: true);

  @override
  void onEnter() {
    super.onEnter();
    AudioManager.instance.stopAllMusic();

    AudioManager.instance.playMusic(Constants.backgroundMusic);
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
      const Offset(600, 200),
      const Offset(650, 200),
      const Offset(700, 200),
      const Offset(750, 200),
      const Offset(200, 200),
      const Offset(210, 210),
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
    jumper.position = const Offset(350, 465);
    add(jumper);

    final jumper2 = Jumper(image: jumperSprite);
    jumper2.position = const Offset(1050, 305);
    add(jumper2);
  }

  Future<void> _loadPointerIdle() async {
    final pointerIdle = await pointerIdleBuilder;
    pointerIdle.position = const Offset(100, 450);
    add(pointerIdle, layer: 'static_objects');
  }

  Future<void> _loadPlayer() async {
    final playerSprite = await AssetLoader.loadImage(Constants.character);

    final player = Player(image: playerSprite);
    player.size = const Size(48, 48);
    player.position = const Offset(250, 400);

    late SpriteSheet playerStart;
    playerStart = await playerStartBuilder(() {
      add(player, layer: 'entities');
      player.play('idle');
      camera.follow(player);
      remove(playerStart);
    });

    add(playerStart, layer: 'entities');
    playerStart.position = const Offset(225, 400);
    camera.follow(playerStart);
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
    await _loadTilemap();
  }

  Future<void> _loadTilemap() async {
    final platformTilemap = await readJson(Constants.platformTilemap);
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

    final backgroundTilemap = Tilemap(
      tileset: backgroundTileset,
      map: backgroundMap,
      position: const Offset(0, 0),
    );

    final rawTiles = platformTilemap['tiles'] as List<dynamic>;

    final map = rawTiles
        .map<List<int>>(
          (row) => (row as List<dynamic>).map<int>((e) => e as int).toList(),
        )
        .toList();

    final solidRawTiles = platformTilemap['collisions'] as List<dynamic>;
    Set<int> solidTiles = Set.from(solidRawTiles.map<int>((e) => e as int));

    final tilemap = Tilemap(tileset: tileset, map: map, solidTiles: solidTiles);
    addChild(backgroundTilemap);
    addChild(tilemap);
  }

  @override
  void render(Canvas canvas) {}
}

class Player extends SpriteSheet with PhysicsBody, CollisionCallbacks {
  Player({super.name = 'Player', required super.image}) : super() {
    addAABBCollider(
      size: Size(30, 42),
      anchor: ColliderAnchor.bottomCenter,
      debugColor: Colors.blue,
    );

    gravity = 800;
    maxFallSpeed = 800;
  }

  bool isGrounded = false;
  final double moveSpeed = 150.0;
  final double jumpForce = -350.0;
  bool isFlipped = false;
  var smokeCount = 0;

  void flip() {
    isFlipped = !isFlipped;
    flipX = !flipX;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _handleInput();
  }

  Future<void> createSmoke(Offset position) async {
    late SpriteSheet smoke;
    smoke = await playerMovementSmokeBuilder(() {
      smokeCount--;
      SceneManager.instance.current?.remove(smoke);
    });
    smoke.position = Offset(position.dx + 32, position.dy + 36);
    SceneManager.instance.current?.add(smoke, layer: 'static_objects');
    smokeCount++;
  }

  void _handleInput() {
    // Pulo (lógica específica de plataforma)// Pulo (lógica específica de plataforma)
    final jumpPressed =
        InputManager.instance.isPressed('KeyW') ||
        InputManager.instance.isPressed('Arrow Up') ||
        InputManager.instance.isPressed('Space');

    if (jumpPressed) {
      if (isGrounded) {
        AudioManager.instance.playSound('jump.mp3');
        play('jump');
        setVelocity(Offset(velocity.dx, jumpForce));
        isGrounded = false;
        return;
      } else {}
    }

    // Movimento horizontal
    double horizontal = 0.0;
    if (InputManager.instance.isPressed('KeyA') ||
        InputManager.instance.isPressed('Arrow Left')) {
      if (smokeCount < 1 && isGrounded) {
        createSmoke(Offset(position.dx - 10, position.dy));
      }

      horizontal = -1.0;
      play('run');
      if (!isFlipped) {
        flip();
      }
    }
    if (InputManager.instance.isPressed('KeyD') ||
        InputManager.instance.isPressed('Arrow Right')) {
      if (smokeCount < 1 && isGrounded) {
        createSmoke(Offset(position.dx - 10, position.dy));
      }

      horizontal = 1.0;
      play('run');
      if (isFlipped) {
        flip();
      }
    }

    // Movimento normal
    setVelocity(Offset(horizontal * moveSpeed, velocity.dy));

    if (isGrounded && horizontal == 0) {
      play('idle');
    }
  }

  @override
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    debugPrint(
      'Collision enter: ${other.runtimeType} - Normal: ${collision.normal}',
    );

    // Removido: não marca grounded só por colidir com Tilemap; usa lado.

    if (collision.selfSide == CollisionSide.bottom) {
    } else if (collision.selfSide == CollisionSide.top) {
      debugPrint("collision top: ${collision.selfSide}");
    } else if (collision.selfSide == CollisionSide.left) {
      debugPrint("collision left: ${collision.selfSide}");
    } else if (collision.selfSide == CollisionSide.right) {
      debugPrint("collision right: ${collision.selfSide}");
    }

    if (collision.selfSide == CollisionSide.bottom) {
      if (other is Jumper) {
        SceneManager.instance.current?.camera.lightShake();
        setVelocity(Offset(velocity.dx, jumpForce * 2));
        isGrounded = false;
      }
    }

    if (collision.selfSide == CollisionSide.left &&
        currentAnimation?.name != 'wallJump') {
      if (!isFlipped) {
        flip();
      }
      play('wallJump');
    } else if (collision.selfSide == CollisionSide.right &&
        currentAnimation?.name != 'wallJump') {
      if (isFlipped) {
        flip();
      }
      play('wallJump');
    }
  }

  @override
  void onCollisionStay(GameObject other, CollisionInfo collision) {
    if (collision.selfSide == CollisionSide.bottom &&
        other.name == 'PlayerGem') {
      SceneManager.instance.current?.remove(other);
      return;
    } else if (collision.selfSide == CollisionSide.bottom &&
        other.name != 'PlayerGem') {
      isGrounded = true;
      // Zera somente a componente vertical para não matar o movimento horizontal
      setVelocity(Offset(velocity.dx, 0));
    }
  }

  @override
  void onAdd() {
    super.onAdd();
    final playerGetArea = PlayerGetArea.withPlayer(this);
    attachObject(playerGetArea, const Offset(24, 24));
    var row = 0;
    addAnimation(
      SpriteAnimation(
        name: 'run',
        frameSize: Size(32, 32),
        frames: [
          Frame(col: 0, row: row),
          Frame(col: 1, row: row),
          Frame(col: 2, row: row),
          Frame(col: 3, row: row),
          Frame(col: 4, row: row),
          Frame(col: 5, row: row),
          Frame(col: 6, row: row),
          Frame(col: 7, row: row),
          Frame(col: 8, row: row),
          Frame(col: 9, row: row),
          Frame(col: 10, row: row),
          Frame(col: 11, row: row),
        ],
      ),
    );

    row = 1;
    addAnimation(
      SpriteAnimation(
        name: 'hit',
        frameSize: Size(32, 32),
        frames: [
          Frame(col: 0, row: row),
          Frame(col: 1, row: row),
          Frame(col: 2, row: row),
          Frame(col: 3, row: row),
          Frame(col: 4, row: row),
          Frame(col: 5, row: row),
          Frame(col: 6, row: row),
        ],
      ),
    );

    row = 2;
    addAnimation(
      SpriteAnimation(
        name: 'doubleJump',
        frameSize: Size(32, 32),
        frames: [
          Frame(col: 0, row: row),
          Frame(col: 1, row: row),
          Frame(col: 2, row: row),
          Frame(col: 3, row: row),
          Frame(col: 4, row: row),
          Frame(col: 5, row: row),
        ],
      ),
    );

    row = 3;
    addAnimation(
      SpriteAnimation(
        name: 'idle',
        frameSize: Size(32, 32),
        frames: [
          Frame(col: 0, row: row),
          Frame(col: 1, row: row),
          Frame(col: 2, row: row),
          Frame(col: 3, row: row),
          Frame(col: 4, row: row),
          Frame(col: 5, row: row),
          Frame(col: 6, row: row),
          Frame(col: 7, row: row),
          Frame(col: 8, row: row),
          Frame(col: 9, row: row),
          Frame(col: 10, row: row),
        ],
      ),
    );

    row = 4;
    addAnimation(
      SpriteAnimation(
        name: 'wallJump',
        frameSize: Size(32, 32),
        frames: [
          Frame(col: 0, row: row),
          Frame(col: 1, row: row),
          Frame(col: 2, row: row),
          Frame(col: 3, row: row),
          Frame(col: 4, row: row),
        ],
      ),
    );

    row = 5;
    addAnimation(
      SpriteAnimation(
        name: 'jump',
        frameSize: Size(32, 32),
        frames: [Frame(col: 0, row: row)],
      ),
    );

    row = 6;
    addAnimation(
      SpriteAnimation(
        name: 'fall',
        frameSize: Size(32, 32),
        frames: [Frame(col: 0, row: row)],
      ),
    );
  }
}

class Jumper extends SpriteSheet with CollisionCallbacks {
  Jumper({
    super.name = 'Jumper',
    required super.image,
    super.size = const Size(48, 48),
  }) : super() {
    addAABBCollider(
      size: Size(48, 16),
      anchor: ColliderAnchor.bottomCenter,
      debugColor: Colors.green,
    );

    addAnimation(
      SpriteAnimation(
        name: 'idle',
        frameSize: Size(48, 48),
        frames: [Frame(col: 0, row: 0)],
      ),
    );

    addAnimation(
      SpriteAnimation(
        name: 'jump',
        frameSize: Size(48, 48),
        frames: [
          Frame(col: 2, row: 0),
          Frame(col: 3, row: 0),
          Frame(col: 4, row: 0),
          Frame(col: 5, row: 0),
          Frame(col: 6, row: 0),
        ],
        frameDuration: 0.05,
        loop: false,
        onEnd: () {
          play('idle');
        },
      ),
    );
  }

  @override
  void onAdd() {
    super.onAdd();
    play('idle');
  }

  @override
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    super.onCollisionEnter(other, collision);
    if (collision.selfSide == CollisionSide.top && other is Player) {
      play('jump');
      AudioManager.instance.playSound('spring.mp3');
    }
  }
}

class PlayerGetArea extends GameObject with CollisionCallbacks {
  PlayerGetArea(this.player, {super.name = 'PlayerGetArea'}) : super() {
    addCircleCollider(radius: 80, isTrigger: true, debugColor: Colors.orange);
  }

  final Player player;

  PlayerGetArea.withPlayer(this.player) : super() {
    addCircleCollider(radius: 80, isTrigger: true, debugColor: Colors.orange);
  }

  @override
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    super.onCollisionEnter(other, collision);

    if (other.name == 'PlayerGem') {
      Animations.moveTo(
        other,
        Offset(player.position.dx + 24, player.position.dy + 24),
        0.2,
        ease: EasingType.easeIn,
        onComplete: () {
          SceneManager.instance.current?.remove(other);
        },
      );
      AudioManager.instance.playSound('coin.mp3');
      return;
    }
  }

  @override
  void render(Canvas canvas) {}
}
