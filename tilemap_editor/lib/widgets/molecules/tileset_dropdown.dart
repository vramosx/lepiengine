import 'package:flutter/widgets.dart' hide Form, FormField;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';

class TilesetDropdown extends StatelessWidget {
  const TilesetDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = EditorScope.of(context);
    final String? selected = scope.selectedLayer?.tilesetId;
    return SizedBox(
      width: double.infinity,
      child: Select<String>(
        filled: true,
        itemBuilder: (context, item) {
          final tileset = scope.tilesets.firstWhere((t) => t.id == item);
          return Text(tileset.name);
        },
        popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
        onChanged: (value) {
          if (value == null) return;
          scope.setLayerTileset(value);
        },
        value: selected,
        placeholder: const Text('Select a tileset'),
        popup: SelectPopup(
          items: SelectItemList(
            children: [
              for (final t in scope.tilesets)
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
                            scope.removeTileset(t.id);
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
}
