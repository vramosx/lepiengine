import 'dart:ui';

import 'package:flutter/material.dart' show Colors, debugPrint;
import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/engine/core/collision_manager.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/core/scene.dart';
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
    add(platformMap);

    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    final playerSprite = await AssetLoader.loadImage(Constants.character);
    final player = Player(image: playerSprite);
    player.position = const Offset(100, 200);
    player.size = const Size(48, 48);
    add(player);
    player.play('idle');
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

    final tilemap = Tilemap(
      tileset: tileset,
      map: map,
      position: const Offset(0, 0),
      debugCollisions: true,
      solidTiles: solidTiles,
    );
    addChild(backgroundTilemap);
    addChild(tilemap);
  }

  @override
  void render(Canvas canvas) {}
}

class Player extends SpriteSheet with PhysicsBody, CollisionCallbacks {
  Player({super.name = 'Player', required super.image}) : super() {
    addAABBCollider(
      size: Size(32, 32),
      anchor: ColliderAnchor.bottomCenter,
      offset: Offset(
        0,
        8,
      ), // Ajusta para alinhar com a parte inferior do sprite
      debugColor: Colors.blue,
    );

    gravity = 0;
    // maxFallSpeed = 500;
  }

  double coyoteTime = 0.0;
  final double maxCoyoteTime = 0.1;
  bool isGrounded = false;

  @override
  void update(double dt) {
    super.update(dt);

    // Atualiza coyote time (lógica específica de plataforma)
    if (isGrounded) {
      coyoteTime = maxCoyoteTime;
    } else {
      coyoteTime = (coyoteTime - dt).clamp(0.0, maxCoyoteTime);
    }
  }

  @override
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    debugPrint('Collision enter: ${other.runtimeType}');
  }

  @override
  void onAdd() {
    super.onAdd();
    
    // Debug: vamos verificar as posições
    debugPrint('Player position: $position');
    debugPrint('Player size: $size');
    debugPrint('Player worldPosition: ${localToWorld(Offset.zero)}');
    
    // Vamos também verificar a posição do collider
    if (colliders.isNotEmpty) {
      final collider = colliders.first;
      debugPrint('Collider worldPosition: ${collider.worldPosition}');
      debugPrint('Collider AABB: ${collider.getAABB()}');
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
