import 'package:lepiengine_tilemap_editor/widgets/organisms/layers_menu.dart';
import 'package:lepiengine_tilemap_editor/widgets/organisms/tileset_menu.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class LeftSideMenu extends StatelessWidget {
  const LeftSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Column(
        children: [
          LayersMenu(),
          Expanded(child: TilesetMenu()),
        ],
      ),
    );
  }
}
