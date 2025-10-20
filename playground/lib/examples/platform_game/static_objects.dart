import 'dart:ui';

import 'package:flutter/material.dart' show Colors;
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';
import 'package:lepiengine/engine/tools/sprite_sheet_builder.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';

/// Builds a simple idle pointer sprite sheet used as a static visual hint.
Future<SpriteSheet> buildPointerIdle() => SpriteSheetBuilder.build(
  name: 'PointerIdle',
  imagePath: Constants.pointerIdle,
  size: const Size(32, 32),
  animations: [
    SpriteAnimation(
      name: 'idle',
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
        Frame(col: 6, row: 0),
      ],
      frameDuration: 0.2,
    ),
  ],
  initialAnimation: 'idle',
);

/// Builds the player "appearing" effect, calling [onEnd] when finished.
Future<SpriteSheet> playerStartBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: 'PlayerStart',
      imagePath: Constants.appearing,
      size: const Size(24, 24),
      animations: [
        SpriteAnimation(
          name: 'start',
          frameSize: const Size(96, 96),
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
          frameDuration: 0.1,
          onEnd: () {
            onEnd?.call();
          },
        ),
      ],
      initialAnimation: 'start',
    );

/// Builds the collectible gem with a trigger collider so the player can pick it up.
Future<SpriteSheet> playerGemBuilder() => SpriteSheetBuilder.buildWithCollider(
  name: 'PlayerGem',
  imagePath: Constants.gem,
  size: const Size(8, 8),
  isTrigger: true,
  debugColor: Colors.black,
  animations: [
    SpriteAnimation(
      name: 'gem',
      frameSize: const Size(16, 16),
      frames: [
        Frame(col: 0, row: 0),
        Frame(col: 1, row: 0),
        Frame(col: 2, row: 0),
        Frame(col: 3, row: 0),
        Frame(col: 4, row: 0),
        Frame(col: 5, row: 0),
        Frame(col: 6, row: 0),
      ],
    ),
  ],
  initialAnimation: 'gem',
);

/// Builds a short-lived smoke effect shown when the player starts moving.
Future<SpriteSheet> playerMovementSmokeBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: 'PlayerMovementSmoke',
      imagePath: Constants.smoke,
      size: const Size(8, 8),
      animations: [
        SpriteAnimation(
          name: 'smoke',
          frameSize: const Size(16, 16),
          frames: [
            Frame(col: 0, row: 0),
            Frame(col: 1, row: 0),
            Frame(col: 2, row: 0),
            Frame(col: 3, row: 0),
            Frame(col: 0, row: 1),
            Frame(col: 1, row: 1),
            Frame(col: 2, row: 1),
            Frame(col: 3, row: 1),
          ],
          loop: false,
          frameDuration: 0.1,
          onEnd: () {
            onEnd?.call();
          },
        ),
      ],
      initialAnimation: 'smoke',
    );
