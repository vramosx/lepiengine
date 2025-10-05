import 'package:lepiengine_tilemap_editor/widgets/molecules/layers_list.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/menu_header.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class LayersMenu extends StatefulWidget {
  const LayersMenu({super.key});

  @override
  State<LayersMenu> createState() => _LayersMenuState();
}

class _LayersMenuState extends State<LayersMenu> {
  List<SortableData<String>> layers = [
    const SortableData('Sky'),
    const SortableData('Building'),
    const SortableData('Over Ground'),
    const SortableData('Ground'),
  ];

  @override
  Widget build(BuildContext context) {
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
        LayersList(layers: layers),
      ],
    );
  }
}
