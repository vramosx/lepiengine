import 'dart:math' as math;
import 'dart:ui';

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
    setLayerOrder('waterEffects', 1);
    setLayerOrder('entities', 2);
    setLayerOrder('effects', 3);

    final player = Player();
    player.position = const Offset(800, 0);
    add(player);

    final enemy = Enemy(player: player);
    enemy.position = const Offset(0, 0);
    add(enemy);
  }
}

class Player extends GameObject with KeyboardControllable {
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
    final shipImage = await AssetLoader.loadImage('ships_battle/ships.png');
    ship = Ship(
      image: shipImage,
      selectedShip: 1,
      isPlayer: true,
      onDamage: (bullet) {
        SceneManager.instance.current?.camera.lightShake();
      },
    );
    ship!.position = const Offset(0, 0);
    addChild(ship!);
    SceneManager.instance.current?.camera.follow(ship!);
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

class Enemy extends GameObject {
  Enemy({super.name = 'Enemy', required this.player}) : super() {
    size = const Size(128, 128);
    anchor = const Offset(0.5, 0.5);
    position = const Offset(0, 0);
  }

  Ship? ship;
  Player? player;
  int life = 4;
  double enemyReactionTimer = 0;
  double enemyReactionInterval = 1;
  int bulletCount = 0;
  int maxBulletCount = 1;
  bool attacking = false;
  bool dead = false;

  @override
  void onAdd() {
    super.onAdd();
    loadEnemy();
  }

  Future<void> createExplosionEffect(Bullet bullet) async {
    final scene = SceneManager.instance.current!;
    late SpriteSheet explosionEffect;
    explosionEffect = await explosionEffectBuilder(() {
      scene.remove(explosionEffect);
    });
    explosionEffect.rotation = bullet.rotation;
    explosionEffect.position = bullet.position;
    scene.add(explosionEffect, layer: 'effects');
    scene.camera.lightShake();
  }

  Future<void> loadEnemy() async {
    final shipImage = await AssetLoader.loadImage('ships_battle/ships.png');
    ship = Ship(
      image: shipImage,
      selectedShip: 2,
      onDamage: (bullet) {
        life--;
        ship!.life += 1;
        ship!.play('ship${ship!.selectedShip}-life${ship!.life}');
        createExplosionEffect(bullet);

        if (life <= 0) {
          dead = true;
          active = false;
          SceneManager.instance.current?.remove(this);
        }
      },
    );
    ship!.position = const Offset(0, 0);
    ship!.speed = 25;
    addChild(ship!);
  }

  @override
  void update(double dt) {
    if (dead) return;
    super.update(dt);
    enemyReactionTimer = math.max(0, enemyReactionTimer - dt);
    if (enemyReactionTimer <= 0) {
      enemyReaction();
    }
  }

  void enemyReaction() {
    if (dead) return;
    enemyReactionTimer = enemyReactionInterval;
    ship?.rotateToObject(player!.ship!);
    final distance = ship?.distanceTo(player!.ship!) ?? 0;
    if (distance > 400 && !attacking) {
      Future.delayed(Duration(milliseconds: 1000), () {
        if (dead) return;
        ship?.forward();
      });
    } else {
      attacking = true;
      Future.delayed(Duration(milliseconds: 8000), () {
        if (dead) return;
        if (bulletCount < maxBulletCount) {
          ship?.shoot(
            onComplete: () {
              bulletCount--;
            },
          );
          bulletCount++;
        }
        attacking = false;
      });
    }
    // ship?.forward();
  }

  @override
  void onRemove() {
    super.onRemove();
    dead = true;
    ship = null;
  }
}

class Ship extends SpriteSheet with PhysicsBody, CollisionCallbacks {
  Ship({
    super.name = 'Ship',
    required super.image,
    required this.selectedShip,
    this.isPlayer = false,
    this.onDamage,
  }) : super() {
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

    play('ship$selectedShip-life$life');

    addAABBCollider(
      size: Size(20, 10),
      anchor: ColliderAnchor.topCenter,
      offset: Offset(0, 10),
      debugColor: Colors.greenAccent,
    );

    addAABBCollider(
      size: Size(40, 10),
      anchor: ColliderAnchor.topCenter,
      offset: Offset(0, 20),
      debugColor: Colors.greenAccent,
    );

    addAABBCollider(
      size: Size(60, 40),
      anchor: ColliderAnchor.topCenter,
      offset: Offset(0, 30),
      debugColor: Colors.greenAccent,
    );

    addAABBCollider(
      size: Size(30, 40),
      anchor: ColliderAnchor.topCenter,
      offset: Offset(0, 70),
      debugColor: Colors.greenAccent,
    );

    addAABBCollider(
      size: Size(20, 10),
      anchor: ColliderAnchor.topCenter,
      offset: Offset(0, 110),
      debugColor: Colors.greenAccent,
    );
  }

  int selectedShip = 1;
  int life = 0;
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
  double deacceleration = 5;
  GameObject? bulletPosition;
  bool isPlayer = false;
  Function(Bullet)? onDamage;

  Future<void> shoot({Function()? onComplete}) async {
    if (bulletCount >= maxBulletCount || reloadTimer > 0) return;
    bulletCount++;
    reloadTimer = reloadTime;
    final bulletImage = await AssetLoader.loadImage('ships_battle/bullet.png');
    Bullet bullet = Bullet(image: bulletImage, fromPlayer: isPlayer);

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

        if (!bullet.destroyed) {
          bulletWaterEffect.position = bullet.position;
          bulletWaterEffect.play('waterEffect');
          scene.add(bulletWaterEffect, layer: 'waterEffects');
        }

        onComplete?.call();
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
  void onCollisionEnter(GameObject other, CollisionInfo collision) {
    super.onCollisionEnter(other, collision);
    if (other is Bullet && other.fromPlayer != isPlayer) {
      other.destroyed = true;
      SceneManager.instance.current?.remove(other);
      Animations.blink(this, Colors.red, 30, 0.1);
      onDamage?.call(other);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    reloadTimer = math.max(0, reloadTimer - dt);
    waterEffectTimer = math.max(0, waterEffectTimer - dt);
    // Desacelera suavemente até parar completamente
    final v = velocity;
    if (v.dx != 0 || v.dy != 0) {
      final currentSpeed = v.distance;
      final decelAmount = deacceleration * dt;
      if (currentSpeed <= decelAmount) {
        setVelocity(Offset.zero);
      } else {
        final dir = v / currentSpeed; // normalizado
        setVelocity(dir * (currentSpeed - decelAmount));
      }
    }
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
  Bullet({super.name = 'Bullet', required super.image, this.fromPlayer = false})
    : super() {
    size = const Size(16, 16);
    anchor = const Offset(0, 0);
    enableGravity = false;
    maxVelocity = 5000;

    addCircleCollider(
      radius: 4,
      debugColor: Colors.deepPurpleAccent,
      isTrigger: true,
    );
  }

  bool fromPlayer = false;
  bool destroyed = false;
}

class BulletPosition extends GameObject {
  BulletPosition({super.name = 'BulletPosition'}) : super() {
    size = const Size(6, 6);
    anchor = const Offset(0, 0);
  }

  @override
  void render(Canvas canvas) {
    final scene = SceneManager.instance.current!;
    super.render(canvas);
    if (scene.collisionManager.debugMode) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width,
        Paint()
          ..color = Colors.black.withAlpha(200)
          ..style = PaintingStyle.stroke,
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

Future<SpriteSheet> explosionEffectBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: "explosionEffect",
      imagePath: "ships_battle/effects.png",
      size: Size(32, 32),
      animations: [
        SpriteAnimation(
          name: "explosionEffect",
          frameSize: Size(96, 96),
          frames: [
            Frame(col: 0, row: 0),
            Frame(col: 1, row: 0),
            Frame(col: 2, row: 0),
          ],
          frameDuration: 0.1,
          loop: false,
          onEnd: () {
            onEnd?.call();
          },
        ),
      ],
      initialAnimation: "explosionEffect",
    );
