// import 'package:flutter/gestures.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/map_render.dart';
import 'package:lepiengine_tilemap_editor/widgets/organisms/left_sidemenu.dart';
import 'package:lepiengine_tilemap_editor/widgets/organisms/right_sidemenu.dart';
import 'package:lepiengine_tilemap_editor/widgets/organisms/topbar.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'controllers/version_controller.dart';
import 'controllers/editor_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VersionController.instance.load();
  runApp(const LepiEngineTilemapEditor());
}

class LepiEngineTilemapEditor extends StatelessWidget {
  const LepiEngineTilemapEditor({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return EditorScope(
      controller: EditorController(),
      child: ShadcnApp(
        theme: ThemeData(
          typography: Typography.geist().copyWith(
            sans: () => TextStyle(fontFamily: 'Montserrat'),
            mono: () => TextStyle(fontFamily: 'Montserrat'),
            h1: () => TextStyle(fontWeight: FontWeight.w100, fontSize: 16),
            h3: () => TextStyle(fontWeight: FontWeight.w200, fontSize: 10),
            textMuted: () =>
                TextStyle(fontWeight: FontWeight.w100, fontSize: 10),
            base: () => TextStyle(fontWeight: FontWeight.w200),
          ),
          colorScheme: ColorSchemes.darkViolet,
          radius: 0.5,
        ),
        home: const TilemapEditor(),
      ),
    );
  }
}

class TilemapEditor extends StatefulWidget {
  const TilemapEditor({super.key});

  @override
  State<StatefulWidget> createState() => _TilemapEditorState();
}

class _TilemapEditorState extends State<TilemapEditor> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          MapRender(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 110.0),
              child: Builder(
                builder: (context) {
                  final controller = EditorScope.of(context);
                  final path = controller.currentFilePath;
                  final name = path == null
                      ? 'Untitled'
                      : path.split(Platform.pathSeparator).last;
                  return Text(name).small;
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  KeyboardDisplay(
                    keys: Platform.isMacOS
                        ? [LogicalKeyboardKey.meta]
                        : [LogicalKeyboardKey.control],
                  ),
                  Text("hold to drag the screen").small,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 130.0),
              child: EditorTools(),
            ),
          ),
          Column(
            children: [
              // topbar
              Topbar(),
              // tool buttons centered

              // editor area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Stack(
                    children: [
                      // map area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          LeftSideMenu(),
                          Spacer(),
                          RightSideMenu(),
                        ],
                      ),

                      // Menus
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EditorTools extends StatefulWidget {
  const EditorTools({super.key});

  @override
  State<EditorTools> createState() => _EditorToolsState();
}

class _EditorToolsState extends State<EditorTools> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final controller = EditorScope.of(context);
        final selected = controller.currentTool;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brush button
              (selected == EditingTool.brush)
                  ? PrimaryButton(
                      shape: ButtonShape.circle,
                      onPressed: () => controller.setTool(EditingTool.brush),
                      child: const Icon(LucideIcons.pencil, size: 14),
                    )
                  : IconButton(
                      shape: ButtonShape.circle,
                      variance: ButtonVariance.ghost,
                      onPressed: () => controller.setTool(EditingTool.brush),
                      icon: const Icon(LucideIcons.pencil, size: 14),
                    ),
              const Gap(4),
              // Bucket button
              (selected == EditingTool.bucket)
                  ? PrimaryButton(
                      shape: ButtonShape.circle,
                      onPressed: () => controller.setTool(EditingTool.bucket),
                      child: const Icon(LucideIcons.paintBucket, size: 14),
                    )
                  : IconButton(
                      shape: ButtonShape.circle,
                      variance: ButtonVariance.ghost,
                      onPressed: () => controller.setTool(EditingTool.bucket),
                      icon: const Icon(LucideIcons.paintBucket, size: 14),
                    ),
              (selected == EditingTool.collision)
                  ? PrimaryButton(
                      shape: ButtonShape.circle,
                      onPressed: () =>
                          controller.setTool(EditingTool.collision),
                      child: const Icon(LucideIcons.blocks, size: 14),
                    )
                  : IconButton(
                      shape: ButtonShape.circle,
                      variance: ButtonVariance.ghost,
                      onPressed: () =>
                          controller.setTool(EditingTool.collision),
                      icon: const Icon(LucideIcons.blocks, size: 14),
                    ),
              Tooltip(
                tooltip: TooltipContainer(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: EditorScope.of(context).showGrid
                      ? Text("Hide grid")
                      : Text("Show grid"),
                ).call,
                child: Toggle(
                  value: EditorScope.of(context).showGrid,
                  style: const ButtonStyle.ghost(shape: ButtonShape.circle),
                  onChanged: (value) {
                    EditorScope.of(context).setShowGrid(value);
                  },
                  child: Icon(LucideIcons.grid3x3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
