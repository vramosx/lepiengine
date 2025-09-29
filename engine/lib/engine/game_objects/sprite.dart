import 'dart:ui';
import '../core/game_object.dart';

/// GameObject especializado para renderizar imagens (sprites).
class Sprite extends GameObject {
  final Image image;
  Rect? sourceRect; // Parte da imagem a ser renderizada
  bool flipX;
  bool flipY;

  Sprite({
    required this.image,
    super.name,
    super.position,
    super.size,
    this.sourceRect,
    this.flipX = false,
    this.flipY = false,
    super.opacity = 1.0,
  });

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);

    // O canvas já está em espaço local do GameObject via renderTree (inclui anchor/pivô).
    // Desenhamos a imagem ocupando (0,0)-(w,h). Flip preserva posição visual.
    if (flipX || flipY) {
      if (flipX) canvas.translate(size.width, 0);
      if (flipY) canvas.translate(0, size.height);
      canvas.scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);
    }

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final srcRect =
        sourceRect ??
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }
}
