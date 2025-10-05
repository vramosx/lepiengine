import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide Form, FormField;
import 'package:file_picker/file_picker.dart';
import 'package:lepiengine_tilemap_editor/widgets/atoms/tileset_selector.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/menu_header.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';

class TilesetMenu extends StatefulWidget {
  const TilesetMenu({super.key});

  @override
  State<TilesetMenu> createState() => _TilesetMenuState();
}

class _TilesetMenuState extends State<TilesetMenu> {
  bool showTilemap = false;
  ImageProvider? _tilesetImage;
  double _tileWidth = 32;
  double _tileHeight = 32;

  Future<void> _loadTileset() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final uiImage = await _loadImageFromBytes(bytes);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final FormController controller = FormController();
            return AlertDialog(
              title: const Text('Tileset Properties'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set the tile width and height'),
                  const Gap(16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      controller: controller,
                      child: const FormTableLayout(
                        rows: [
                          FormField<String>(
                            key: FormKey(#width),
                            label: Text('Width'),
                            child: TextField(
                              initialValue: '32',
                              autofocus: true,
                            ),
                          ),
                          FormField<String>(
                            key: FormKey(#height),
                            label: Text('Height'),
                            child: TextField(initialValue: '32'),
                          ),
                        ],
                      ),
                    ).withPadding(vertical: 16),
                  ),
                ],
              ),
              actions: [
                PrimaryButton(
                  child: const Text('Set'),
                  onPressed: () {
                    final scope = EditorScope.of(context);
                    final values = controller.values;

                    final dynamic widthRaw = values[const FormKey(#width)];
                    final dynamic heightRaw = values[const FormKey(#height)];

                    final double parsedWidth =
                        double.tryParse(widthRaw?.toString() ?? '') ?? 32;
                    final double parsedHeight =
                        double.tryParse(heightRaw?.toString() ?? '') ?? 32;

                    final double tileW = parsedWidth
                        .clamp(1.0, uiImage.width.toDouble())
                        .toDouble();
                    final double tileH = parsedHeight
                        .clamp(1.0, uiImage.height.toDouble())
                        .toDouble();

                    setState(() {
                      _tilesetImage = MemoryImage(bytes);
                      showTilemap = true;
                      _tileWidth = tileW;
                      _tileHeight = tileH;
                    });

                    scope.setTileset(
                      image: uiImage,
                      tileWidth: tileW,
                      tileHeight: tileH,
                    );

                    Navigator.of(context).pop(values);
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<ui.Image> _loadImageFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuHeader(
          iconData: LucideIcons.blocks,
          title: "Tileset",
          actionWidget: Tooltip(
            tooltip: TooltipContainer(
              backgroundColor: Theme.of(context).colorScheme.card,
              child: Text("Load tileset"),
            ).call,
            child: PrimaryButton(
              onPressed: () {
                _loadTileset();
              },
              shape: ButtonShape.circle,
              child: Icon(LucideIcons.folderOpen, size: 12),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: (showTilemap && _tilesetImage != null)
                ? SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TilesetSelector(
                        image: _tilesetImage!,
                        tileWidth: _tileWidth,
                        tileHeight: _tileHeight,
                        gridColor: Theme.of(context).colorScheme.secondary,
                        highlightColor: Theme.of(context).colorScheme.primary,
                        selectedX: EditorScope.of(context).selectedTileX,
                        selectedY: EditorScope.of(context).selectedTileY,
                        onTileSelected: (x, y) {
                          EditorScope.of(context).selectTile(x, y);
                        },
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
