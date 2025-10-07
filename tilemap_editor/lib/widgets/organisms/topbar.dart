import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lepiengine_tilemap_editor/controllers/version_controller.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class Topbar extends StatefulWidget {
  const Topbar({super.key});

  @override
  State<Topbar> createState() => _TopbarState();
}

class _TopbarState extends State<Topbar> {
  final version = VersionController.instance.version;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 142,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                spacing: 16,
                children: [
                  Image.asset('assets/images/Lepi.png', width: 75),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("LepiEngine - Tilemap Editor").h1,
                      Text(version ?? "").h3,
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.popover,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Menubar(
                border: false,
                children: [
                  MenuButton(
                    subMenu: [
                      MenuButton(
                        leading: Icon(LucideIcons.file),
                        trailing: MenuShortcut(
                          activator: SingleActivator(
                            LogicalKeyboardKey.keyN,
                            meta: Platform.isMacOS,
                            control: !Platform.isMacOS,
                          ),
                        ),
                        child: Text('New').base,
                      ),
                      MenuButton(
                        leading: Icon(LucideIcons.folderOpen),
                        trailing: MenuShortcut(
                          activator: SingleActivator(
                            LogicalKeyboardKey.keyO,
                            meta: Platform.isMacOS,
                            control: !Platform.isMacOS,
                          ),
                        ),
                        child: Text('Open').base,
                      ),
                      MenuButton(
                        leading: Icon(LucideIcons.save),
                        trailing: MenuShortcut(
                          activator: SingleActivator(
                            LogicalKeyboardKey.keyS,
                            meta: Platform.isMacOS,
                            control: !Platform.isMacOS,
                          ),
                        ),
                        child: Text('Save').base,
                      ),
                      MenuDivider(),
                      MenuButton(
                        leading: Icon(LucideIcons.doorClosed),
                        child: Text('Quit').base,
                      ),
                    ],
                    child: Text('File').base,
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
