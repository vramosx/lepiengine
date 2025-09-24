import 'dart:ui';
import 'package:lepiengine/engine/animation/animations.dart';
import 'package:lepiengine/engine/animation/easing.dart';
import 'package:lepiengine/engine/core/asset_loader.dart';
import 'package:lepiengine/engine/core/scene.dart';
import 'package:lepiengine/engine/core/viewport.dart';
import 'package:lepiengine/engine/core/scene_manager.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';
import 'package:lepiengine/engine/game_objects/sprite_sheet.dart';

enum DemoFeature {
  moveTo,
  moveBy,
  rotateTo,
  scaleTo,
  resize,
  fadeIn,
  fadeOut,
  colorTo,
  blink,
  sequence,
  parallel,
  repeat,
  forever,
  shake,
  pulse,
  wiggle,
  pathFollow,
  custom,
}

const Map<DemoFeature, String> kDemoNames = {
  DemoFeature.moveTo: 'Move To',
  DemoFeature.moveBy: 'Move By',
  DemoFeature.rotateTo: 'Rotate To',
  DemoFeature.scaleTo: 'Scale To',
  DemoFeature.resize: 'Resize',
  DemoFeature.fadeIn: 'Fade In',
  DemoFeature.fadeOut: 'Fade Out',
  DemoFeature.colorTo: 'Color To',
  DemoFeature.blink: 'Blink',
  DemoFeature.sequence: 'Sequence',
  DemoFeature.parallel: 'Parallel',
  DemoFeature.repeat: 'Repeat',
  DemoFeature.forever: 'Forever',
  DemoFeature.shake: 'Shake',
  DemoFeature.pulse: 'Pulse',
  DemoFeature.wiggle: 'Wiggle',
  DemoFeature.pathFollow: 'Path Follow',
  DemoFeature.custom: 'Custom',
};

class AnimationShowcase extends Scene {
  AnimationShowcase({super.name = 'AnimationShowcase'})
    : super(debugCollisions: false);

  DemoFeature currentFeature = DemoFeature.moveTo;

  late SpriteSheet char;
  late SpriteSheet pointer;
  late SpriteSheet gem;

  @override
  void onEnter() {
    super.onEnter();
    _setupBackground();
    _loadAssets();
  }

  Future<void> _setupBackground() async {
    // Apenas uma cor de fundo escura para destacar as animações
    setLayerOrder('background', 0);
    setLayerOrder('entities', 10);
    setLayerOrder('ui', 100);
  }

  Future<void> _loadAssets() async {
    final imageChar = await AssetLoader.loadImage(Constants.character);
    final imagePointer = await AssetLoader.loadImage(Constants.pointerIdle);
    final imageGem = await AssetLoader.loadImage(Constants.gem);

    char = SpriteSheet(image: imageChar, size: const Size(64, 64));
    pointer = SpriteSheet(image: imagePointer, size: const Size(64, 64));
    gem = SpriteSheet(image: imageGem, size: const Size(32, 32));

    // Animações básicas para ter algo para desenhar (frame único)
    char.addAnimation(
      SpriteAnimation(
        name: 'idle',
        frameSize: const Size(32, 32),
        frames: [Frame(col: 0, row: 3)],
      ),
    );
    pointer.addAnimation(
      SpriteAnimation(
        name: 'idle',
        frameSize: const Size(48, 48),
        frames: [Frame(col: 0, row: 0)],
      ),
    );
    gem.addAnimation(
      SpriteAnimation(
        name: 'idle',
        frameSize: const Size(16, 16),
        frames: [Frame(col: 0, row: 0)],
      ),
    );
    char.play('idle');
    pointer.play('idle');
    gem.play('idle');

    add(char);
    add(pointer);
    add(gem);

    _resetTargets();
    _playCurrent();
    SceneManager.instance.current?.camera.focusOn(char);
  }

  Offset _center() {
    final size = SceneManager.instance.logicalViewportSize;
    return Offset(size.width / 2, size.height / 2);
  }

  void _resetTargets() {
    final c = _center();
    // Mostrar apenas o char para centralizar a demo
    char
      ..anchor = const Offset(0.5, 0.5)
      ..position = c
      ..rotation = 0
      ..scale = const Offset(1, 1)
      ..size = const Size(64, 64)
      ..opacity = 1.0
      ..tintColor = null
      ..visible = true;

    pointer
      ..anchor = const Offset(0.5, 0.5)
      ..position = c
      ..rotation = 0
      ..scale = const Offset(1, 1)
      ..size = const Size(64, 64)
      ..opacity = 1.0
      ..tintColor = null
      ..visible = false; // oculto por padrão

    gem
      ..anchor = const Offset(0.5, 0.5)
      ..position = c
      ..rotation = 0
      ..scale = const Offset(1, 1)
      ..size = const Size(32, 32)
      ..opacity = 1.0
      ..tintColor = null
      ..visible = false; // oculto por padrão

    // Limpa animações ativas
    animationManager.clear();
  }

  void _playCurrent() {
    // Garante estado limpo
    _resetTargets();
    final c = _center();

    switch (currentFeature) {
      case DemoFeature.moveTo:
        Animations.moveTo(
          char,
          c + const Offset(120, 0),
          1.0,
          ease: EasingType.easeOut,
        );
        break;
      case DemoFeature.moveBy:
        Animations.moveBy(
          char,
          const Offset(120, 0),
          1.0,
          ease: EasingType.easeInOut,
        );
        break;
      case DemoFeature.rotateTo:
        char.rotation = 400;
        // Animations.rotateTo(char, 160, 0.8, ease: EasingType.easeInOut);
        break;
      case DemoFeature.scaleTo:
        Animations.scaleTo(
          char,
          const Offset(1.6, 1.6),
          0.8,
          ease: EasingType.easeInOut,
        );
        break;
      case DemoFeature.resize:
        Animations.resize(
          char,
          const Size(96, 96),
          0.8,
          ease: EasingType.easeInOut,
        );
        break;
      case DemoFeature.fadeIn:
        char.opacity = 0.0;
        Animations.fadeIn(char, 0.8, ease: EasingType.easeOut);
        break;
      case DemoFeature.fadeOut:
        char.opacity = 1.0;
        Animations.fadeOut(char, 0.8, ease: EasingType.easeIn);
        break;
      case DemoFeature.colorTo:
        Animations.colorTo(
          char,
          const Color(0xFFFF6A00),
          0.8,
          ease: EasingType.easeInOut,
        );
        break;
      case DemoFeature.blink:
        Animations.blink(char, const Color(0xFFFF3366), 8.0, 1.5);
        break;
      case DemoFeature.sequence:
        final s1 = Animations.moveBy(
          char,
          const Offset(80, 0),
          0.4,
          ease: EasingType.easeInOut,
        );
        final s2 = Animations.moveBy(
          char,
          const Offset(-80, 0),
          0.4,
          ease: EasingType.easeInOut,
        );
        Animations.sequence([s1, s2], char);
        break;
      case DemoFeature.parallel:
        final a = Animations.rotateTo(
          char,
          0.8,
          0.6,
          ease: EasingType.easeInOut,
        );
        final b = Animations.colorTo(
          char,
          const Color(0xFF55CCFF),
          0.6,
          ease: EasingType.easeInOut,
        );
        Animations.parallel([a, b], char);
        break;
      case DemoFeature.repeat:
        final mv = Animations.moveBy(
          char,
          const Offset(80, 0),
          0.4,
          ease: EasingType.easeInOut,
        );
        Animations.repeat(mv, count: 3);
        break;
      case DemoFeature.forever:
        final mvF = Animations.moveBy(
          char,
          const Offset(0, -60),
          0.5,
          ease: EasingType.easeInOut,
        );
        Animations.forever(mvF);
        break;
      case DemoFeature.shake:
        Animations.shake(char, 14.0, 0.8);
        break;
      case DemoFeature.pulse:
        Animations.pulse(char, 1.3, 0.8, repeat: 2);
        break;
      case DemoFeature.wiggle:
        Animations.wiggle(char, 0.35, 3.0, 1.2);
        break;
      case DemoFeature.pathFollow:
        final path = <Offset>[
          c + const Offset(-80, 0),
          c + const Offset(0, -80),
          c + const Offset(80, 0),
          c + const Offset(0, 80),
          c + const Offset(-80, 0),
        ];
        Animations.pathFollow(char, path, 2.0, ease: EasingType.easeInOut);
        break;
      case DemoFeature.custom:
        Animations.custom(
          char,
          1.2,
          ease: EasingType.linear,
          onUpdate: (t) {
            char.opacity = 0.5 + 0.5 * (1 - (t - 0.5).abs() * 2);
            char.scale =
                const Offset(1, 1) * (1 + 0.3 * (1 - (t - 0.5).abs() * 2));
          },
        );
        break;
    }
  }

  // API pública para UI do playground
  void setFeature(DemoFeature feature) {
    currentFeature = feature;
    _playCurrent();
    SceneManager.instance.current?.camera.focusOn(char);
  }

  void restartFeature() {
    _playCurrent();
    SceneManager.instance.current?.camera.focusOn(char);
  }

  @override
  void render(Canvas canvas, {Size? canvasSize, Viewport? viewport}) {
    // Pintar fundo escuro
    final size = canvasSize ?? const Size(1024, 768);
    final paint = Paint()..color = const Color(0xFF0F0F12);
    canvas.drawRect(Offset.zero & size, paint);
    super.render(canvas, canvasSize: canvasSize, viewport: viewport);
  }
}
