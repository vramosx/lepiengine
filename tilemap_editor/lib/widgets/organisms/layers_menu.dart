import 'package:lepiengine_tilemap_editor/widgets/molecules/layers_list.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/menu_header.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';

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
              onPressed: () {},
              shape: ButtonShape.circle,
              child: Icon(LucideIcons.plus, size: 12),
            ),
          ),
        ),
        LayersList(
          layers: layers,
          selectedIndex: controller.selectedLayerIndex,
          onSelect: (index) => controller.selectLayer(index),
          onListChange: (newList) =>
              controller.setLayersByNames(newList.map((e) => e.data).toList()),
        ),
      ],
    );
  }
}
