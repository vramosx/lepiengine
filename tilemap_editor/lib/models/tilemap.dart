class Tilemap {
  final String name;
  final TilemapTileset tileset;
  final int mapTileWidth;
  final int mapTileHeight;
  final int mapWidth;
  final int mapHeight;
  final List<TilemapLayer> map; // lista de camadas com tiles
  final List<SolidTilesLayer>
  solidTiles; // lista de camadas com posições sólidas
  final bool debugCollisions;

  Tilemap({
    required this.name,
    required this.tileset,
    required this.mapTileWidth,
    required this.mapTileHeight,
    required this.mapWidth,
    required this.mapHeight,
    required this.map,
    required this.solidTiles,
    this.debugCollisions = false,
  });

  factory Tilemap.fromJson(Map<String, dynamic> json) {
    final List<dynamic> mapJson = json['map'] as List<dynamic>;
    final List<dynamic> solidJson = json['solidTiles'] as List<dynamic>;

    return Tilemap(
      name: json['name'] as String,
      tileset: TilemapTileset.fromJson(json['tileset'] as Map<String, dynamic>),
      mapTileWidth: json['mapTileWidth'] as int,
      mapTileHeight: json['mapTileHeight'] as int,
      mapWidth: json['mapWidth'] as int,
      mapHeight: json['mapHeight'] as int,
      map: mapJson
          .map((e) => TilemapLayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      solidTiles: solidJson
          .map((e) => SolidTilesLayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      debugCollisions: (json['debugCollisions'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tileset': tileset.toJson(),
      'mapTileWidth': mapTileWidth,
      'mapTileHeight': mapTileHeight,
      'mapWidth': mapWidth,
      'mapHeight': mapHeight,
      'map': map.map((e) => e.toJson()).toList(),
      'solidTiles': solidTiles.map((e) => e.toJson()).toList(),
      'debugCollisions': debugCollisions,
    };
  }
}

class TilemapTileset {
  final String image;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;

  TilemapTileset({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
  });

  factory TilemapTileset.fromJson(Map<String, dynamic> json) {
    return TilemapTileset(
      image: json['image'],
      tileWidth: json['tileWidth'],
      tileHeight: json['tileHeight'],
      columns: json['columns'],
      rows: json['rows'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
      'columns': columns,
      'rows': rows,
    };
  }
}

class TilemapLayer {
  final String layer;
  final List<List<int>> tiles;

  TilemapLayer({required this.layer, required this.tiles});

  factory TilemapLayer.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rows = json['tiles'] as List<dynamic>;
    return TilemapLayer(
      layer: json['layer'] as String,
      tiles: rows
          .map<List<int>>(
            (row) => (row as List<dynamic>).map<int>((e) => e as int).toList(),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'layer': layer, 'tiles': tiles};
  }
}

class SolidTilesLayer {
  final String layer;
  // Lista de pares [x, y]
  final List<List<int>> tiles;

  SolidTilesLayer({required this.layer, required this.tiles});

  factory SolidTilesLayer.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pairs = json['tiles'] as List<dynamic>;
    return SolidTilesLayer(
      layer: json['layer'] as String,
      tiles: pairs
          .map<List<int>>(
            (pair) =>
                (pair as List<dynamic>).map<int>((e) => e as int).toList(),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'layer': layer, 'tiles': tiles};
  }
}
