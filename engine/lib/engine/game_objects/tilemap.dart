import 'dart:ui';
import 'dart:math' as math;
import 'package:lepiengine/engine/core/collider.dart';
import '../core/game_object.dart';
import '../models/tileset.dart';
import '../core/asset_loader.dart';

/// Célula de tile (esparsa) no grid do mapa v1
class TileCellV1 {
  const TileCellV1({
    required this.x,
    required this.y,
    required this.tx,
    required this.ty,
  });

  /// Coordenadas no grid do mundo (em células)
  final int x;
  final int y;

  /// Coordenadas do tile dentro do spritesheet (coluna/linha)
  final int tx;
  final int ty;
}

/// Camada do mapa v1 com tiles esparsos e colisões por layer
class TileLayerV1 {
  TileLayerV1({
    required this.name,
    required this.tilesetId,
    required this.tiles,
    Set<math.Point<int>>? collisions,
  }) : collisions = collisions ?? <math.Point<int>>{};

  final String name;
  final String tilesetId;
  final List<TileCellV1> tiles; // esparsos
  final Set<math.Point<int>> collisions; // sólidos por layer
}

class Tilemap extends GameObject {
  /// Tilesets disponíveis no mapa (chave = tilesetId do JSON v1)
  final Map<String, Tileset> tilesetsById;

  /// Camadas do mapa (v1)
  final List<TileLayerV1> layers;

  /// Dimensões do grid em células
  final int gridWidth; // map.size.width
  final int gridHeight; // map.size.height

  /// Tamanho do tile no mundo (pixels)
  final int worldTileWidth; // map.worldTileSize.width
  final int worldTileHeight; // map.worldTileSize.height

  /// Depuração: desenhar colisões e colliders resultantes
  final bool debugCollisions;

  /// Constrói um Tilemap no formato v1 (sem compat legado)
  Tilemap({
    required Map<String, Tileset> tilesetsById,
    required List<TileLayerV1> layers,
    required int gridWidth,
    required int gridHeight,
    int worldTileWidth = 32,
    int worldTileHeight = 32,
    bool debugCollisions = false,
    super.position,
    super.name,
  }) : tilesetsById = tilesetsById,
       layers = layers,
       gridWidth = gridWidth,
       gridHeight = gridHeight,
       worldTileWidth = worldTileWidth,
       worldTileHeight = worldTileHeight,
       debugCollisions = debugCollisions,
       super(
         size: Size(
           gridWidth * worldTileWidth.toDouble(),
           gridHeight * worldTileHeight.toDouble(),
         ),
       );

  /// União de todas as células sólidas de todas as camadas
  Set<math.Point<int>> get allSolidTiles {
    final Set<math.Point<int>> combined = <math.Point<int>>{};
    for (final layer in layers) {
      combined.addAll(layer.collisions);
    }
    return combined;
  }

  @override
  void onAdd() {
    super.onAdd();
    _generateColliders();
  }

  /// Gera colliders mesclados para os tiles sólidos
  void _generateColliders() {
    if (gridWidth == 0 || gridHeight == 0) return;

    final Set<math.Point<int>> solids = allSolidTiles;
    for (int y = 0; y < gridHeight; y++) {
      int? startX;
      for (int x = 0; x < gridWidth; x++) {
        final bool isSolid = solids.contains(math.Point<int>(x, y));

        if (isSolid && startX == null) {
          // inicia uma sequência de sólidos
          startX = x;
        }

        final bool reachedEnd =
            (!isSolid && startX != null) || (isSolid && x == gridWidth - 1);

        if (reachedEnd) {
          final int endX = isSolid ? x : x - 1;
          final int widthPx = (endX - startX! + 1) * worldTileWidth;
          final int heightPx = worldTileHeight;

          final collider = AABBCollider(
            gameObject: this,
            size: Size(widthPx.toDouble(), heightPx.toDouble()),
            offset: Offset(
              startX * worldTileWidth.toDouble(),
              y * worldTileHeight.toDouble(),
            ),
            anchor: ColliderAnchor.topLeft,
            isStatic: true,
            debugColor: const Color(0xFFFF0000),
          );
          addCollider(collider);
          startX = null;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    const double dstPad = 0.2;
    // Desenha de baixo para cima: assume que o JSON lista as camadas
    // do topo para a base (como editores normalmente fazem).
    for (int li = layers.length - 1; li >= 0; li--) {
      final layer = layers[li];
      final Tileset? tileset = tilesetsById[layer.tilesetId];
      if (tileset == null) continue; // tileset ausente — ignore

      for (final tile in layer.tiles) {
        final int index = tile.ty * tileset.columns + tile.tx;
        final Rect src = tileset.getTileRect(index);

        final Rect dst = Rect.fromLTWH(
          tile.x * worldTileWidth.toDouble() - dstPad,
          tile.y * worldTileHeight.toDouble() - dstPad,
          worldTileWidth.toDouble() + dstPad * 2,
          worldTileHeight.toDouble() + dstPad * 2,
        );
        canvas.drawImageRect(tileset.image, src, dst, paint);
      }
    }

    // Overlay de debug de sólidos (pintura única por célula)
    if (debugCollisions) {
      final Set<math.Point<int>> solids = allSolidTiles;
      final Paint debugPaint = Paint()
        ..color = const Color(0x55FF0000)
        ..style = PaintingStyle.fill;
      for (final p in solids) {
        final Rect dst = Rect.fromLTWH(
          p.x * worldTileWidth.toDouble(),
          p.y * worldTileHeight.toDouble(),
          worldTileWidth.toDouble(),
          worldTileHeight.toDouble(),
        );
        canvas.drawRect(dst, debugPaint);
      }

      // Também desenha os colliders mesclados
      for (final collider in colliders) {
        collider.debugRender(canvas);
      }
    }
  }

  /// Constrói um Tilemap v1 a partir do JSON, usando tilesets já carregados
  /// (uso interno/avançado). Para carregamento automático assíncrono, use
  /// o método estático [fromJsonV1].
  factory Tilemap._fromJsonV1WithTilesets(
    Map<String, dynamic> json,
    Map<String, Tileset> tilesetsById, {
    Offset? position,
    String? name,
    bool debugCollisions = false,
    double? width,
    double? height,
  }) {
    final int schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    if (schemaVersion != 1) {
      throw ArgumentError(
        'Tilemap schemaVersion esperado = 1, recebido = $schemaVersion',
      );
    }

    final Map<String, dynamic> map = (json['map'] as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> size = (map['size'] as Map)
        .cast<String, dynamic>();
    final int gridWidth = (size['width'] as num).toInt();
    final int gridHeight = (size['height'] as num).toInt();

    final Map<String, dynamic> worldTileSize = (map['worldTileSize'] as Map)
        .cast<String, dynamic>();
    final int worldTileWidth = (worldTileSize['width'] as num).toInt();
    final int worldTileHeight = (worldTileSize['height'] as num).toInt();

    final List<dynamic> layersJson = (json['layers'] as List).toList();
    final List<TileLayerV1> layers = <TileLayerV1>[];

    for (final dynamic l in layersJson) {
      final Map<String, dynamic> layer = (l as Map).cast<String, dynamic>();
      final String name = layer['name'] as String? ?? '';
      final String tilesetId = layer['tilesetId'] as String? ?? '';

      // Validação de tilesetId presente no mapa fornecido
      if (!tilesetsById.containsKey(tilesetId)) {
        throw ArgumentError('Tileset ausente para tilesetId="$tilesetId"');
      }

      // Tiles esparsos
      final List<TileCellV1> tiles = <TileCellV1>[];
      final List<dynamic> tilesJson =
          (layer['tiles'] as List? ?? const <dynamic>[]).toList();
      for (final dynamic t in tilesJson) {
        final Map<String, dynamic> tile = (t as Map).cast<String, dynamic>();
        tiles.add(
          TileCellV1(
            x: (tile['x'] as num).toInt(),
            y: (tile['y'] as num).toInt(),
            tx: (tile['tx'] as num).toInt(),
            ty: (tile['ty'] as num).toInt(),
          ),
        );
      }

      // Colisões por layer
      final Set<math.Point<int>> collisions = <math.Point<int>>{};
      final List<dynamic> collisionsJson =
          (layer['collisions'] as List? ?? const <dynamic>[]).toList();
      for (final dynamic c in collisionsJson) {
        final Map<String, dynamic> col = (c as Map).cast<String, dynamic>();
        collisions.add(
          math.Point<int>((col['x'] as num).toInt(), (col['y'] as num).toInt()),
        );
      }

      // Ignora "visible" e "showCollisions" — são apenas do editor
      layers.add(
        TileLayerV1(
          name: name,
          tilesetId: tilesetId,
          tiles: tiles,
          collisions: collisions,
        ),
      );
    }

    final tilemap = Tilemap(
      tilesetsById: tilesetsById,
      layers: layers,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      worldTileWidth: worldTileWidth,
      worldTileHeight: worldTileHeight,
      debugCollisions: debugCollisions,
      position: position,
      name: name,
    );
    // Ajuste de stretch opcional (aplica escala e atualiza size)
    if (width != null || height != null) {
      final double baseW = gridWidth * worldTileWidth.toDouble();
      final double baseH = gridHeight * worldTileHeight.toDouble();
      final double targetW = width ?? baseW;
      final double targetH = height ?? baseH;
      final double sx = targetW / baseW;
      final double sy = targetH / baseH;
      tilemap.scale = Offset(sx, sy);
      tilemap.size = Size(targetW, targetH);
    }
    return tilemap;
  }

  /// Carrega um Tilemap v1 a partir do JSON, resolvendo e carregando
  /// automaticamente os tilesets usados utilizando o campo "path" do JSON.
  ///
  /// - Usa o `path` exatamente como informado pelo JSON (relativo a assets/images).
  /// - Suporta `width`/`height` para aplicar stretch no tilemap resultante.
  static Future<Tilemap> fromJsonV1(
    Map<String, dynamic> json, {
    Offset? position,
    String? name,
    bool debugCollisions = false,
    double? width,
    double? height,
  }) async {
    // Coleta ids de tilesets usados pelas camadas
    final List<dynamic> layersJson = (json['layers'] as List).toList();
    final Set<String> usedTilesetIds = <String>{};
    for (final dynamic l in layersJson) {
      final Map<String, dynamic> layer = (l as Map).cast<String, dynamic>();
      final String tilesetId = layer['tilesetId'] as String? ?? '';
      if (tilesetId.isNotEmpty) usedTilesetIds.add(tilesetId);
    }

    // Monta tilesetsById apenas para ids usados
    final Map<String, Tileset> tilesetsById = <String, Tileset>{};
    final List<dynamic> tilesetsJson = (json['tilesets'] as List).toList();
    for (final dynamic ts in tilesetsJson) {
      final Map<String, dynamic> s = (ts as Map).cast<String, dynamic>();
      final String id = s['id'] as String? ?? '';
      if (!usedTilesetIds.contains(id)) {
        continue; // ignora tilesets não usados
      }
      final Map<String, dynamic>? tps = (s['tilePixelSize'] as Map?)
          ?.cast<String, dynamic>();
      final int tw = (tps?['width'] as num?)?.toInt() ?? 16;
      final int th = (tps?['height'] as num?)?.toInt() ?? 16;
      final String pathStr = s['path'] as String? ?? '';
      if (pathStr.isEmpty) {
        throw ArgumentError('Tileset "$id" sem campo "path" definido no JSON.');
      }
      final Image image = await AssetLoader.loadImage(pathStr);
      tilesetsById[id] = Tileset(image: image, tileWidth: tw, tileHeight: th);
    }

    return Tilemap._fromJsonV1WithTilesets(
      json,
      tilesetsById,
      position: position,
      name: name,
      debugCollisions: debugCollisions,
      width: width,
      height: height,
    );
  }
}
