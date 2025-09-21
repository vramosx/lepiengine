import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'models/tilemap_editor_state.dart';
import 'widgets/tileset_panel.dart';
import 'widgets/map_canvas.dart';
import 'widgets/configuration_panel.dart';

class TilemapEditorScreen extends StatefulWidget {
  const TilemapEditorScreen({super.key});

  @override
  State<TilemapEditorScreen> createState() => _TilemapEditorScreenState();
}

class _TilemapEditorScreenState extends State<TilemapEditorScreen> {
  late TilemapEditorState editorState;

  @override
  void initState() {
    super.initState();
    editorState = TilemapEditorState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tilemap Editor'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showNewMapDialog,
            icon: const Icon(Icons.add),
            tooltip: 'New Map',
          ),
          IconButton(
            onPressed: _loadTileset,
            icon: const Icon(Icons.image),
            tooltip: 'Load Tileset',
          ),
          IconButton(
            onPressed: _exportJson,
            icon: const Icon(Icons.save),
            tooltip: 'Export JSON',
          ),
          IconButton(
            onPressed: _importJson,
            icon: const Icon(Icons.folder_open),
            tooltip: 'Import JSON',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: editorState,
        builder: (context, child) {
          return Row(
            children: [
              // Painel Esquerdo
              Container(
                width: 300,
                color: Colors.grey[100],
                child: Column(
                  children: [
                    // Configurações
                    Expanded(
                      flex: 1,
                      child: ConfigurationPanel(editorState: editorState),
                    ),
                    const Divider(height: 1),
                    // Tileset
                    Expanded(
                      flex: 2,
                      child: TilesetPanel(editorState: editorState),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // Canvas Central
              Expanded(
                child: Column(
                  children: [
                    // Modo de edição
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: Row(
                        children: [
                          const Text('Mode: '),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Tiles'),
                                icon: Icon(Icons.grid_on),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Collision'),
                                icon: Icon(Icons.block),
                              ),
                            ],
                            selected: {editorState.editingCollision},
                            onSelectionChanged: (selection) {
                              editorState.setEditingMode(selection.first);
                            },
                          ),
                        ],
                      ),
                    ),
                    // Canvas do mapa
                    Expanded(child: MapCanvas(editorState: editorState)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showNewMapDialog() async {
    final widthController = TextEditingController(
      text: editorState.width.toString(),
    );
    final heightController = TextEditingController(
      text: editorState.height.toString(),
    );

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Map'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Width (tiles)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Height (tiles)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final width = int.tryParse(widthController.text) ?? 10;
              final height = int.tryParse(heightController.text) ?? 10;
              Navigator.pop(context, {'width': width, 'height': height});
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      editorState.setMapSize(result['width']!, result['height']!);
    }
  }

  Future<void> _loadTileset() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final image = await _loadImageFromBytes(bytes);

      if (mounted) {
        // Solicitar dimensões do tile
        await _showTileSizeDialog(image, result.files.single.path!);
      }
    }
  }

  Future<ui.Image> _loadImageFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _showTileSizeDialog(ui.Image image, String path) async {
    final tileWidthController = TextEditingController(
      text: editorState.tileWidth.toString(),
    );
    final tileHeightController = TextEditingController(
      text: editorState.tileHeight.toString(),
    );

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Tileset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Image: ${image.width}x${image.height} pixels'),
            const SizedBox(height: 16),
            TextField(
              controller: tileWidthController,
              decoration: const InputDecoration(
                labelText: 'Tile Width (px)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tileHeightController,
              decoration: const InputDecoration(
                labelText: 'Tile Height (px)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tileWidth = int.tryParse(tileWidthController.text) ?? 32;
              final tileHeight = int.tryParse(tileHeightController.text) ?? 32;
              Navigator.pop(context, {
                'tileWidth': tileWidth,
                'tileHeight': tileHeight,
              });
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      editorState.setTileSize(result['tileWidth']!, result['tileHeight']!);
      editorState.setTilesetImage(image, path);
    }
  }

  Future<void> _exportJson() async {
    final jsonString = editorState.exportToJsonString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            children: [
              const Text('Generated JSON:'),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard!')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        editorState.fromJson(jsonData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Map loaded successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading file: $e')));
        }
      }
    }
  }
}
