import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

class TilesetDef {
  final String id;
  final String name;
  final ui.Image image;
  final ImageProvider provider;
  final String?
  path; // caminho relativo ao arquivo do projeto (quando disponível)

  const TilesetDef({
    required this.id,
    required this.name,
    required this.image,
    required this.provider,
    this.path,
  });
}
