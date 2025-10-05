import 'package:shadcn_flutter/shadcn_flutter.dart';

class LayersList extends StatefulWidget {
  final List<SortableData<String>> layers;
  final Function(List<SortableData<String>> layers)? onListChange;
  const LayersList({super.key, required this.layers, this.onListChange});

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
                setState(() {
                  layers.remove(layer);
                });
                widget.onListChange?.call(layers);
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
                          key: ValueKey(i),
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
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              spacing: 8,
                              children: [
                                const SortableDragHandle(
                                  child: Icon(LucideIcons.equal, size: 14),
                                ),
                                Expanded(child: Text(layers[i].data).xSmall),
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
