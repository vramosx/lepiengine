import 'dart:ui';
import 'game_object.dart';

// Helpers de vetor para Offsets
extension _OffsetVectorUtils on Offset {
  Offset normalized() {
    final double len = distance;
    if (len == 0) return const Offset(0, 0);
    return this / len;
  }
}

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

/// Lado da colisão relativo ao objeto que recebe o evento/correção
enum CollisionSide { top, bottom, left, right, unknown }

/// Informações detalhadas sobre uma colisão
class CollisionInfo {
  const CollisionInfo({
    required this.other,
    required this.intersectionPoint,
    required this.normal,
    required this.penetrationDepth,
    required this.isEntering,
    this.selfSide = CollisionSide.unknown,
    this.otherSide = CollisionSide.unknown,
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

  /// Lado do objeto (que recebe o evento) onde ocorreu o contato
  final CollisionSide selfSide;

  /// Lado do outro objeto envolvido (oposto de selfSide)
  final CollisionSide otherSide;
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
    // Alinha o ponto de ancoragem do collider ao ponto correspondente
    // dentro do GameObject. Assim, por exemplo, um collider com
    // anchor bottomCenter ficará preso ao bottomCenter do objeto.
    final Offset attachPointInLocal = Offset(
      gameObject.size.width * anchorOffset.dx,
      gameObject.size.height * anchorOffset.dy,
    );

    // IMPORTANTE: o offset deve estar no espaço LOCAL para que seja
    // afetado por rotação/escala do GameObject. Antes, somávamos o
    // offset em world space, o que fazia o collider não acompanhar a
    // rotação do objeto. Ao transformar (attachPointInLocal + offset)
    // para o mundo, garantimos que o deslocamento rode junto.
    final Offset worldPos = gameObject.localToWorld(
      attachPointInLocal + offset,
    );
    return worldPos;
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
    // Calcula os 4 cantos NO ESPAÇO LOCAL do GameObject,
    // aplicando o deslocamento relativo e o anchor do collider.
    final anchorPos = anchorOffset;
    final Offset localAnchorPoint =
        Offset(
          gameObject.size.width * anchorPos.dx,
          gameObject.size.height * anchorPos.dy,
        ) +
        offset; // offset em espaço local

    final double leftLocal = -size.width * anchorPos.dx;
    final double topLocal = -size.height * anchorPos.dy;

    final List<Offset> localCorners = <Offset>[
      Offset(leftLocal, topLocal),
      Offset(leftLocal + size.width, topLocal),
      Offset(leftLocal, topLocal + size.height),
      Offset(leftLocal + size.width, topLocal + size.height),
    ].map((c) => localAnchorPoint + c).toList();

    // Transforma os cantos para o mundo considerando rotação/escala do GameObject.
    final List<Offset> worldCorners = localCorners
        .map(gameObject.localToWorld)
        .toList();

    double minX = worldCorners.first.dx;
    double maxX = worldCorners.first.dx;
    double minY = worldCorners.first.dy;
    double maxY = worldCorners.first.dy;

    for (final c in worldCorners.skip(1)) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Retorna os 4 cantos no mundo na ordem:
  /// topLeft, topRight, bottomRight, bottomLeft.
  List<Offset> getWorldCorners() {
    final anchorPos = anchorOffset;
    final Offset localAnchorPoint =
        Offset(
          gameObject.size.width * anchorPos.dx,
          gameObject.size.height * anchorPos.dy,
        ) +
        offset;

    final double leftLocal = -size.width * anchorPos.dx;
    final double topLocal = -size.height * anchorPos.dy;

    final List<Offset> localCorners = <Offset>[
      Offset(leftLocal, topLocal),
      Offset(leftLocal + size.width, topLocal),
      Offset(leftLocal + size.width, topLocal + size.height),
      Offset(leftLocal, topLocal + size.height),
    ].map((c) => localAnchorPoint + c).toList();

    return localCorners.map(gameObject.localToWorld).toList();
  }

  Offset _polygonCenter(List<Offset> pts) {
    double sx = 0;
    double sy = 0;
    for (final p in pts) {
      sx += p.dx;
      sy += p.dy;
    }
    final int n = pts.length;
    return Offset(sx / n, sy / n);
  }

  // Projeta um conjunto de pontos no eixo e retorna min/max escalares
  (double, double) _projectOntoAxis(List<Offset> pts, Offset axis) {
    final double ax = axis.dx;
    final double ay = axis.dy;
    double min = pts.first.dx * ax + pts.first.dy * ay;
    double max = min;
    for (final p in pts.skip(1)) {
      final double proj = p.dx * ax + p.dy * ay;
      if (proj < min) min = proj;
      if (proj > max) max = proj;
    }
    return (min, max);
  }

  // Calcula colisão OBB x OBB via SAT. Retorna par (penetração, normal)
  (double, Offset)? _satOBB(List<Offset> a, List<Offset> b) {
    final List<Offset> axes = <Offset>[
      (a[1] - a[0]).normalized(),
      (a[3] - a[0]).normalized(),
      (b[1] - b[0]).normalized(),
      (b[3] - b[0]).normalized(),
    ];

    double minOverlap = double.infinity;
    Offset bestAxis = const Offset(0, 0);

    for (final axis in axes) {
      final (double amin, double amax) = _projectOntoAxis(a, axis);
      final (double bmin, double bmax) = _projectOntoAxis(b, axis);
      final double overlap = _intervalOverlap(amin, amax, bmin, bmax);
      if (overlap <= 0) return null; // eixo separador encontrado
      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    // Orienta a normal para mover A PARA LONGE de B (B → A)
    final Offset centerA = _polygonCenter(a);
    final Offset centerB = _polygonCenter(b);
    final Offset directionAB = (centerB - centerA);
    final double dot =
        directionAB.dx * bestAxis.dx + directionAB.dy * bestAxis.dy;
    // Se bestAxis aponta na mesma direção de A→B (dot > 0), inverta
    if (dot > 0) bestAxis = Offset(-bestAxis.dx, -bestAxis.dy);

    return (minOverlap, bestAxis);
  }

  double _intervalOverlap(double amin, double amax, double bmin, double bmax) {
    final double left = (amax < bmax) ? amax : bmax;
    final double right = (amin > bmin) ? amin : bmin;
    return left - right;
  }

  @override
  bool intersects(Collider other) {
    if (other is AABBCollider) {
      final List<Offset> a = getWorldCorners();
      final List<Offset> b = other.getWorldCorners();
      return _satOBB(a, b) != null;
    } else if (other is CircleCollider) {
      return other.intersects(this); // Delega para CircleCollider
    }
    return false;
  }

  @override
  CollisionInfo? getIntersection(Collider other) {
    if (!intersects(other)) return null;

    if (other is AABBCollider) {
      return _getOBBIntersection(other);
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

  CollisionInfo _getOBBIntersection(AABBCollider other) {
    final List<Offset> a = getWorldCorners();
    final List<Offset> b = other.getWorldCorners();
    final (double, Offset)? sat = _satOBB(a, b);
    // sat não será nulo aqui, pois já validamos intersects
    final double penetration = sat!.$1;
    final Offset normal = sat.$2;

    // Ponto de contato aproximado: centro entre os centros, ajustado pela normal
    final Offset centerA = _polygonCenter(a);
    final Offset centerB = _polygonCenter(b);
    final Offset contact = (centerA + centerB) / 2;

    return CollisionInfo(
      other: other,
      intersectionPoint: contact,
      normal: normal,
      penetrationDepth: penetration,
      isEntering: true,
    );
  }

  @override
  bool containsPoint(Offset worldPoint) {
    // Converte o ponto para o espaço local do GameObject e verifica
    // contra o retângulo local do collider (considerando anchor/offset).
    final anchorPos = anchorOffset;
    final Offset localAnchorPoint =
        Offset(
          gameObject.size.width * anchorPos.dx,
          gameObject.size.height * anchorPos.dy,
        ) +
        offset;

    final Offset lp = gameObject.worldToLocal(worldPoint) - localAnchorPoint;

    final double left = -size.width * anchorPos.dx;
    final double top = -size.height * anchorPos.dy;
    final double right = left + size.width;
    final double bottom = top + size.height;

    return lp.dx >= left && lp.dx <= right && lp.dy >= top && lp.dy <= bottom;
  }

  @override
  void debugRender(Canvas canvas) {
    final paint = Paint()
      ..color = debugColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Desenha o retângulo REAL (rotacionado) do collider para debug.
    final anchorPos = anchorOffset;
    final Offset localAnchorPoint =
        Offset(
          gameObject.size.width * anchorPos.dx,
          gameObject.size.height * anchorPos.dy,
        ) +
        offset;

    final double leftLocal = -size.width * anchorPos.dx;
    final double topLocal = -size.height * anchorPos.dy;

    final List<Offset> worldCorners = <Offset>[
      Offset(leftLocal, topLocal),
      Offset(leftLocal + size.width, topLocal),
      Offset(leftLocal + size.width, topLocal + size.height),
      Offset(leftLocal, topLocal + size.height),
    ].map((c) => gameObject.localToWorld(localAnchorPoint + c)).toList();

    final Path path = Path()
      ..moveTo(worldCorners[0].dx, worldCorners[0].dy)
      ..lineTo(worldCorners[1].dx, worldCorners[1].dy)
      ..lineTo(worldCorners[2].dx, worldCorners[2].dy)
      ..lineTo(worldCorners[3].dx, worldCorners[3].dy)
      ..close();
    canvas.drawPath(path, paint);

    // Também desenha o AABB resultante (útil para entender broad-phase)
    final Rect aabb = getAABB();
    final Paint aabbPaint = Paint()
      ..color = debugColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke;
    canvas.drawRect(aabb, aabbPaint);
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
      return _intersectsOBB(other);
    }
    return false;
  }

  bool _intersectsOBB(AABBCollider obb) {
    final List<Offset> corners = obb.getWorldCorners();
    final Offset c = worldCenter;

    // SAT contra eixos do OBB
    final List<Offset> axes = <Offset>[
      (corners[1] - corners[0]).normalized(),
      (corners[3] - corners[0]).normalized(),
    ];

    for (final axis in axes) {
      final (double min, double max) = obb._projectOntoAxis(corners, axis);
      final double centerProj = c.dx * axis.dx + c.dy * axis.dy;
      // Projeção do círculo é [centerProj - r, centerProj + r]
      final double overlap = obb._intervalOverlap(
        min,
        max,
        centerProj - radius,
        centerProj + radius,
      );
      if (overlap <= 0) return false;
    }
    // Também testa contra a direção para o vértice mais próximo (caso canto)
    final Offset closest = _closestPointOnPolygon(c, corners);
    return (c - closest).distance < radius;
  }

  Offset _closestPointOnSegment(Offset p, Offset a, Offset b) {
    final Offset ab = b - a;
    final double t =
        ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) /
        (ab.dx * ab.dx + ab.dy * ab.dy);
    final double clampedT = t.clamp(0.0, 1.0);
    return Offset(a.dx + ab.dx * clampedT, a.dy + ab.dy * clampedT);
  }

  Offset _closestPointOnPolygon(Offset p, List<Offset> poly) {
    Offset closest = poly[0];
    double minDist = (p - closest).distanceSquared;
    for (int i = 0; i < poly.length; i++) {
      final Offset a = poly[i];
      final Offset b = poly[(i + 1) % poly.length];
      final Offset q = _closestPointOnSegment(p, a, b);
      final double d = (p - q).distanceSquared;
      if (d < minDist) {
        minDist = d;
        closest = q;
      }
    }
    return closest;
  }

  @override
  CollisionInfo? getIntersection(Collider other) {
    if (!intersects(other)) return null;

    if (other is CircleCollider) {
      return _getCircleIntersection(other);
    } else if (other is AABBCollider) {
      return _getOBBIntersection(other);
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

  CollisionInfo _getOBBIntersection(AABBCollider obb) {
    final List<Offset> corners = obb.getWorldCorners();
    final Offset center = worldCenter;
    final Offset closest = _closestPointOnPolygon(center, corners);
    final double distance = (center - closest).distance;
    final double penetrationDepth = radius - distance;
    final Offset normal = distance > 0
        ? (center - closest) / distance
        : const Offset(0, -1);

    return CollisionInfo(
      other: obb,
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
