import 'package:flutter/material.dart';
import 'package:lepiengine/engine/core/audio_manager.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/engine/core/collision_manager.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_player.dart';

class Jumper extends SpriteSheet with CollisionCallbacks {
  Jumper({
    super.name = 'Jumper',
    required super.image,
    super.size = const Size(24, 24),
  }) : super() {
    addAABBCollider(
      size: Size(24, 12),
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
    if (collision.selfSide == CollisionSide.top && other is PlatformPlayer) {
      play('jump');
      AudioManager.instance.playSound('spring.mp3');
    }
  }
}
