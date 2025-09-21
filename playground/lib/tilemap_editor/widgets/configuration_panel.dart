import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tilemap_editor_state.dart';

class ConfigurationPanel extends StatefulWidget {
  final TilemapEditorState editorState;

  const ConfigurationPanel({super.key, required this.editorState});

  @override
  State<ConfigurationPanel> createState() => _ConfigurationPanelState();
}

class _ConfigurationPanelState extends State<ConfigurationPanel> {
  late TextEditingController widthController;
  late TextEditingController heightController;
  late TextEditingController tileWidthController;
  late TextEditingController tileHeightController;

  @override
  void initState() {
    super.initState();
    widthController = TextEditingController(
      text: widget.editorState.width.toString(),
    );
    heightController = TextEditingController(
      text: widget.editorState.height.toString(),
    );
    tileWidthController = TextEditingController(
      text: widget.editorState.tileWidth.toString(),
    );
    tileHeightController = TextEditingController(
      text: widget.editorState.tileHeight.toString(),
    );

    widget.editorState.addListener(_updateControllers);
  }

  @override
  void dispose() {
    widget.editorState.removeListener(_updateControllers);
    widthController.dispose();
    heightController.dispose();
    tileWidthController.dispose();
    tileHeightController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    if (widthController.text != widget.editorState.width.toString()) {
      widthController.text = widget.editorState.width.toString();
    }
    if (heightController.text != widget.editorState.height.toString()) {
      heightController.text = widget.editorState.height.toString();
    }
    if (tileWidthController.text != widget.editorState.tileWidth.toString()) {
      tileWidthController.text = widget.editorState.tileWidth.toString();
    }
    if (tileHeightController.text != widget.editorState.tileHeight.toString()) {
      tileHeightController.text = widget.editorState.tileHeight.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Map dimensions
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widthController,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onMapSizeChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onMapSizeChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tile dimensions
          const Text(
            'Tile Dimensions (px)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tileWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onTileSizeChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: tileHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onTileSizeChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Spacer(),

          // Clear button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _clearMap,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapSizeChanged(String value) {
    final width = int.tryParse(widthController.text);
    final height = int.tryParse(heightController.text);

    if (width != null && height != null && width > 0 && height > 0) {
      widget.editorState.setMapSize(width, height);
    }
  }

  void _onTileSizeChanged(String value) {
    final tileWidth = int.tryParse(tileWidthController.text);
    final tileHeight = int.tryParse(tileHeightController.text);

    if (tileWidth != null &&
        tileHeight != null &&
        tileWidth > 0 &&
        tileHeight > 0) {
      widget.editorState.setTileSize(tileWidth, tileHeight);
    }
  }

  void _clearMap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Map'),
        content: const Text(
          'Are you sure you want to clear the entire map? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.editorState.clearMap();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
