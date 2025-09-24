import 'dart:ui';

import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';
import 'package:lepiengine/engine/tools/sprite_sheet_builder.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';

Future<SpriteSheet> pointerIdleBuilder = SpriteSheetBuilder.build(
  name: 'PointerIdle',
  imagePath: Constants.pointerIdle,
  size: Size(64, 64),
  animations: [
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
  ],
  initialAnimation: 'idle',
);

Future<SpriteSheet> playerStartBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: 'PlayerStart',
      imagePath: Constants.appearing,
      size: Size(96, 96),
      animations: [
        SpriteAnimation(
          name: 'start',
          frameSize: Size(96, 96),
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

Future<SpriteSheet> playerGemBuilder = SpriteSheetBuilder.build(
  name: 'PlayerGem',
  imagePath: Constants.gem,
  size: Size(16, 16),
  animations: [
    SpriteAnimation(
      name: 'gem',
      frameSize: Size(16, 16),
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

Future<SpriteSheet> playerMovementSmokeBuilder(Function()? onEnd) =>
    SpriteSheetBuilder.build(
      name: 'PlayerMovementSmoke',
      imagePath: Constants.smoke,
      size: Size(16, 16),
      animations: [
        SpriteAnimation(
          name: 'smoke',
          frameSize: Size(16, 16),
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
