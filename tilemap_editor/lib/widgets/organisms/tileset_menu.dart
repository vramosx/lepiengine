import 'package:flutter/widgets.dart' hide Form, FormField;
import 'package:lepiengine_tilemap_editor/widgets/atoms/tileset_selector.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/menu_header.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/tileset_dropdown.dart';
import 'package:lepiengine_tilemap_editor/widgets/dialogs/tileset_properties_dialog.dart';
import 'package:lepiengine_tilemap_editor/services/tileset_loader.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';

class TilesetMenu extends StatefulWidget {
  const TilesetMenu({super.key});

  @override
  State<TilesetMenu> createState() => _TilesetMenuState();
}

class _TilesetMenuState extends State<TilesetMenu> {
  Future<void> _loadTileset() async {
    final picked = await pickAndDecodeTileset();
    if (!mounted || picked == null) return;
    final props = await showTilesetPropertiesDialog(context, picked.image);
    if (!mounted || props == null) return;
    final scope = EditorScope.of(context);
    final id = scope.addTileset(
      name: picked.filename,
      image: picked.image,
      provider: picked.provider,
      tileWidth: props.tileWidth,
      tileHeight: props.tileHeight,
    );
    scope.setLayerTileset(id);
  }

  Widget buildTilesetSelection() => const TilesetDropdown();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: EditorScope.of(context),
      builder: (context, _) {
        final scope = EditorScope.of(context);
        final tilesetImage = scope.selectedLayerTilesetProvider;
        final showTilemap = tilesetImage != null;
        final tileW = scope.tilePixelWidth;
        final tileH = scope.tilePixelHeight;
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
                child: (showTilemap)
                    ? SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: TilesetSelector(
                            image: tilesetImage,
                            tileWidth: tileW,
                            tileHeight: tileH,
                            gridColor: Theme.of(context).colorScheme.secondary,
                            highlightColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            selectedX: scope.selectedTileX,
                            selectedY: scope.selectedTileY,
                            selectedStartX:
                                scope.selectedLayerSelection?.startX,
                            selectedStartY:
                                scope.selectedLayerSelection?.startY,
                            selectedEndX: scope.selectedLayerSelection?.endX,
                            selectedEndY: scope.selectedLayerSelection?.endY,
                            onTileSelected: (x, y) {
                              scope.selectTile(x, y);
                            },
                            onRangeSelected: (sx, sy, ex, ey) {
                              scope.setSelectionRange(sx, sy, ex, ey);
                            },
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
