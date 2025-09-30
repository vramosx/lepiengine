import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/main.dart';

class ShipsBattle extends Scene {
  ShipsBattle({super.name = 'ShipsBattle', super.debugCollisions = true})
    : super(clearColor: Colors.blueAccent);

  @override
  void onEnter() {
    super.onEnter();
    _loadScene();
  }

  Future<void> _loadScene() async {
    final player = Player();
    add(player);
  }
}

class Player extends GameObject with KeyboardControllable, CollisionCallbacks {
  Player({super.name = 'Player'}) : super() {
    position = const Offset(0, 0);
  }

  Ship? ship;

  @override
  void onAdd() {
    super.onAdd();
    loadPlayer();
  }

  Future<void> loadPlayer() async {
    SceneManager.instance.current?.setLayerOrder('waterEffects', 1);
    SceneManager.instance.current?.setLayerOrder('entities', 2);
    final shipImage = await AssetLoader.loadImage('ships_battle/ships.png');
    ship = Ship(image: shipImage);
    ship!.position = const Offset(0, 0);
    addChild(ship!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _handleInput();
  }

  void _handleInput() {
    if (InputManager.instance.isPressed('Arrow Left')) {
      ship?.rotateLeft();
    }
    if (InputManager.instance.isPressed('Arrow Right')) {
      ship?.rotateRight();
    }

    if (InputManager.instance.isPressed('Arrow Up')) {
      ship?.forward();
    }
    if (InputManager.instance.isPressed('Arrow Down')) {
      ship?.backward();
    }

    if (InputManager.instance.isPressed('Space')) {
      ship?.shoot();
    }
  }
}

class Enemy extends GameObject with CollisionCallbacks {
  Enemy({super.name = 'Enemy'}) : super() {
    size = const Size(128, 128);
    anchor = const Offset(0.5, 0.5);
    position = const Offset(0, 0);

    addAABBCollider(
      size: Size(128, 128),
      anchor: ColliderAnchor.bottomCenter,
      debugColor: Colors.red,
    );
  }
}

class Ship extends SpriteSheet with PhysicsBody {
  Ship({super.name = 'Ship', required super.image}) : super() {
    size = const Size(128, 128);
    anchor = const Offset(0.5, 0.5);
    position = const Offset(0, 0);

    enableGravity = false;
    maxVelocity = 50;

    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 4; j++) {
        addAnimation(
          SpriteAnimation(
            name: 'ship$i-life$j',
            frameSize: const Size(128, 128),
            frames: [Frame(col: i, row: j)],
          ),
        );
      }
    }
    bulletPosition = BulletPosition(name: 'bulletPosition');
    attachObject(bulletPosition!, Offset(61, 10));

    play('ship$selectedShip-life0');

    addAABBCollider(
      size: Size(64, 115),
      anchor: ColliderAnchor.center,
      debugColor: Colors.red,
    );
  }

  int selectedShip = 1;
  double speed = 0.5;
  double maxSpeed = 100;
  double reloadTime = 0.2;
  double reloadTimer = 0;
  int bulletCount = 0;
  int maxBulletCount = 50;
  int waterEffectCount = 0;
  int maxWaterEffectCount = 12;
  double waterEffectTimer = 0;
  double waterEffectInterval = 0.2;
  GameObject? bulletPosition;

  Future<void> shoot() async {
    if (bulletCount >= maxBulletCount || reloadTimer > 0) return;
    bulletCount++;
    reloadTimer = reloadTime;
    final bulletImage = await AssetLoader.loadImage('ships_battle/bullet.png');
    Bullet bullet = Bullet(image: bulletImage);

    final mountWorld = bulletPosition!.localToWorld(Offset(-5, -5));

    bullet.position = mountWorld;
    bullet.rotation = rotation;

    final scene = SceneManager.instance.current!;
    scene.add(bullet);

    // Move na direção da rotação atual do Ship (frente do navio)
    final dir = Offset(math.sin(bullet.rotation), -math.cos(bullet.rotation));
    final dest = bullet.position + dir * 400;
    late SpriteSheet bulletWaterEffect;

    bulletWaterEffect = await bulletWaterEffectBuilder(() {
      scene.remove(bulletWaterEffect);
    });
    bulletWaterEffect.rotation = bullet.rotation;
    bulletWaterEffect.anchor = const Offset(0, 0);
    bulletWaterEffect.position = bullet.position;

    Animations.moveTo(
      bullet,
      dest,
      1,
      onComplete: () {
        scene.remove(bullet);
        bulletCount--;

        bulletWaterEffect.position = bullet.position;
        bulletWaterEffect.play('waterEffect');
        scene.add(bulletWaterEffect, layer: 'waterEffects');
      },
    );
  }

  Future<void> createWaterEffect() async {
    if (waterEffectCount >= maxWaterEffectCount || waterEffectTimer > 0) return;
    waterEffectCount++;
    waterEffectTimer = waterEffectInterval;
    final scene = SceneManager.instance.current!;
    late SpriteSheet waterEffect;
    waterEffect = await waterEffectBuilder(() {
      scene.remove(waterEffect);
      waterEffectCount--;
    });
    waterEffect.rotation = rotation;
    waterEffect.anchor = const Offset(0, 0);
    waterEffect.position = localToWorld(Offset(50, 100));
    scene.add(waterEffect, layer: 'waterEffects');
  }

  @override
  void update(double dt) {
    super.update(dt);
    reloadTimer = math.max(0, reloadTimer - dt);
    waterEffectTimer = math.max(0, waterEffectTimer - dt);
  }

  void rotateLeft() {
    rotation -= 0.05;
  }

  void rotateRight() {
    rotation += 0.05;
  }

  void forward() {
    final deg = localDegrees();
    final radians = deg * math.pi / 180;
    final vx = speed * math.sin(radians); // Velocidade máxima * componente x
    final vy =
        -speed *
        math.cos(
          radians,
        ); // Velocidade máxima * componente y (negativo pois y cresce para baixo)
    addVelocity(Offset(vx, vy));
    createWaterEffect();
  }

  void backward() {
    final deg = localDegrees();
    final radians = deg * math.pi / 180;
    final vx = -speed * math.sin(radians);
    final vy = speed * math.cos(radians);
    addVelocity(Offset(vx, vy));
  }
}

class Bullet extends Sprite with PhysicsBody {
  Bullet({super.name = 'Bullet', required super.image}) : super() {
    size = const Size(16, 16);
    anchor = const Offset(0, 0);
    enableGravity = false;
    maxVelocity = 5000;
  }
}

class BulletPosition extends GameObject {
  BulletPosition({super.name = 'BulletPosition'}) : super() {
    size = const Size(6, 6);
    anchor = const Offset(0, 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (kDebugMode) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width,
        Paint()
          ..color = Colors.black.withAlpha(200)
          ..style = PaintingStyle.fill,
      );
    }
  }
}

Future<SpriteSheet> bulletWaterEffectBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: "bulletWaterEffect",
      imagePath: "ships_battle/bullet_water_effect.png",
      size: Size(32, 32),
      animations: [
        SpriteAnimation(
          name: "waterEffect",
          frameSize: Size(32, 32),
          frames: [
            Frame(col: 0, row: 0),
            Frame(col: 1, row: 0),
            Frame(col: 2, row: 0),
            Frame(col: 3, row: 0),
          ],
          frameDuration: 0.1,
          loop: false,
          onEnd: () {
            onEnd?.call();
          },
        ),
      ],
      initialAnimation: "waterEffect",
    );

Future<SpriteSheet> waterEffectBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: "waterEffect",
      imagePath: "ships_battle/water_effect.png",
      size: Size(32, 32),
      animations: [
        SpriteAnimation(
          name: "waterEffect",
          frameSize: Size(32, 32),
          frames: [
            Frame(col: 0, row: 0),
            Frame(col: 1, row: 0),
            Frame(col: 2, row: 0),
            Frame(col: 3, row: 0),
          ],
          frameDuration: 0.2,
          loop: false,
          onEnd: () {
            onEnd?.call();
          },
        ),
      ],
      initialAnimation: "waterEffect",
    );
