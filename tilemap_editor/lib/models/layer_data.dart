import 'tile_ref.dart';
import 'tile_selection.dart';

class LayerData {
  String name;
  List<List<TileRef?>> tiles; // [y][x]
  String? tilesetId; // referência ao tileset selecionado
  TileSelection? selection; // seleção de tiles no tileset
  List<List<bool>> collisions; // [y][x] grid de colisão
  bool visible = true; // controle de visibilidade do layer (render e colisões)
  bool showCollisions = true; // visível por padrão

  LayerData({
    required this.name,
    required int width,
    required int height,
    this.tilesetId,
    this.selection,
  }) : tiles = List.generate(
         height,
         (_) => List<TileRef?>.filled(width, null, growable: false),
         growable: false,
       ),
       collisions = List.generate(
         height,
         (_) => List<bool>.filled(width, false, growable: false),
         growable: false,
       );

  void resize({required int width, required int height}) {
    final List<List<TileRef?>> newTiles = List.generate(
      height,
      (_) => List<TileRef?>.filled(width, null, growable: false),
      growable: false,
    );
    for (int y = 0; y < newTiles.length && y < tiles.length; y++) {
      for (int x = 0; x < newTiles[y].length && x < tiles[y].length; x++) {
        newTiles[y][x] = tiles[y][x];
      }
    }
    tiles = newTiles;

    final List<List<bool>> newCollisions = List.generate(
      height,
      (_) => List<bool>.filled(width, false, growable: false),
      growable: false,
    );
    for (int y = 0; y < newCollisions.length && y < collisions.length; y++) {
      for (
        int x = 0;
        x < newCollisions[y].length && x < collisions[y].length;
        x++
      ) {
        newCollisions[y][x] = collisions[y][x];
      }
    }
    collisions = newCollisions;
  }
}
