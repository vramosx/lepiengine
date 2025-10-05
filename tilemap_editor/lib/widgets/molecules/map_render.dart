import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:lepiengine_tilemap_editor/widgets/atoms/canvas_control.dart';
import 'package:lepiengine_tilemap_editor/widgets/atoms/map_editor.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';
import 'package:flutter/services.dart';

class MapRender extends StatefulWidget {
  const MapRender({super.key, required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<MapRender> createState() => _MapRenderState();
}

class _MapRenderState extends State<MapRender> {
  final sceneTextSize = 60.0;
  double zoom = 1.0;
  double left = 0;
  double top = 0;
  bool canDrag = true;
  int taps = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        // Centralize the scene
        double screenWidth = MediaQuery.sizeOf(context).width;
        double screenHeight = MediaQuery.sizeOf(context).height;

        double sceneWidth = widget.width.toDouble() * zoom;
        double sceneHeight = (widget.height.toDouble() + sceneTextSize) * zoom;

        left = ((screenWidth - sceneWidth) / 2);
        top = ((screenHeight - sceneHeight)) / 2;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: [
            CanvasControl(
              scale: zoom,
              position: Offset(left, top),
              onTap: () {
                if (!canDrag) return;

                taps += 1;
                if (taps == 2) {
                  taps = 0;
                }
              },
              onScale: (newScale) {
                setState(() {
                  zoom = newScale;
                });
              },
              // onDrag: (newPosition) {
              //   if (!canDrag) return;
              //   setState(() {
              //     left = newPosition.dx;
              //     top = newPosition.dy;
              //   });
              // },
              onDrag: (newPosition) {
                final keys = HardwareKeyboard.instance.logicalKeysPressed;
                final allowPan =
                    keys.contains(LogicalKeyboardKey.metaLeft) ||
                    keys.contains(LogicalKeyboardKey.metaRight) ||
                    keys.contains(LogicalKeyboardKey.controlLeft) ||
                    keys.contains(LogicalKeyboardKey.controlRight);

                if (!allowPan) return;
                if (!canDrag) return;

                setState(() {
                  left = newPosition.dx;
                  top = newPosition.dy;
                });
              },
              child: DeferredPointerHandler(
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // Use positioned to overflow stack with no use of OverflowBox
                    Positioned(
                      left: 0,
                      top: 0,
                      width: widget.width.toDouble(),
                      height: widget.height + sceneTextSize,
                      child: MapEditor(
                        tilesX: EditorScope.of(context).tilesX,
                        tilesY: EditorScope.of(context).tilesY,
                        tileSize: EditorScope.of(context).tileSize,
                        gridColor: Theme.of(context).colorScheme.secondary,
                        highlightColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
