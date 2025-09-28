import 'dart:ui';

import 'package:lepiengine/engine/core/collision_manager.dart';

import '../core/game_object.dart';

/// Representa a posição de um frame em uma sprite sheet por coluna e linha
class Frame {
  final int col;
  final int row;

  Frame({required this.col, required this.row});
}

class SpriteAnimation {
  final String name;
  final double frameDuration; // tempo de cada frame em segundos
  final bool loop;
  final VoidCallback? onEnd;

  // Nova abordagem: tamanho do frame + posições por coluna/linha
  final Size? frameSize;
  final List<Frame>? frames;

  // Abordagem original: Rects diretamente
  final List<Rect>? framesRect;

  // Cache dos Rects calculados
  late final List<Rect> _calculatedFrames;

  SpriteAnimation({
    required this.name,
    this.frameSize,
    this.frames,
    this.framesRect,
    this.frameDuration = 0.1,
    this.loop = true,
    this.onEnd,
  }) {
    // Validação: uma das duas abordagens deve estar preenchida
    if ((frameSize == null || frames == null) && framesRect == null) {
      throw ArgumentError(
        'Deve fornecer frameSize + frames OU framesRect para criar uma animação',
      );
    }

    if ((frameSize != null && frames != null) && framesRect != null) {
      throw ArgumentError(
        'Forneça apenas uma abordagem: frameSize + frames OU framesRect',
      );
    }

    // Calcula os Rects baseado na abordagem escolhida
    _calculatedFrames = _calculateFrames();
  }

  List<Rect> _calculateFrames() {
    if (framesRect != null) {
      return framesRect!;
    }

    if (frameSize != null && frames != null) {
      return frames!.map((frame) {
        final left = frame.col * frameSize!.width;
        final top = frame.row * frameSize!.height;
        return Rect.fromLTWH(left, top, frameSize!.width, frameSize!.height);
      }).toList();
    }

    throw StateError('Estado inválido: nenhuma abordagem válida encontrada');
  }

  /// Retorna os frames calculados (seja por Rect direto ou por coluna/linha)
  List<Rect> get calculatedFrames => _calculatedFrames;
}

class SpriteSheet extends GameObject {
  final Image image;
  final Map<String, SpriteAnimation> animations = {};
  SpriteAnimation? _currentAnimation;

  double _time = 0.0;
  int _currentFrame = 0;
  bool _animationEnded = false;
  bool flipX = false;
  bool flipY = false;
  SpriteAnimation? get currentAnimation => _currentAnimation;

  SpriteSheet({required this.image, super.name, super.position, super.size});

  /// Adiciona uma animação
  void addAnimation(SpriteAnimation animation) {
    animations[animation.name] = animation;
  }

  /// Executa uma animação pelo nome
  void play(String name) {
    if (_currentAnimation?.name == name) return;

    _currentAnimation = animations[name];
    _time = 0.0;
    _currentFrame = 0;
    _animationEnded = false;
  }

  void onAnimationEnd() {
    _animationEnded = true;
    _currentAnimation!.onEnd?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_currentAnimation == null) return;

    if (_animationEnded) return; // já terminou, não avança mais

    _time += dt;
    if (_time >= _currentAnimation!.frameDuration) {
      _time = 0.0;
      _currentFrame++;

      if (_currentFrame >= _currentAnimation!.calculatedFrames.length) {
        if (_currentAnimation!.loop) {
          _currentFrame = 0;
        } else {
          _currentFrame = _currentAnimation!.calculatedFrames.length - 1;
          onAnimationEnd();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible || _currentAnimation == null) return;

    final frameRect = _currentAnimation!.calculatedFrames[_currentFrame];

    final paint = Paint();

    // Usa o sistema de coordenadas local do GameObject (0,0 com anchor aplicado)
    // O canvas já está transformado pela renderTree() do GameObject
    final left = flipX
        ? (size.width * anchor.dx - size.width)
        : -size.width * anchor.dx;
    final top = flipY ? size.height * anchor.dy : -size.height * anchor.dy;
    final dstRect = Rect.fromLTWH(left, top, size.width, size.height);

    if (flipX || flipY) {
      final dx = flipX ? -1.0 : 1.0;
      final dy = flipY ? -1.0 : 1.0;
      canvas.scale(dx, dy);
    }

    canvas.drawImageRect(image, frameRect, dstRect, paint);
  }
}

class SpriteSheetWithCollider extends SpriteSheet with CollisionCallbacks {
  SpriteSheetWithCollider({
    required super.image,
    super.name,
    super.position,
    super.size,
  });
}
