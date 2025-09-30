import 'dart:ui';
import 'collider.dart';
import 'game_object.dart';

/// Gerencia o sistema de colisões da cena
class CollisionManager {
  CollisionManager({this.debugMode = false});

  /// Se true, renderiza colliders para debug
  bool debugMode;

  /// Lista de todos os colliders dinâmicos (que se movem)
  final List<Collider> _dynamicColliders = [];

  /// Lista de todos os colliders estáticos (fixos)
  final List<Collider> _staticColliders = [];

  /// Mapa para rastrear colisões ativas (para callbacks de stay/exit)
  final Map<String, Set<String>> _activeCollisions = {};

  /// Adiciona um collider ao sistema
  void addCollider(Collider collider) {
    if (collider.isStatic) {
      _staticColliders.add(collider);
    } else {
      _dynamicColliders.add(collider);
    }
  }

  /// Remove um collider do sistema
  void removeCollider(Collider collider) {
    if (collider.isStatic) {
      _staticColliders.remove(collider);
    } else {
      _dynamicColliders.remove(collider);
    }

    // Remove das colisões ativas
    final colliderId = _getColliderId(collider);
    _activeCollisions.remove(colliderId);

    // Remove referências a este collider em outras colisões
    for (final collisions in _activeCollisions.values) {
      collisions.remove(colliderId);
    }
  }

  /// Limpa todos os colliders
  void clearAll() {
    _dynamicColliders.clear();
    _staticColliders.clear();
    _activeCollisions.clear();
  }

  /// Gera um ID único para um collider baseado no GameObject
  String _getColliderId(Collider collider) {
    return '${collider.gameObject.hashCode}_${collider.hashCode}';
  }

  /// Gera uma chave única para um par de colliders
  String _getCollisionKey(Collider a, Collider b) {
    final idA = _getColliderId(a);
    final idB = _getColliderId(b);
    // Ordena para garantir consistência (A-B = B-A)
    return idA.compareTo(idB) < 0 ? '${idA}_$idB' : '${idB}_$idA';
  }

  /// Atualiza o sistema de colisões (deve ser chamado a cada frame)
  void update(double dt) {
    final Map<String, CollisionInfo> currentCollisions = {};

    // Verifica colisões dinâmico vs dinâmico
    for (int i = 0; i < _dynamicColliders.length; i++) {
      for (int j = i + 1; j < _dynamicColliders.length; j++) {
        _checkCollisionPair(
          _dynamicColliders[i],
          _dynamicColliders[j],
          currentCollisions,
        );
      }
    }

    // Verifica colisões dinâmico vs estático
    for (final dynamic in _dynamicColliders) {
      for (final static in _staticColliders) {
        _checkCollisionPair(dynamic, static, currentCollisions);
      }
    }

    // NOVO: Resolve colisões automaticamente ANTES dos callbacks
    _resolveCollisions(currentCollisions);

    // Processa callbacks baseado nas colisões atuais vs anteriores
    _processCollisionCallbacks(currentCollisions);
  }

  // ---- Helpers de lado de colisão ----
  CollisionSide _oppositeSide(CollisionSide side) {
    switch (side) {
      case CollisionSide.top:
        return CollisionSide.bottom;
      case CollisionSide.bottom:
        return CollisionSide.top;
      case CollisionSide.left:
        return CollisionSide.right;
      case CollisionSide.right:
        return CollisionSide.left;
      case CollisionSide.unknown:
        return CollisionSide.unknown;
    }
  }

  CollisionSide _sideFromNormal(Offset normal) {
    const double epsilon = 1e-5;
    final double ax = normal.dx.abs();
    final double ay = normal.dy.abs();

    if (ax < epsilon && ay < epsilon) return CollisionSide.unknown;

    if (ax > ay) {
      return normal.dx > 0 ? CollisionSide.left : CollisionSide.right;
    } else {
      // Empate ou predominante em Y → usa vertical
      return normal.dy > 0 ? CollisionSide.top : CollisionSide.bottom;
    }
  }

  /// Verifica colisão entre um par de colliders
  void _checkCollisionPair(
    Collider a,
    Collider b,
    Map<String, CollisionInfo> currentCollisions,
  ) {
    // Otimização: broad phase usando AABB
    if (!a.getAABB().overlaps(b.getAABB())) {
      return;
    }

    final collision = a.getIntersection(b);
    if (collision != null) {
      final key = _getCollisionKey(a, b);

      // Armazena informação sobre ambos os colliders
      currentCollisions[key] = CollisionInfo(
        other: b,
        intersectionPoint: collision.intersectionPoint,
        normal: collision.normal,
        penetrationDepth: collision.penetrationDepth,
        isEntering: collision.isEntering,
      );
    }
  }

  /// Resolve colisões automaticamente para objetos com PhysicsBody
  void _resolveCollisions(Map<String, CollisionInfo> currentCollisions) {
    // print('CollisionManager: Resolvendo ${currentCollisions.length} colisões');

    for (final entry in currentCollisions.entries) {
      final collision = entry.value;
      final colliders = _getCollidersFromKey(entry.key);
      if (colliders == null) continue;

      final colliderA = colliders.$1;
      final colliderB = colliders.$2;
      final gameObjectA = colliderA.gameObject;
      final gameObjectB = colliderB.gameObject;

      // print('_resolveCollisions: Key: ${entry.key}');
      // print(
      //   '_resolveCollisions: collision.other: ${collision.other.gameObject.runtimeType}',
      // );
      // print(
      //   '_resolveCollisions: colliderA: ${colliderA.gameObject.runtimeType}',
      // );
      // print(
      //   '_resolveCollisions: colliderB: ${colliderB.gameObject.runtimeType}',
      // );
      // // print('_resolveCollisions: Normal original: ${collision.normal}');

      // print(
      //   'CollisionManager: Verificando ${gameObjectA.runtimeType} vs ${gameObjectB.runtimeType}',
      // );

      // CORREÇÃO: Determina qual normal usar baseado em quem calculou
      final normalForA = collision.normal;
      final normalForB = Offset(-collision.normal.dx, -collision.normal.dy);

      // Se collision.other é colliderB, então a normal é para A
      // Se collision.other é colliderA, então a normal é para B (precisa inverter)
      final needsInversion = collision.other == colliderA;

      // print('_resolveCollisions: needsInversion: $needsInversion');
      // print('_resolveCollisions: normalForA: $normalForA');
      // print('_resolveCollisions: normalForB: $normalForB');

      // Resolve física automaticamente para objetos com PhysicsBody
      // Distribui a correção entre os dois objetos dinâmicos (50/50)
      final bool movableA =
          gameObjectA is PhysicsBody &&
          !colliderB.isTrigger &&
          !colliderA.isStatic;
      final bool movableB =
          gameObjectB is PhysicsBody &&
          !colliderA.isTrigger &&
          !colliderB.isStatic;

      final double shareA = (movableA && movableB)
          ? 0.5
          : (movableA ? 1.0 : 0.0);
      final double shareB = (movableA && movableB)
          ? 0.5
          : (movableB ? 1.0 : 0.0);

      if (movableA && shareA > 0) {
        final correctNormal = needsInversion ? normalForB : normalForA;
        final selfSide = _sideFromNormal(correctNormal);
        final otherSide = _oppositeSide(selfSide);
        gameObjectA.resolveCollision(
          gameObjectB,
          CollisionInfo(
            other: colliderB,
            intersectionPoint: collision.intersectionPoint,
            normal: correctNormal,
            penetrationDepth: collision.penetrationDepth * shareA,
            isEntering: collision.isEntering,
            selfSide: selfSide,
            otherSide: otherSide,
          ),
        );
      }

      if (movableB && shareB > 0) {
        final correctNormal = needsInversion ? normalForA : normalForB;
        final selfSide = _sideFromNormal(correctNormal);
        final otherSide = _oppositeSide(selfSide);
        gameObjectB.resolveCollision(
          gameObjectA,
          CollisionInfo(
            other: colliderA,
            intersectionPoint: collision.intersectionPoint,
            normal: correctNormal,
            penetrationDepth: collision.penetrationDepth * shareB,
            isEntering: collision.isEntering,
            selfSide: selfSide,
            otherSide: otherSide,
          ),
        );
      }
    }
  }

  /// Processa callbacks de colisão baseado no estado anterior vs atual
  void _processCollisionCallbacks(
    Map<String, CollisionInfo> currentCollisions,
  ) {
    final Set<String> processedKeys = {};

    // Processa colisões atuais
    for (final entry in currentCollisions.entries) {
      final key = entry.key;
      final collision = entry.value;
      processedKeys.add(key);

      final wasColliding = _activeCollisions.containsKey(key);

      if (!wasColliding) {
        // Nova colisão - onCollisionEnter
        _activeCollisions[key] = <String>{};
        _triggerCollisionEnter(key, collision);
      } else {
        // Colisão contínua - onCollisionStay
        _triggerCollisionStay(key, collision);
      }
    }

    // Processa colisões que terminaram
    final keysToRemove = <String>[];
    for (final key in _activeCollisions.keys) {
      if (!processedKeys.contains(key)) {
        // Colisão terminou - onCollisionExit
        keysToRemove.add(key);
        _triggerCollisionExit(key);
      }
    }

    // Remove colisões que terminaram
    for (final key in keysToRemove) {
      _activeCollisions.remove(key);
    }
  }

  /// Dispara callback de entrada de colisão
  void _triggerCollisionEnter(String collisionKey, CollisionInfo collision) {
    final colliders = _getCollidersFromKey(collisionKey);
    if (colliders == null) return;

    final colliderA = colliders.$1;
    final colliderB = colliders.$2;
    final gameObjectA = colliderA.gameObject;
    final gameObjectB = colliderB.gameObject;

    // Ajuste: normal armazenada pode estar relativa ao outro collider devido à ordenação da chave.
    final bool needsInversion = collision.other == colliderA;
    final Offset normalForA = needsInversion
        ? Offset(-collision.normal.dx, -collision.normal.dy)
        : collision.normal;
    final Offset normalForB = Offset(-normalForA.dx, -normalForA.dy);

    // Callback para A
    if (gameObjectA is CollisionCallbacks) {
      final selfSideA = _sideFromNormal(normalForA);
      final otherSideA = _oppositeSide(selfSideA);
      final collisionForA = CollisionInfo(
        other: colliderB,
        intersectionPoint: collision.intersectionPoint,
        normal: normalForA,
        penetrationDepth: collision.penetrationDepth,
        isEntering: true,
        selfSide: selfSideA,
        otherSide: otherSideA,
      );
      gameObjectA.onCollisionEnter(gameObjectB, collisionForA);
    }

    // Callback para B
    if (gameObjectB is CollisionCallbacks) {
      final selfSideB = _sideFromNormal(normalForB);
      final otherSideB = _oppositeSide(selfSideB);
      final collisionForB = CollisionInfo(
        other: colliderA,
        intersectionPoint: collision.intersectionPoint,
        normal: normalForB,
        penetrationDepth: collision.penetrationDepth,
        isEntering: true,
        selfSide: selfSideB,
        otherSide: otherSideB,
      );
      gameObjectB.onCollisionEnter(gameObjectA, collisionForB);
    }
  }

  /// Dispara callback de colisão contínua
  void _triggerCollisionStay(String collisionKey, CollisionInfo collision) {
    final colliders = _getCollidersFromKey(collisionKey);
    if (colliders == null) return;

    final colliderA = colliders.$1;
    final colliderB = colliders.$2;
    final gameObjectA = colliderA.gameObject;
    final gameObjectB = colliderB.gameObject;

    // Ajuste: normal armazenada pode estar relativa ao outro collider devido à ordenação da chave.
    final bool needsInversion = collision.other == colliderA;
    final Offset normalForA = needsInversion
        ? Offset(-collision.normal.dx, -collision.normal.dy)
        : collision.normal;
    final Offset normalForB = Offset(-normalForA.dx, -normalForA.dy);

    // Callback para A
    if (gameObjectA is CollisionCallbacks) {
      final selfSideA = _sideFromNormal(normalForA);
      final otherSideA = _oppositeSide(selfSideA);
      final collisionForA = CollisionInfo(
        other: colliderB,
        intersectionPoint: collision.intersectionPoint,
        normal: normalForA,
        penetrationDepth: collision.penetrationDepth,
        isEntering: false,
        selfSide: selfSideA,
        otherSide: otherSideA,
      );
      gameObjectA.onCollisionStay(gameObjectB, collisionForA);
    }

    // Callback para B
    if (gameObjectB is CollisionCallbacks) {
      final selfSideB = _sideFromNormal(normalForB);
      final otherSideB = _oppositeSide(selfSideB);
      final collisionForB = CollisionInfo(
        other: colliderA,
        intersectionPoint: collision.intersectionPoint,
        normal: normalForB,
        penetrationDepth: collision.penetrationDepth,
        isEntering: false,
        selfSide: selfSideB,
        otherSide: otherSideB,
      );
      gameObjectB.onCollisionStay(gameObjectA, collisionForB);
    }
  }

  /// Dispara callback de saída de colisão
  void _triggerCollisionExit(String collisionKey) {
    final colliders = _getCollidersFromKey(collisionKey);
    if (colliders == null) return;

    final gameObjectA = colliders.$1.gameObject;
    final gameObjectB = colliders.$2.gameObject;

    if (gameObjectA is CollisionCallbacks) {
      gameObjectA.onCollisionExit(gameObjectB);
    }

    if (gameObjectB is CollisionCallbacks) {
      gameObjectB.onCollisionExit(gameObjectA);
    }
  }

  /// Recupera os colliders de uma chave de colisão
  (Collider, Collider)? _getCollidersFromKey(String collisionKey) {
    final parts = collisionKey.split('_');
    if (parts.length < 4) return null;

    Collider? colliderA;
    Collider? colliderB;

    final idA = '${parts[0]}_${parts[1]}';
    final idB = '${parts[2]}_${parts[3]}';

    for (final collider in [..._dynamicColliders, ..._staticColliders]) {
      final id = _getColliderId(collider);
      if (id == idA) {
        colliderA = collider;
      } else if (id == idB) {
        colliderB = collider;
      }
    }

    if (colliderA != null && colliderB != null) {
      return (colliderA, colliderB);
    }

    return null;
  }

  /// Renderiza todos os colliders em modo debug
  void debugRender(Canvas canvas) {
    if (!debugMode) return;

    // Renderiza colliders dinâmicos
    for (final collider in _dynamicColliders) {
      if (collider.gameObject.visible) {
        collider.debugRender(canvas);
      }
    }

    // Renderiza colliders estáticos
    for (final collider in _staticColliders) {
      if (collider.gameObject.visible) {
        collider.debugRender(canvas);
      }
    }
  }

  /// Encontra todos os colliders que intersectam com um ponto
  List<Collider> getCollidersAtPoint(Offset worldPoint) {
    final result = <Collider>[];

    for (final collider in [..._dynamicColliders, ..._staticColliders]) {
      if (collider.containsPoint(worldPoint)) {
        result.add(collider);
      }
    }

    return result;
  }

  /// Encontra todos os colliders que intersectam com uma área
  List<Collider> getCollidersInArea(Rect area) {
    final result = <Collider>[];

    for (final collider in [..._dynamicColliders, ..._staticColliders]) {
      if (collider.getAABB().overlaps(area)) {
        result.add(collider);
      }
    }

    return result;
  }

  /// Encontra o primeiro collider que intersecta com um ponto
  Collider? getFirstColliderAtPoint(Offset worldPoint) {
    for (final collider in [..._dynamicColliders, ..._staticColliders]) {
      if (collider.containsPoint(worldPoint)) {
        return collider;
      }
    }
    return null;
  }

  /// Retorna estatísticas do sistema de colisão
  Map<String, dynamic> getStats() {
    return {
      'dynamicColliders': _dynamicColliders.length,
      'staticColliders': _staticColliders.length,
      'activeCollisions': _activeCollisions.length,
      'totalColliders': _dynamicColliders.length + _staticColliders.length,
    };
  }
}

/// Mixin para GameObjects que querem receber callbacks de colisão
mixin CollisionCallbacks on GameObject {
  /// Chamado quando uma colisão começa
  void onCollisionEnter(GameObject other, CollisionInfo collision) {}

  /// Chamado enquanto a colisão continua
  void onCollisionStay(GameObject other, CollisionInfo collision) {}

  /// Chamado quando uma colisão termina
  void onCollisionExit(GameObject other) {}
}
