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

    // Área de destino (onde será desenhada na tela)
    final dstRect = position & size;

    // Salvar estado do canvas para aplicar transformações
    canvas.save();

    // Aplicar transformações de flip
    if (flipX || flipY) {
      final dx = flipX ? -1.0 : 1.0;
      final dy = flipY ? -1.0 : 1.0;

      // Translada para o centro, aplica flip, volta
      canvas.translate(dstRect.center.dx, dstRect.center.dy);
      canvas.scale(dx, dy);
      canvas.translate(-dstRect.center.dx, -dstRect.center.dy);
    }

    // Desenhar imagem
    canvas.drawImageRect(
      image,
      sourceRect ??
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dstRect,
      paint,
    );

    canvas.restore();
  }
}
