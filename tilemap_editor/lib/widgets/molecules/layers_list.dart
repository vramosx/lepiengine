import 'package:flutter/material.dart'
    show InkWell, TextEditingController, FocusNode;
import 'package:lepiengine_tilemap_editor/controllers/editor_controller.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class LayersList extends StatefulWidget {
  final List<SortableData<String>> layers;
  final Function(List<SortableData<String>> layers)? onListChange;
  final int? selectedIndex;
  final void Function(int index)? onSelect;
  const LayersList({
    super.key,
    required this.layers,
    this.onListChange,
    this.selectedIndex,
    this.onSelect,
  });

  @override
  State<LayersList> createState() => _LayersListState();
}

class _LayersListState extends State<LayersList> {
  late List<SortableData<String>> layers;

  @override
  void initState() {
    super.initState();
    layers = widget.layers;
  }

  @override
  void didUpdateWidget(covariant LayersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza a cópia local quando o pai envia uma nova ordem/lista
    if (!identical(oldWidget.layers, widget.layers)) {
      layers = widget.layers;
    }
  }

  void deleteLayer(SortableData<String> layer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm deletion of layer?'),
          content: const Text('This action is irreversible!'),
          actions: [
            OutlineButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            DestructiveButton(
              child: const Text('OK'),
              onPressed: () {
                final index = layers.indexOf(layer);
                if (index != -1) {
                  // Remove na fonte da verdade
                  EditorScope.of(context).removeLayer(index);
                  // Atualiza espelho local para feedback visual imediato
                  setState(() {
                    layers.removeAt(index);
                  });
                  widget.onListChange?.call(layers);
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: SortableLayer(
                lock: true,
                child: SortableDropFallback<int>(
                  onAccept: (value) {
                    setState(() {
                      layers.add(layers.removeAt(value.data));
                    });
                    widget.onListChange?.call(layers);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < layers.length; i++)
                        Sortable<String>(
                          key: ValueKey(layers[i].data),
                          data: layers[i],
                          // we only want user to drag the item from the handle,
                          // so we disable the drag on the item itself
                          enabled: false,
                          onAcceptTop: (value) {
                            setState(() {
                              layers.swapItem(value, i);
                            });
                            widget.onListChange?.call(layers);
                          },
                          onAcceptBottom: (value) {
                            setState(() {
                              layers.swapItem(value, i + 1);
                            });
                            widget.onListChange?.call(layers);
                          },
                          child: InkWell(
                            onTap: () => widget.onSelect?.call(i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: (widget.selectedIndex == i)
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(60)
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    const SortableDragHandle(
                                      child: Icon(LucideIcons.equal, size: 14),
                                    ),
                                    Expanded(
                                      child: _InlineRename(
                                        key: ValueKey(layers[i].data),
                                        initial: layers[i].data,
                                        onSubmit: (value) async {
                                          final newName = value.trim();
                                          if (newName.isEmpty) return true;
                                          // Impede duplicatas contra a lista atual
                                          final exists = layers.any(
                                            (e) =>
                                                e.data == newName &&
                                                e != layers[i],
                                          );
                                          if (exists) {
                                            await showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Duplicate layer name',
                                                  ),
                                                  content: const Text(
                                                    'A layer with this name already exists. Please choose a different name.',
                                                  ),
                                                  actions: [
                                                    PrimaryButton(
                                                      child: const Text('OK'),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            return false;
                                          }
                                          // Primeiro renomeia no controlador (fonte da verdade)
                                          EditorScope.of(
                                            context,
                                          ).renameLayer(i, newName);
                                          // Atualiza a cópia local apenas para feedback imediato
                                          setState(() {
                                            layers[i] = SortableData<String>(
                                              newName,
                                            );
                                          });
                                          return true;
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      tooltip: TooltipContainer(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.card,
                                        child: Text(
                                          EditorScope.of(
                                                context,
                                              ).layers[i].visible
                                              ? 'Hide layer'
                                              : 'Show layer',
                                        ),
                                      ).call,
                                      child: IconButton(
                                        onPressed: () {
                                          EditorScope.of(
                                            context,
                                          ).toggleLayerVisibility(i);
                                        },
                                        icon: Icon(
                                          EditorScope.of(
                                                context,
                                              ).layers[i].visible
                                              ? LucideIcons.eye
                                              : LucideIcons.eyeOff,
                                          size: 12,
                                        ),
                                        variance: ButtonVariance.ghost,
                                      ),
                                    ),
                                    Tooltip(
                                      tooltip: TooltipContainer(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.card,
                                        child: Text(
                                          EditorScope.of(
                                                context,
                                              ).layers[i].showCollisions
                                              ? 'Hide collisions'
                                              : 'Show collisions',
                                        ),
                                      ).call,
                                      child: IconButton(
                                        onPressed: () {
                                          EditorScope.of(
                                            context,
                                          ).toggleLayerCollisionVisibility(i);
                                        },
                                        icon: Icon(
                                          LucideIcons.blocks,
                                          size: 12,
                                        ),
                                        variance: ButtonVariance.ghost,
                                      ),
                                    ),
                                    Tooltip(
                                      tooltip: TooltipContainer(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.card,
                                        child: Text("Delete layer"),
                                      ).call,
                                      child: IconButton(
                                        onPressed: () => deleteLayer(layers[i]),
                                        icon: Icon(LucideIcons.trash, size: 12),
                                        variance: ButtonVariance.ghost,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineRename extends StatefulWidget {
  final String initial;
  final Future<bool> Function(String value) onSubmit;
  const _InlineRename({
    super.key,
    required this.initial,
    required this.onSubmit,
  });

  @override
  State<_InlineRename> createState() => _InlineRenameState();
}

class _InlineRenameState extends State<_InlineRename> {
  bool editing = false;
  late final TextEditingController controller;
  late final FocusNode focusNode;
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initial);
    focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus && editing && !_committing) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _InlineRename oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && !editing) {
      controller.text = widget.initial;
    }
  }

  Future<void> _commit() async {
    if (_committing) return;
    _committing = true;
    final text = controller.text.trim();
    bool ok = true;
    if (text.isNotEmpty && text != widget.initial) {
      ok = await widget.onSubmit(text);
    }
    if (ok) {
      setState(() => editing = false);
    } else {
      // mantém em edição e restaura o valor válido
      setState(() {
        editing = true;
        controller.text = widget.initial;
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      });
      focusNode.requestFocus();
    }
    _committing = false;
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return GestureDetector(
        onDoubleTap: () {
          setState(() {
            editing = true;
            controller.text = widget.initial;
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          });
        },
        child: Text(widget.initial).xSmall,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        maxLines: 1,
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}
