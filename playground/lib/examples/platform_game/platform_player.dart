import 'dart:ui';

import 'package:flutter/material.dart' show Colors, debugPrint;
import 'package:lepiengine/engine/core/audio_manager.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/engine/core/collision_manager.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/core/input_manager.dart';
import 'package:lepiengine/engine/core/scene_manager.dart';
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';
import 'package:lepiengine_playground/examples/platform_game/jumper.dart';
import 'package:lepiengine_playground/examples/platform_game/player_get_area.dart';
import 'package:lepiengine_playground/examples/platform_game/static_objects.dart';

class PlatformPlayer extends SpriteSheet with PhysicsBody, CollisionCallbacks {
  PlatformPlayer({super.name = 'Player', required super.image}) : super() {
    addAABBCollider(
      size: Size(12, 18),
      anchor: ColliderAnchor.bottomCenter,
      debugColor: Colors.blue,
    );

    gravity = 400;
    maxFallSpeed = 400;
  }

  bool isGrounded = false;
  final double moveSpeed = 80.0;
  final double jumpForce = -200.0;
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
    smoke.position = Offset(position.dx + 16, position.dy + 16);
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
        other.name == 'PlayerGem' &&
        other.name != 'PlayerGetArea') {
      SceneManager.instance.current?.remove(other);
      return;
    } else if (collision.selfSide == CollisionSide.bottom &&
        other.name != 'PlayerGem' &&
        other.name != 'PlayerGetArea') {
      isGrounded = true;
      // Zera somente a componente vertical para não matar o movimento horizontal
      setVelocity(Offset(velocity.dx, 0));
    }
  }

  @override
  void onAdd() {
    super.onAdd();
    final playerGetArea = PlayerGetArea.withPlayer(this);
    attachObject(playerGetArea, const Offset(12, 12));
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
