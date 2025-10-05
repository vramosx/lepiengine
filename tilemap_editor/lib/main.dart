import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:lepiengine_tilemap_editor/widgets/molecules/map_render.dart';
import 'package:lepiengine_tilemap_editor/widgets/organisms/left_sidemenu.dart';
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
            h1: () => TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
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
          Column(
            children: [
              // topbar
              Topbar(),
              // editor area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Stack(
                    children: [
                      // map area
                      Row(children: [LeftSideMenu()]),

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
