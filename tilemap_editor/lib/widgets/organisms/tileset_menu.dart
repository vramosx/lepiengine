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
  String? selectedTileset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = EditorScope.of(context);
    final provider = scope.selectedLayerTilesetProvider;
    final id = scope.selectedLayer?.tilesetId;
    setState(() {
      _tilesetImage = provider;
      selectedTileset = id;
      showTilemap = provider != null;
      _tileWidth = scope.tilePixelWidth;
      _tileHeight = scope.tilePixelHeight;
    });
  }

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

                    final id = scope.addTileset(
                      name: result.files.single.name,
                      image: uiImage,
                      provider: MemoryImage(bytes),
                      tileWidth: tileW,
                      tileHeight: tileH,
                    );
                    scope.setLayerTileset(id);
                    setState(() {
                      _tilesetImage = scope.selectedLayerTilesetProvider;
                      showTilemap = true;
                      _tileWidth = tileW;
                      _tileHeight = tileH;
                      selectedTileset = id;
                    });

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

  Widget buildTilesetSelection() {
    return SizedBox(
      width: double.infinity,
      child: Select<String>(
        filled: true,
        itemBuilder: (context, item) {
          final tileset = EditorScope.of(
            context,
          ).tilesets.firstWhere((t) => t.id == item);
          return Text(tileset.name);
        },
        popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
        onChanged: (value) {
          if (value == null) return;
          final scope = EditorScope.of(context);
          scope.setLayerTileset(value);
          setState(() {
            selectedTileset = value;
            _tilesetImage = scope.selectedLayerTilesetProvider;
          });
        },
        value:
            selectedTileset ?? EditorScope.of(context).selectedLayer?.tilesetId,
        placeholder: const Text('Select a tileset'),
        popup: SelectPopup(
          items: SelectItemList(
            children: [
              for (final t in EditorScope.of(context).tilesets)
                SelectItemButton(
                  value: t.id,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.name),
                      IconButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete tileset?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  OutlineButton(
                                    child: const Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  DestructiveButton(
                                    child: const Text('Delete'),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            final scope = EditorScope.of(context);
                            scope.removeTileset(t.id);
                            final newSel = scope.selectedLayer?.tilesetId;
                            setState(() {
                              selectedTileset = newSel;
                              _tilesetImage =
                                  scope.selectedLayerTilesetProvider;
                              showTilemap = newSel != null;
                            });
                          }
                        },
                        icon: Icon(LucideIcons.trash, size: 14),
                        variance: ButtonStyle.destructive(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ).call,
      ),
    );
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
        buildTilesetSelection(),
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
                        selectedStartX: EditorScope.of(
                          context,
                        ).selectedLayerSelection?.startX,
                        selectedStartY: EditorScope.of(
                          context,
                        ).selectedLayerSelection?.startY,
                        selectedEndX: EditorScope.of(
                          context,
                        ).selectedLayerSelection?.endX,
                        selectedEndY: EditorScope.of(
                          context,
                        ).selectedLayerSelection?.endY,
                        onTileSelected: (x, y) {
                          EditorScope.of(context).selectTile(x, y);
                        },
                        onRangeSelected: (sx, sy, ex, ey) {
                          EditorScope.of(
                            context,
                          ).setSelectionRange(sx, sy, ex, ey);
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
