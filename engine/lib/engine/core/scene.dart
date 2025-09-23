import 'dart:ui';
import 'game_object.dart';
import 'camera.dart';
import 'collision_manager.dart';
import 'viewport.dart';
import 'collider.dart';

/// Representa uma camada da cena.
/// Objetos dentro da mesma camada são ordenados por zIndex.
class SceneLayer {
  SceneLayer(this.name, {this.order = 0});

  final String name;
  int order; // quanto menor, mais "ao fundo" (renderiza antes)
  final List<GameObject> _objects = <GameObject>[];

  List<GameObject> get objects => List.unmodifiable(_objects);

  void add(GameObject obj) => _objects.add(obj);
  bool remove(GameObject obj) => _objects.remove(obj);
  void clear() => _objects.clear();
}

/// Cena: gerencia objetos em múltiplas camadas e ciclo de vida/render.
class Scene {
  Scene({
    required this.name,
    this.clearColor, // opcional: pinta o fundo da cena
    Map<String, int>?
    initialLayers, // ex: { "background":0, "entities":10, "ui":100 }
    Camera? camera, // câmera da cena (opcional)
    bool debugCollisions = false, // ativa visualização debug de colisões
  }) : camera = camera ?? Camera(),
       collisionManager = CollisionManager(debugMode: debugCollisions) {
    // cria camadas padrão (se não vier nada)
    if (initialLayers == null || initialLayers.isEmpty) {
      ensureLayer('background', order: 0);
      ensureLayer('entities', order: 10);
      ensureLayer('ui', order: 100);
    } else {
      initialLayers.forEach((k, v) => ensureLayer(k, order: v));
    }
  }

  final String name;

  /// Se definido, a cena pinta um retângulo cheio antes de renderizar os objetos.
  final Color? clearColor;

  /// Câmera da cena
  final Camera camera;

  /// Sistema de colisões da cena
  final CollisionManager collisionManager;

  bool active = true; // controla se update() roda
  bool visible = true; // controla se render() desenha
  bool mounted = false;

  // ---- Ciclo de vida da própria cena (SceneManager chamará) ----
  void onEnter() {} // chamada quando a cena se torna ativa
  void onExit() {} // chamada quando a cena deixa de ser ativa

  // ---- Camadas ----
  final Map<String, SceneLayer> _layers = <String, SceneLayer>{};

  /// Retorna camadas em ordem de desenho: order ASC (fundo → topo).
  Iterable<SceneLayer> get _sortedLayers {
    final list = _layers.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Garante existência da camada e retorna a referência.
  SceneLayer ensureLayer(String name, {int order = 0}) {
    return _layers.putIfAbsent(name, () => SceneLayer(name, order: order))
      ..order = order; // permite atualizar a ordem caso já exista
  }

  /// Atualiza a ordem de uma camada existente.
  void setLayerOrder(String layerName, int order) {
    final layer = _layers[layerName];
    if (layer != null) layer.order = order;
  }

  /// Remove completamente uma camada.
  void removeLayer(String layerName) {
    _layers.remove(layerName);
  }

  // ---- Gerência de objetos ----

  /// Adiciona um objeto à camada (padrão: "entities").
  void add(GameObject obj, {String layer = 'entities'}) {
    final l = ensureLayer(layer);
    l.add(obj);

    // Configura callback para registrar novos colliders automaticamente
    obj.setColliderAddedCallback((collider) {
      collisionManager.addCollider(collider);
    });

    obj.onAdd();

    // Registra todos os colliders do objeto no sistema de colisão (incluindo filhos)
    _registerCollidersRecursively(obj);
  }

  /// Registra todos os colliders de um objeto e seus filhos recursivamente
  void _registerCollidersRecursively(GameObject obj) {
    // Registra colliders do objeto atual
    for (final collider in obj.colliders) {
      collisionManager.addCollider(collider);
    }

    // Registra colliders dos filhos recursivamente
    for (final child in obj.children) {
      _registerCollidersRecursively(child);
    }
  }

  /// Remove um objeto (varre todas as camadas).
  bool remove(GameObject obj) {
    for (final l in _layers.values) {
      final removed = l.remove(obj);
      if (removed) {
        // Remove todos os colliders do objeto do sistema de colisão
        for (final collider in obj.colliders) {
          collisionManager.removeCollider(collider);
        }
        // Limpa o callback
        obj.setColliderAddedCallback(null);
        obj.onRemove();
        return true;
      }
    }
    return false;
  }

  /// Move um objeto de uma camada para outra.
  bool moveToLayer(GameObject obj, String newLayer) {
    for (final l in _layers.values) {
      if (l.objects.contains(obj)) {
        l.remove(obj);
        ensureLayer(newLayer).add(obj);
        return true;
      }
    }
    return false;
  }

  /// Remove todos os objetos de todas as camadas.
  void clearAll() {
    for (final l in _layers.values) {
      for (final obj in l.objects) {
        // Remove todos os colliders do objeto
        for (final collider in obj.colliders) {
          collisionManager.removeCollider(collider);
        }
        obj.onRemove();
      }
      l.clear();
    }
  }

  /// Remove todos os objetos de uma camada específica.
  void clearLayer(String layer) {
    final l = _layers[layer];
    if (l != null) {
      for (final obj in l.objects) {
        // Remove todos os colliders do objeto
        for (final collider in obj.colliders) {
          collisionManager.removeCollider(collider);
        }
        obj.onRemove();
      }
      l.clear();
    }
  }

  // ---- Consulta/Utilidades ----

  /// Busca por nome (primeiro que encontrar).
  GameObject? findByName(String name) {
    for (final l in _layers.values) {
      for (final o in l.objects) {
        if (o.name == name) return o;
      }
    }
    return null;
  }

  /// Lista todos por tipo T.
  List<T> query<T extends GameObject>() {
    final out = <T>[];
    for (final l in _layers.values) {
      for (final o in l.objects) {
        if (o is T) out.add(o);
      }
    }
    return out;
  }

  // ---- Métodos de conveniência para a câmera ----

  /// Converte coordenadas do mundo para a tela usando a câmera da cena
  Offset worldToScreen(Offset worldPos, Size viewport) {
    return camera.worldToScreen(worldPos, viewport);
  }

  /// Converte coordenadas da tela para o mundo usando a câmera da cena
  Offset screenToWorld(Offset screenPos, Size viewport) {
    return camera.screenToWorld(screenPos, viewport);
  }

  /// Faz a câmera seguir um objeto específico
  void followWithCamera(GameObject target) {
    camera.follow(target);
  }

  /// Para de seguir qualquer objeto com a câmera
  void stopCameraFollow() {
    camera.stopFollowing();
  }

  /// Move a câmera para uma posição específica
  void moveCameraTo(Offset position) {
    camera.moveTo(position);
  }

  /// Foca a câmera em um objeto específico instantaneamente
  void focusCameraOn(GameObject obj) {
    camera.focusOn(obj);
  }

  // ---- Métodos de conveniência para colisões ----

  /// Ativa/desativa o modo debug de colisões
  void setCollisionDebug(bool enabled) {
    collisionManager.debugMode = enabled;
  }

  /// Encontra todos os colliders que intersectam com um ponto
  List<Collider> getCollidersAtPoint(Offset worldPoint) {
    return collisionManager.getCollidersAtPoint(worldPoint);
  }

  /// Encontra todos os colliders que intersectam com uma área
  List<Collider> getCollidersInArea(Rect area) {
    return collisionManager.getCollidersInArea(area);
  }

  /// Encontra o primeiro collider que intersecta com um ponto
  Collider? getFirstColliderAtPoint(Offset worldPoint) {
    return collisionManager.getFirstColliderAtPoint(worldPoint);
  }

  /// Retorna estatísticas do sistema de colisão
  Map<String, dynamic> getCollisionStats() {
    return collisionManager.getStats();
  }

  /// Itera todos os objetos seguindo a mesma ordem de render:
  /// layer.order ASC → zIndex ASC.
  Iterable<GameObject> get _iterObjectsInDrawOrder sync* {
    for (final layer in _sortedLayers) {
      final list = layer.objects.toList()
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      for (final o in list) {
        yield o;
      }
    }
  }

  // ---- Loop da cena ----

  /// Atualiza todos os objetos ativos na ordem de camadas/zIndex.
  void update(double dt) {
    if (!active) return;

    // Atualiza a câmera
    camera.update(dt);

    // Atualiza objetos normalmente
    for (final o in _iterObjectsInDrawOrder) {
      if (o.active) {
        o.update(dt);
      }
    }

    // Atualiza física de objetos com PhysicsBody
    for (final o in _iterObjectsInDrawOrder) {
      if (o.active && o is PhysicsBody) {
        o.updatePhysics(dt);
      }
    }

    // Atualiza o sistema de colisões (resolve automaticamente)
    collisionManager.update(dt);
  }

  /// Renderiza a cena inteira.
  /// Passe `canvasSize` para habilitar o preenchimento de fundo (clearColor).
  /// A `viewport` aplica escala/offset da resolução base para a tela.
  void render(Canvas canvas, {Size? canvasSize, Viewport? viewport}) {
    if (!visible) return;

    if (clearColor != null && canvasSize != null) {
      final paint = Paint()..color = clearColor!;
      canvas.drawRect(Offset.zero & canvasSize, paint);
    }

    // Aplica transformação da viewport (resolução base -> tela)
    if (viewport != null) {
      canvas.save();
      viewport.applyCanvasTransform(canvas);
    }

    // Aplica transformação da câmera para objetos do mundo (não UI)
    canvas.save();
    final logicalSize = viewport != null
        ? viewport.logicalViewportSize
        : (canvasSize ?? Size.zero);
    camera.applyTransform(canvas, logicalSize);

    // Renderiza camadas que não são UI (com culling otimizado)
    for (final layer in _sortedLayers) {
      if (layer.name == 'ui') {
        continue; // UI é renderizada sem transformação da câmera
      }

      final objectsInLayer = layer.objects.toList()
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

      for (final o in objectsInLayer) {
        // Culling: só renderiza objetos visíveis na câmera
        // if (canvasSize != null && !camera.isGameObjectVisible(o, viewport)) {
        //   continue;
        // }
        o.renderTree(canvas);
      }
    }

    // Renderiza colliders em debug mode (no espaço do mundo)
    if (collisionManager.debugMode) {
      collisionManager.debugRender(canvas);
    }

    canvas.restore();

    // Desfaz transformação da viewport, mantendo canvas em espaço de tela para UI
    if (viewport != null) {
      canvas.restore();
    }

    // Renderiza camada UI sem transformação da câmera (sempre em screen space)
    final uiLayer = _layers['ui'];
    if (uiLayer != null) {
      final uiObjects = uiLayer.objects.toList()
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      for (final o in uiObjects) {
        o.renderTree(canvas);
      }
    }
  }
}
