import 'dart:ui';
import 'game_object.dart';

/// Tipos de anchor para colliders
enum ColliderAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Informações detalhadas sobre uma colisão
class CollisionInfo {
  const CollisionInfo({
    required this.other,
    required this.intersectionPoint,
    required this.normal,
    required this.penetrationDepth,
    required this.isEntering,
  });

  /// O outro collider envolvido na colisão
  final Collider other;

  /// Ponto de intersecção no espaço do mundo
  final Offset intersectionPoint;

  /// Normal da colisão (direção para resolver a penetração)
  final Offset normal;

  /// Profundidade da penetração
  final double penetrationDepth;

  /// Se esta é uma colisão de entrada (true) ou saída (false)
  final bool isEntering;
}

/// Base abstrata para todos os tipos de collider
abstract class Collider {
  Collider({
    required this.gameObject,
    this.offset = Offset.zero,
    this.anchor = ColliderAnchor.center,
    this.isTrigger = false,
    this.isStatic = false,
    this.debugColor = const Color(0xFF00FF00), // Verde por padrão
  });

  /// GameObject ao qual este collider está anexado
  final GameObject gameObject;

  /// Deslocamento relativo à posição do GameObject
  final Offset offset;

  /// Ponto de referência do collider
  final ColliderAnchor anchor;

  /// Se true, não bloqueia fisicamente, apenas dispara eventos
  final bool isTrigger;

  /// Se true, é tratado como estático (otimização de performance)
  final bool isStatic;

  /// Cor para visualização em debug
  final Color debugColor;

  /// Retorna a posição do collider no mundo
  Offset get worldPosition {
    final gameObjectPos = gameObject.localToWorld(Offset.zero);
    return gameObjectPos + offset;
  }

  /// Converte anchor enum para offset (0..1)
  Offset get anchorOffset {
    switch (anchor) {
      case ColliderAnchor.topLeft:
        return const Offset(0, 0);
      case ColliderAnchor.topCenter:
        return const Offset(0.5, 0);
      case ColliderAnchor.topRight:
        return const Offset(1, 0);
      case ColliderAnchor.centerLeft:
        return const Offset(0, 0.5);
      case ColliderAnchor.center:
        return const Offset(0.5, 0.5);
      case ColliderAnchor.centerRight:
        return const Offset(1, 0.5);
      case ColliderAnchor.bottomLeft:
        return const Offset(0, 1);
      case ColliderAnchor.bottomCenter:
        return const Offset(0.5, 1);
      case ColliderAnchor.bottomRight:
        return const Offset(1, 1);
    }
  }

  /// Verifica se há intersecção com outro collider
  bool intersects(Collider other);

  /// Retorna informações detalhadas da colisão, se houver
  CollisionInfo? getIntersection(Collider other);

  /// Retorna o AABB (Axis-Aligned Bounding Box) do collider no mundo
  Rect getAABB();

  /// Desenha o collider para debug
  void debugRender(Canvas canvas);

  /// Verifica se um ponto está dentro do collider
  bool containsPoint(Offset worldPoint);
}

/// Collider retangular alinhado aos eixos (AABB)
class AABBCollider extends Collider {
  AABBCollider({
    required super.gameObject,
    required this.size,
    super.offset,
    super.anchor,
    super.isTrigger,
    super.isStatic,
    super.debugColor,
  });

  /// Tamanho do collider
  final Size size;

  @override
  Rect getAABB() {
    final pos = worldPosition;
    final anchorPos = anchorOffset;

    // if (size.width == 48) {
    //   print('AABB Debug: size.width: ${size.width}');
    // }

    final left = pos.dx - (size.width * anchorPos.dx);
    final top = pos.dy - (size.height * anchorPos.dy);

    return Rect.fromLTWH(left, top, size.width, size.height);
  }

  @override
  bool intersects(Collider other) {
    if (other is AABBCollider) {
      return getAABB().overlaps(other.getAABB());
    } else if (other is CircleCollider) {
      return other.intersects(this); // Delega para CircleCollider
    }
    return false;
  }

  @override
  CollisionInfo? getIntersection(Collider other) {
    if (!intersects(other)) return null;

    if (other is AABBCollider) {
      return _getAABBIntersection(other);
    } else if (other is CircleCollider) {
      final circleInfo = other.getIntersection(this);
      if (circleInfo == null) return null;

      // Inverte a normal para manter a perspectiva correta
      return CollisionInfo(
        other: this,
        intersectionPoint: circleInfo.intersectionPoint,
        normal: Offset(-circleInfo.normal.dx, -circleInfo.normal.dy),
        penetrationDepth: circleInfo.penetrationDepth,
        isEntering: circleInfo.isEntering,
      );
    }
    return null;
  }

  CollisionInfo _getAABBIntersection(AABBCollider other) {
    final rect1 = getAABB();
    final rect2 = other.getAABB();

    // print('AABB Debug: rect1 (${gameObject.runtimeType}): $rect1');
    // print('AABB Debug: rect2 (${other.gameObject.runtimeType}): $rect2');

    final intersection = rect1.intersect(rect2);

    // Calcula a normal baseada na menor sobreposição
    final overlapX = intersection.width;
    final overlapY = intersection.height;

    // print('AABB Debug: overlapX: $overlapX, overlapY: $overlapY');

    final Offset normal;
    final double penetrationDepth;

    // CORREÇÃO: Para plataformas, priorize separação vertical se há overlap significativo
    final hasVerticalOverlap = overlapY > 5.0; // Threshold mínimo

    if (hasVerticalOverlap) {
      // Prioriza separação VERTICAL para plataformas
      penetrationDepth = overlapY;
      normal = const Offset(0, -1); // Empurra para cima
      // print(
      //   'AABB Debug: PLATAFORMA - Separação VERTICAL forçada, normal: $normal',
      // );
    } else if (overlapX < overlapY) {
      // Separação horizontal (lógica original)
      penetrationDepth = overlapX;
      if (rect1.center.dx < rect2.center.dx) {
        normal = const Offset(-1, 0); // Empurra para a esquerda
      } else {
        normal = const Offset(1, 0); // Empurra para a direita
      }
      // print(
      //   'AABB Debug: Separação HORIZONTAL (menor overlap), normal: $normal',
      // );
    } else {
      // Separação vertical (lógica original)
      penetrationDepth = overlapY;
      if (rect1.center.dy < rect2.center.dy) {
        normal = const Offset(0, -1); // Empurra para cima
      } else {
        normal = const Offset(0, 1); // Empurra para baixo
      }
      // print('AABB Debug: Separação VERTICAL (menor overlap), normal: $normal');
    }

    return CollisionInfo(
      other: other,
      intersectionPoint: intersection.center,
      normal: normal,
      penetrationDepth: penetrationDepth,
      isEntering: true, // Será determinado pelo CollisionManager
    );
  }

  @override
  bool containsPoint(Offset worldPoint) {
    return getAABB().contains(worldPoint);
  }

  @override
  void debugRender(Canvas canvas) {
    final rect = getAABB();
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, paint);

    // Desenha um ponto no centro para indicar a posição
    final centerPaint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(rect.center, 2.0, centerPaint);
  }
}

/// Collider circular
class CircleCollider extends Collider {
  CircleCollider({
    required super.gameObject,
    required this.radius,
    super.offset,
    super.anchor,
    super.isTrigger,
    super.isStatic,
    super.debugColor,
  });

  /// Raio do círculo
  final double radius;

  /// Retorna o centro do círculo no mundo
  Offset get worldCenter {
    final pos = worldPosition;
    final anchorPos = anchorOffset;

    // Para círculos, o anchor afeta o centro
    final diameter = radius * 2;
    return Offset(
      pos.dx - (diameter * anchorPos.dx) + radius,
      pos.dy - (diameter * anchorPos.dy) + radius,
    );
  }

  @override
  Rect getAABB() {
    final center = worldCenter;
    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool intersects(Collider other) {
    if (other is CircleCollider) {
      final distance = (worldCenter - other.worldCenter).distance;
      return distance < (radius + other.radius);
    } else if (other is AABBCollider) {
      return _intersectsAABB(other);
    }
    return false;
  }

  bool _intersectsAABB(AABBCollider aabb) {
    final rect = aabb.getAABB();
    final center = worldCenter;

    // Encontra o ponto mais próximo no retângulo
    final closestX = center.dx.clamp(rect.left, rect.right);
    final closestY = center.dy.clamp(rect.top, rect.bottom);
    final closest = Offset(closestX, closestY);

    // Verifica se a distância é menor que o raio
    final distance = (center - closest).distance;
    return distance < radius;
  }

  @override
  CollisionInfo? getIntersection(Collider other) {
    if (!intersects(other)) return null;

    if (other is CircleCollider) {
      return _getCircleIntersection(other);
    } else if (other is AABBCollider) {
      return _getAABBIntersection(other);
    }
    return null;
  }

  CollisionInfo _getCircleIntersection(CircleCollider other) {
    final center1 = worldCenter;
    final center2 = other.worldCenter;
    final distance = (center2 - center1).distance;

    final penetrationDepth = (radius + other.radius) - distance;
    final direction = (center2 - center1) / distance;

    // Ponto de intersecção no meio da sobreposição
    final intersectionPoint =
        center1 + (direction * (radius - penetrationDepth / 2));

    return CollisionInfo(
      other: other,
      intersectionPoint: intersectionPoint,
      normal: -direction, // Normal aponta para longe do outro círculo
      penetrationDepth: penetrationDepth,
      isEntering: true,
    );
  }

  CollisionInfo _getAABBIntersection(AABBCollider aabb) {
    final rect = aabb.getAABB();
    final center = worldCenter;

    // Encontra o ponto mais próximo no retângulo
    final closestX = center.dx.clamp(rect.left, rect.right);
    final closestY = center.dy.clamp(rect.top, rect.bottom);
    final closest = Offset(closestX, closestY);

    final distance = (center - closest).distance;
    final penetrationDepth = radius - distance;

    // Normal aponta do ponto mais próximo para o centro do círculo
    final normal = distance > 0
        ? (center - closest) / distance
        : const Offset(0, -1);

    return CollisionInfo(
      other: aabb,
      intersectionPoint: closest,
      normal: normal,
      penetrationDepth: penetrationDepth,
      isEntering: true,
    );
  }

  @override
  bool containsPoint(Offset worldPoint) {
    final distance = (worldPoint - worldCenter).distance;
    return distance <= radius;
  }

  @override
  void debugRender(Canvas canvas) {
    final center = worldCenter;
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, paint);

    // Desenha um ponto no centro
    final centerPaint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, centerPaint);
  }
}
