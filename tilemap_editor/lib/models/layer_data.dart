import 'tile_ref.dart';
import 'tile_selection.dart';

class LayerData {
  final String name;
  final List<List<TileRef?>> tiles; // [y][x]
  String? tilesetId; // referência ao tileset selecionado
  TileSelection? selection; // seleção de tiles no tileset

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
       );
}
