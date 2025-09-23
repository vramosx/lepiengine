import 'dart:ui';

import 'package:flutter/material.dart'
    show Colors, debugPrint, TextPainter, TextSpan;
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
import 'package:lepiengine_playground/examples/utils/constants.dart';
import 'package:lepiengine_playground/examples/utils/json_utils.dart';

class PlatformGame extends Scene {
  PlatformGame({super.name = 'PlatformGame'}) : super(debugCollisions: true);

  @override
  void onEnter() {
    super.onEnter();
    final platformMap = PlatformMap();
    add(platformMap, layer: 'map');

    _loadPlayer();

    _loadPointerIdle();

    setLayerOrder("map", 0);

    // AudioManager.instance.playMusic(Constants.backgroundMusic);

    // add(DebugText(text: 'Debug Text', position: const Offset(100, 200)));
  }

  Future<void> _loadPointerIdle() async {
    final pointerIdleSprite = await AssetLoader.loadImage(
      Constants.pointerIdle,
    );
    final pointerIdle = PointerIdle(image: pointerIdleSprite);
    pointerIdle.position = const Offset(100, 450);
    add(pointerIdle, layer: 'frontPlayer');
    setLayerOrder("frontPlayer", 4);
  }

  Future<void> _loadPlayer() async {
    final playerSprite = await AssetLoader.loadImage(Constants.character);
    final player = Player(image: playerSprite);
    player.size = const Size(48, 48);
    player.position = const Offset(250, 400);
    add(player);
    player.play('idle');
    setLayerOrder("entities", 3);
    camera.follow(player);
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

class DebugText extends GameObject {
  final String text;
  DebugText({super.name = 'DebugText', required this.text, super.position});

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(text: text),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}

class Player extends SpriteSheet with PhysicsBody, CollisionCallbacks {
  Player({super.name = 'Player', required super.image}) : super() {
    addAABBCollider(
      size: Size(30, 42),
      anchor: ColliderAnchor.bottomCenter,
      debugColor: Colors.blue,
    );

    gravity = 800;
    maxFallSpeed = 500;
  }

  bool isGrounded = false;
  final double moveSpeed = 150.0;
  final double jumpForce = -350.0;
  bool isFlipped = false;

  void flip() {
    isFlipped = !isFlipped;
    flipX = !flipX;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _handleInput();
  }

  void _handleInput() {
    // Pulo (lógica específica de plataforma)// Pulo (lógica específica de plataforma)
    final jumpPressed =
        InputManager.instance.isPressed('KeyW') ||
        InputManager.instance.isPressed('Arrow Up') ||
        InputManager.instance.isPressed('Space');

    if (jumpPressed) {
      if (isGrounded) {
        // AudioManager.instance.playSound('jump.mp3');
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
      horizontal = -1.0;
      play('run');
      if (!isFlipped) {
        flip();
      }
    }
    if (InputManager.instance.isPressed('KeyD') ||
        InputManager.instance.isPressed('Arrow Right')) {
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
      SceneManager.instance.current?.camera.lightShake();
    } else if (collision.selfSide == CollisionSide.top) {
      debugPrint("collision top: ${collision.selfSide}");
    } else if (collision.selfSide == CollisionSide.left) {
      debugPrint("collision left: ${collision.selfSide}");
    } else if (collision.selfSide == CollisionSide.right) {
      debugPrint("collision right: ${collision.selfSide}");
    }
  }

  @override
  void onCollisionStay(GameObject other, CollisionInfo collision) {
    // Mantém isGrounded enquanto estiver colidindo com o chão
    if (collision.selfSide == CollisionSide.bottom) {
      isGrounded = true;
      // Zera somente a componente vertical para não matar o movimento horizontal
      setVelocity(Offset(velocity.dx, 0));
    }
  }

  @override
  void onAdd() {
    super.onAdd();
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

class PointerIdle extends SpriteSheet {
  PointerIdle({
    super.name = 'PointerIdle',
    super.size = const Size(64, 64),
    required super.image,
  }) : super() {
    addAnimation(
      SpriteAnimation(
        name: 'idle',
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
          Frame(col: 6, row: 0),
        ],
        frameDuration: 0.2,
      ),
    );
  }

  @override
  void onAdd() {
    super.onAdd();
    play('idle');
  }
}
