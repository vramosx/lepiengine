import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/menu_header.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class RightSideMenu extends StatelessWidget {
  const RightSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.of(context);
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MenuHeader(iconData: LucideIcons.map, title: 'Map Properties'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Text('Map').muted,
                  Row(
                    spacing: 8,
                    children: [
                      Text('W').xSmall,
                      SizedBox(
                        width: 80,
                        child: TextField(
                          initialValue: controller.tilesX.toString(),
                          onSubmitted: (val) {
                            final w = int.tryParse(val) ?? controller.tilesX;
                            controller.setMapSize(
                              widthInTiles: w.clamp(1, 9999),
                              heightInTiles: controller.tilesY,
                            );
                          },
                        ),
                      ),
                      Text('H').xSmall,
                      SizedBox(
                        width: 80,
                        child: TextField(
                          initialValue: controller.tilesY.toString(),
                          onSubmitted: (val) {
                            final h = int.tryParse(val) ?? controller.tilesY;
                            controller.setMapSize(
                              widthInTiles: controller.tilesX,
                              heightInTiles: h.clamp(1, 9999),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('Tile').muted,
                  Row(
                    spacing: 8,
                    children: [
                      Text('W').xSmall,
                      SizedBox(
                        width: 80,
                        child: TextField(
                          initialValue: controller.tilePixelWidth
                              .toStringAsFixed(0),
                          onSubmitted: (val) {
                            final w =
                                double.tryParse(val) ??
                                controller.tilePixelWidth;
                            controller.setTilePixelSize(
                              width: w.clamp(1, 4096),
                              height: controller.tilePixelHeight,
                            );
                          },
                        ),
                      ),
                      Text('H').xSmall,
                      SizedBox(
                        width: 80,
                        child: TextField(
                          initialValue: controller.tilePixelHeight
                              .toStringAsFixed(0),
                          onSubmitted: (val) {
                            final h =
                                double.tryParse(val) ??
                                controller.tilePixelHeight;
                            controller.setTilePixelSize(
                              width: controller.tilePixelWidth,
                              height: h.clamp(1, 4096),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
