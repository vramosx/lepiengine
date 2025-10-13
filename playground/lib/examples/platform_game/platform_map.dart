import 'dart:ui';

import 'package:lepiengine/engine/core/game_object.dart';
import 'package:lepiengine/engine/game_objects/tilemap.dart';
import 'package:lepiengine_playground/examples/utils/constants.dart';
import 'package:lepiengine_playground/examples/utils/json_utils.dart';

class PlatformMap extends GameObject {
  PlatformMap({
    super.name = 'PlatformMap',
    super.position = const Offset(0, 0),
  });

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
    );

    addChild(tilemapV1);
  }

  @override
  void render(Canvas canvas) {}
}
