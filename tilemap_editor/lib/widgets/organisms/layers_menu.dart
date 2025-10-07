import 'package:lepiengine_tilemap_editor/widgets/molecules/layers_list.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/menu_header.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';
import 'package:flutter/foundation.dart' show listEquals;

class LayersMenu extends StatefulWidget {
  const LayersMenu({super.key});

  @override
  State<LayersMenu> createState() => _LayersMenuState();
}

class _LayersMenuState extends State<LayersMenu> {
  List<SortableData<String>> layers = [];

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.of(context);
    layers = controller.layerNames.map((e) => SortableData<String>(e)).toList();
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        MenuHeader(
          iconData: LucideIcons.layers,
          title: "Layers",
          actionWidget: Tooltip(
            tooltip: TooltipContainer(
              backgroundColor: Theme.of(context).colorScheme.card,
              child: Text("Add new layer"),
            ).call,
            child: PrimaryButton(
              onPressed: () async {
                final nameController = TextEditingController(text: 'New Layer');
                final created = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Create new layer'),
                      content: SizedBox(
                        width: 320,
                        child: TextField(
                          controller: nameController,
                          autofocus: true,
                        ),
                      ),
                      actions: [
                        OutlineButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        PrimaryButton(
                          child: const Text('Create'),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    );
                  },
                );
                if (created == true) {
                  EditorScope.of(context).addLayer(nameController.text);
                }
              },
              shape: ButtonShape.circle,
              child: Icon(LucideIcons.plus, size: 12),
            ),
          ),
        ),
        LayersList(
          layers: layers,
          selectedIndex: controller.selectedLayerIndex,
          onSelect: (index) => controller.selectLayer(index),
          onListChange: (newList) {
            // Solicita reordenação ao controlador (fonte da verdade)
            final currentNames = controller.layerNames;
            final desiredNames = newList.map((e) => e.data).toList();
            if (listEquals(currentNames, desiredNames)) return;
            controller.reorderLayersByNames(desiredNames);
          },
        ),
      ],
    );
  }
}
