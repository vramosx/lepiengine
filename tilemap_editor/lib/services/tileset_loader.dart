import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

class TilesetLoadResult {
  final ui.Image image;
  final ImageProvider provider;
  final String filename;

  const TilesetLoadResult({
    required this.image,
    required this.provider,
    required this.filename,
  });
}

Future<TilesetLoadResult?> pickAndDecodeTileset() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );

  if (result == null) return null;
  final file = result.files.single;
  final Uint8List? bytes = file.bytes;
  if (bytes == null) return null;

  final ui.Image uiImage = await _loadImageFromBytes(bytes);
  return TilesetLoadResult(
    image: uiImage,
    provider: MemoryImage(bytes),
    filename: file.name,
  );
}

Future<ui.Image> _loadImageFromBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
