import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'collider.dart';

/// Camada/layer simples para ordenação (pode evoluir para enum + parallax)
typedef ZIndex = double;

/// Base de todo elemento renderizável/atualizável do jogo.
abstract class GameObject {
  GameObject({
    this.name,
    Offset? position,
    this.rotation = 0.0,
    Offset? scale,
    this.anchor = const Offset(0, 0),
    this.size = Size.zero,
    this.visible = true,
    this.zIndex = 0.0,
    this.opacity = 1.0,
    this.active = true,
  }) : position = position ?? Offset.zero,
       scale = scale ?? const Offset(1, 1);

  // Identificação/organização
  final String? name;

  // Transform local
  Offset position;
  double rotation; // em radianos
  Offset scale;

  /// Anchor/pivô (0..1) relativo ao retângulo local do objeto (0,0 top-left; 0.5,0.5 centro)
  Offset anchor;

  /// Tamanho "lógico" do objeto (usado para bounds/hitTest desenhando shapes/sprites)
  Size size;

  // Aparência/estado
  bool visible;
  bool active;
  ZIndex zIndex;
  double opacity; // 0..1 (compõe com a pintura do filho)

  // Hierarquia
  GameObject? _parent;
  final List<GameObject> _children = <GameObject>[];

  GameObject? get parent => _parent;
  List<GameObject> get children => List.unmodifiable(_children);

  // Sistema de colisão
  final List<Collider> _colliders = <Collider>[];
  List<Collider> get colliders => List.unmodifiable(_colliders);

  /// Retorna o bounds (AABB) no espaço local.
  Rect get bounds => position & size;

  /// Ciclo de vida: chamado quando adicionado como filho a outro GameObject ou cena.
  void onAdd() {}

  /// Ciclo de vida: chamado quando removido.
  void onRemove() {}

  /// Atualiza lógica do objeto (override conforme necessário).
  void update(double dt) {
    // default: propaga para filhos
    for (final c in _children) {
      if (c.active) c.update(dt);
    }
  }

  /// Renderização do objeto (apenas o próprio). Use tamanho/anchor/transform.
  /// Dica: desenhe no espaço local com origem (0,0) e use `size` para limites.
  void render(Canvas canvas);

  /// Renderiza este objeto + filhos, já aplicando a transformação local.
  void renderTree(Canvas canvas) {
    if (!visible) return;

    canvas.save();

    // Aplica transformação local: translate -> rotate -> scale -> anchor
    // 1) mover para posição global
    canvas.translate(position.dx, position.dy);
    // 2) rotação
    if (rotation != 0) {
      canvas.rotate(rotation);
    }
    // 3) escala
    if (scale.dx != 1 || scale.dy != 1) {
      canvas.scale(scale.dx, scale.dy);
    }
    // 4) compensar âncora (leva (0,0) para o pivô)
    if (size != Size.zero) {
      final Offset pivot = Offset(
        size.width * anchor.dx,
        size.height * anchor.dy,
      );
      canvas.translate(-pivot.dx, -pivot.dy);
    }

    // Aplica opacidade local via layer se necessário
    if (opacity < 1.0) {
      final Paint p = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
      canvas.saveLayer(null, p);
      render(canvas);
      // filhos
      for (final c in _childrenSorted()) {
        c.renderTree(canvas);
      }
      canvas.restore();
    } else {
      render(canvas);
      for (final c in _childrenSorted()) {
        c.renderTree(canvas);
      }
    }

    canvas.restore();
  }

  /// Ordena filhos por zIndex (estável). Pode otimizar com dirty flag no futuro.
  Iterable<GameObject> _childrenSorted() sync* {
    final list = _children.toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    yield* list;
  }

  /// Adiciona filho e dispara onAdd.
  void addChild(GameObject child) {
    assert(child._parent == null, 'O objeto já possui um pai.');
    child._parent = this;
    _children.add(child);
    child.onAdd();
  }

  /// Remove filho e dispara onRemove.
  void removeChild(GameObject child) {
    final removed = _children.remove(child);
    if (removed) {
      child._parent = null;
      child.onRemove();
    }
  }

  /// Remove todos os filhos.
  void clearChildren() {
    for (final c in _children) {
      c._parent = null;
      c.onRemove();
    }
    _children.clear();
  }

  /// Converte um ponto do espaço local para o espaço do mundo (world space).
  Offset localToWorld(Offset localPoint) {
    // Acumula transformações subindo a hierarquia.
    final matrix = _accumulateTransform();
    final Float64List m = matrix;
    final double x = localPoint.dx;
    final double y = localPoint.dy;
    final double tx = m[0] * x + m[4] * y + m[12];
    final double ty = m[1] * x + m[5] * y + m[13];
    return Offset(tx, ty);
  }

  /// Converte um ponto do mundo para o espaço local deste objeto.
  Offset worldToLocal(Offset worldPoint) {
    final m = _accumulateTransform();
    final Matrix4 mat = Matrix4.fromFloat64List(m);
    final Matrix4 inv = Matrix4.inverted(mat);
    final Float64List i = inv.storage;
    final double x = worldPoint.dx;
    final double y = worldPoint.dy;
    final double lx = i[0] * x + i[4] * y + i[12];
    final double ly = i[1] * x + i[5] * y + i[13];
    return Offset(lx, ly);
  }

  /// Hit test básico no espaço local (retângulo do size).
  bool hitTest(Offset worldPoint) {
    if (size == Size.zero) return false;
    final lp = worldToLocal(worldPoint);

    // Calcula o retângulo local considerando o anchor
    final double left = -size.width * anchor.dx;
    final double top = -size.height * anchor.dy;
    final double right = left + size.width;
    final double bottom = top + size.height;

    return Rect.fromLTRB(left, top, right, bottom).contains(lp);
  }

  /// Retorna os bounds (AABB) no mundo (útil para debug/colisão AABB simples).
  Rect worldAABB() {
    if (size == Size.zero) return Rect.zero;
    // Quatro cantos locais
    final corners = <Offset>[
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map(localToWorld).toList();

    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;

    for (final c in corners.skip(1)) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Monta a matriz acumulada (parent → ... → this).
  Float64List _accumulateTransform() {
    Matrix4 m = Matrix4.identity();
    final chain = <GameObject>[];
    GameObject? cursor = this;

    // Sobe a árvore (this por último para aplicação em ordem)
    while (cursor != null) {
      chain.add(cursor);
      cursor = cursor._parent;
    }
    // Aplica do root para o leaf
    for (final node in chain.reversed) {
      // translate (posição)
      m = m..translate(node.position.dx, node.position.dy);
      // rotate
      if (node.rotation != 0) m = m..rotateZ(node.rotation);
      // scale
      if (node.scale.dx != 1 || node.scale.dy != 1) {
        m = m..scale(node.scale.dx, node.scale.dy, 1.0);
      }
      // anchor: desloca pivô
      if (node.size != Size.zero) {
        final px = node.size.width * node.anchor.dx;
        final py = node.size.height * node.anchor.dy;
        m = m..translate(-px, -py);
      }
    }
    return m.storage;
  }

  // ---- Métodos de Collider ----

  /// Adiciona um collider ao GameObject
  void addCollider(Collider collider) {
    _colliders.add(collider);
  }

  /// Remove um collider do GameObject
  bool removeCollider(Collider collider) {
    return _colliders.remove(collider);
  }

  /// Remove todos os colliders
  void clearColliders() {
    _colliders.clear();
  }

  /// Cria e adiciona um AABBCollider
  AABBCollider addAABBCollider({
    required Size size,
    Offset offset = Offset.zero,
    ColliderAnchor anchor = ColliderAnchor.center,
    bool isTrigger = false,
    bool isStatic = false,
    Color debugColor = const Color(0xFF00FF00),
  }) {
    final collider = AABBCollider(
      gameObject: this,
      size: size,
      offset: offset,
      anchor: anchor,
      isTrigger: isTrigger,
      isStatic: isStatic,
      debugColor: debugColor,
    );
    addCollider(collider);
    return collider;
  }

  /// Cria e adiciona um CircleCollider
  CircleCollider addCircleCollider({
    required double radius,
    Offset offset = Offset.zero,
    ColliderAnchor anchor = ColliderAnchor.center,
    bool isTrigger = false,
    bool isStatic = false,
    Color debugColor = const Color(0xFF00FF00),
  }) {
    final collider = CircleCollider(
      gameObject: this,
      radius: radius,
      offset: offset,
      anchor: anchor,
      isTrigger: isTrigger,
      isStatic: isStatic,
      debugColor: debugColor,
    );
    addCollider(collider);
    return collider;
  }

  /// Retorna o primeiro collider de um tipo específico
  T? getCollider<T extends Collider>() {
    for (final collider in _colliders) {
      if (collider is T) return collider;
    }
    return null;
  }

  /// Retorna todos os colliders de um tipo específico
  List<T> getColliders<T extends Collider>() {
    return _colliders.whereType<T>().toList();
  }
}

/* ============================================================
 * Mixins (capabilities) — para “plugar” quando precisar
 * ============================================================*/

/// Colisão básica por AABB. O Scene/CollisionSystem chamará os callbacks.
/// DEPRECATED: Use CollisionCallbacks mixin do collision_manager.dart
@Deprecated('Use CollisionCallbacks mixin do collision_manager.dart')
mixin Collidable on GameObject {
  // Você pode expor tipos diferentes de collider no futuro.
  Rect get aabb => worldAABB();

  void onCollisionEnter(GameObject other) {}
  void onCollisionStay(GameObject other) {}
  void onCollisionExit(GameObject other) {}
}

/// Input por toque/clique — o Scene/InputSystem chamará hitTest e eventos.
mixin Touchable on GameObject {
  bool onTapDown(Offset localPos, Offset globalPos) => false;
  bool onTapUp(Offset localPos, Offset globalPos) => false;
  bool onTapCancel() => false;
  bool onDragStart(Offset localPos, Offset globalPos) => false;
  bool onDragUpdate(Offset localPos, Offset globalPos) => false;
  bool onDragEnd(Offset localPos, Offset globalPos, Offset velocity) => false;
}

/// Teclado — útil para desktop/web. Integraremos depois no InputSystem.
mixin KeyboardControllable on GameObject {
  void onKeyDown(Object key) {}
  void onKeyUp(Object key) {}
}

/// Física básica genérica - fornece apenas os fundamentos
mixin PhysicsBody on GameObject {
  // Propriedades básicas de física (configuráveis)
  double gravity = 800.0;
  double maxFallSpeed = 500.0;

  // Estado interno básico
  Offset _velocity = Offset.zero;

  // API pública da engine
  Offset get velocity => _velocity;
  void setVelocity(Offset newVelocity) => _velocity = newVelocity;
  void addVelocity(Offset deltaVelocity) => _velocity += deltaVelocity;

  // Física básica (chamada automaticamente pela Scene)
  void updatePhysics(double dt) {
    // Aplica gravidade
    _velocity = Offset(_velocity.dx, _velocity.dy + gravity * dt);

    // Limita velocidade de queda
    if (_velocity.dy > maxFallSpeed) {
      _velocity = Offset(_velocity.dx, maxFallSpeed);
    }

    // Aplica movimento
    position += _velocity * dt;
  }

  // Resolução automática de colisão (chamada pelo CollisionManager)
  void resolveCollision(GameObject other, CollisionInfo collision) {
    if (collision.other.isTrigger) return; // Triggers não resolvem física

    final normal = collision.normal;
    final penetration = collision.penetrationDepth;

    // Ignora penetrações muito pequenas
    if (penetration < 0.1) return;

    // Resolve penetração
    position = Offset(
      position.dx + normal.dx * penetration,
      position.dy + normal.dy * penetration,
    );

    // Para velocidade na direção da normal se estiver se movendo contra ela
    final velocityDotNormal =
        _velocity.dx * normal.dx + _velocity.dy * normal.dy;
    if (velocityDotNormal < 0) {
      // Remove componente da velocidade na direção da normal
      _velocity = Offset(
        _velocity.dx - normal.dx * velocityDotNormal,
        _velocity.dy - normal.dy * velocityDotNormal,
      );
    }
  }
}
