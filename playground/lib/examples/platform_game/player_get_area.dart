import 'package:flutter/material.dart';
import 'package:lepiengine/engine/animation/animations.dart';
import 'package:lepiengine/engine/animation/easing.dart';
import 'package:lepiengine/engine/core/audio_manager.dart';
import 'package:lepiengine/engine/core/collider.dart';
import 'package:lepiengine/engine/core/collision_manager.dart';
import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/core/scene_manager.dart';
import 'package:lepiengine_playground/examples/platform_game/platform_player.dart';

class PlayerGetArea extends GameObject with CollisionCallbacks {
  PlayerGetArea(this.player, {super.name = 'PlayerGetArea'}) : super() {
    addCircleCollider(radius: 20, isTrigger: true, debugColor: Colors.orange);
  }

  final PlatformPlayer player;

  PlayerGetArea.withPlayer(this.player, {super.name = 'PlayerGetArea'})
    : super() {
    addCircleCollider(radius: 20, isTrigger: true, debugColor: Colors.orange);
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
