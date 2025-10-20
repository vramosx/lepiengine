import 'dart:ui';

import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/game_objects/tilemap.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';
import 'package:lepiengine_playground/examples/utils/json_utils.dart';

/// Hosts and loads the tilemap for the platformer example.
class PlatformMap extends GameObject {
  PlatformMap({
    super.name = 'PlatformMap',
    super.position = const Offset(0, 0),
  });

  late final Tilemap tilemap;

  @override
  void onAdd() {
    super.onAdd();

    _loadScene();
  }

  Future<void> _loadScene() async {
    await _loadTilemap();
  }

  Future<void> _loadTilemap() async {
    final jsonMap = await readJson(Constants.platformTilemap);

    // Carregamento automático (sem tratar paths) e criação do Tilemap v1
    final tilemapV1 = await Tilemap.fromJsonV1(
      jsonMap,
      name: 'PlatformTilemap',
      showGridPosition: false,
    );

    tilemap = tilemapV1;

    addChild(tilemapV1);
  }

  @override
  void render(Canvas canvas) {}
}
