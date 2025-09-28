import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:lepiengine/main.dart';

class EngineStart extends Scene {
  EngineStart(this.initialScene, {super.name = 'EngineStart'}) : super();
  final String initialScene;

  @override
  void onEnter() {
    super.onEnter();

    _loadScene();
  }

  Future<void> _loadScene() async {
    final data = await rootBundle.load(
      "packages/lepiengine/assets/images/Lepi.png",
    );
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final lepiLogo = LepiLogo(image: frame.image);

    add(lepiLogo);
    _startAnimation(lepiLogo);

    camera.focusOn(lepiLogo);
  }

  void _startAnimation(LepiLogo lepiLogo) {
    Animations.fadeIn(lepiLogo, 1.0, ease: EasingType.easeOut);
    Animations.moveTo(lepiLogo, const Offset(0, -10), 1.0);
    Animations.resize(lepiLogo, const Size(120, 70), 1.0);

    Future.delayed(const Duration(seconds: 2), () {
      Animations.fadeOut(
        lepiLogo,
        1.0,
        ease: EasingType.easeIn,
        onComplete: () {
          SceneManager.instance.setScene(initialScene);
        },
      );
    });
  }
}

class LepiLogo extends Sprite {
  LepiLogo({required super.image}) : super() {
    size = const Size(100, 70);
    position = const Offset(0, 0);
    anchor = const Offset(0.5, 0.5);
    opacity = 0.0;
  }
}
