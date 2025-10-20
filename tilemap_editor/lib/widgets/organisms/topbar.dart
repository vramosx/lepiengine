import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lepiengine_tilemap_editor/controllers/version_controller.dart';
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';
import 'package:lepiengine_tilemap_editor/services/io_service.dart' as io;
import 'package:lepiengine_tilemap_editor/widgets/dialogs/confirm_discard_dialog.dart';
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
      height: 102,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                spacing: 16,
                children: [
                  Image.asset('assets/images/Lepi.png', width: 36),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
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
                        onPressed: (ctx) {
                          final controller = EditorScope.of(ctx);
                          final bool needConfirm =
                              controller.isDirty ||
                              controller.hasAnyTilePlaced();
                          if (needConfirm) {
                            showDialog<bool>(
                              context: ctx,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Unsaved changes'),
                                  content: const Text(
                                    'You have unsaved changes. Continue? This action is irreversible.',
                                  ),
                                  actions: [
                                    OutlineButton(
                                      child: const Text('Cancel'),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    DestructiveButton(
                                      child: const Text('Continue'),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                    ),
                                  ],
                                );
                              },
                            ).then((ok) {
                              if (ok == true) controller.newMap();
                            });
                          } else {
                            controller.newMap();
                          }
                        },
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
                        onPressed: (ctx) {
                          final controller = EditorScope.of(ctx);
                          proceed() {
                            io.openProject(ctx, controller);
                          }

                          if (controller.isDirty) {
                            showConfirmDiscardDialog(ctx).then((ok) {
                              if (ok == true) proceed();
                            });
                          } else {
                            proceed();
                          }
                        },
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
                        onPressed: (ctx) {
                          final controller = EditorScope.of(ctx);
                          io.saveProject(ctx, controller);
                        },
                        child: Text('Save').base,
                      ),
                      MenuButton(
                        leading: Icon(LucideIcons.saveAll),
                        child: Text('Save As...').base,
                        onPressed: (ctx) {
                          final controller = EditorScope.of(ctx);
                          io.saveProjectAs(ctx, controller);
                        },
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
