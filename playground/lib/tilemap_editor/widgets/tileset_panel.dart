import 'package:flutter/material.dart';
import '../models/tilemap_editor_state.dart';
import 'tileset_painter.dart';

class TilesetPanel extends StatelessWidget {
  final TilemapEditorState editorState;

  const TilesetPanel({super.key, required this.editorState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editorState,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tileset',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (editorState.tilesetImage == null) ...[
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tileset loaded',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use the "Load Tileset" button in the top bar',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Tileset preview with selection
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SingleChildScrollView(
                      child: TilesetGrid(editorState: editorState),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Selected tile information
              if (editorState.selectedTileIndex != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Selected tile: ${editorState.selectedTileIndex}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Click on a tile to select it',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class TilesetGrid extends StatelessWidget {
  final TilemapEditorState editorState;

  const TilesetGrid({super.key, required this.editorState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editorState,
      builder: (context, child) {
        final image = editorState.tilesetImage!;
        final tilesPerRow = editorState.tilesPerRow;
        final tilesPerColumn = editorState.tilesPerColumn;

        if (tilesPerRow == 0 || tilesPerColumn == 0) {
          return const Center(child: Text('Invalid tile dimensions'));
        }

        return GestureDetector(
          onTapDown: (details) => _onTilesetTap(details.localPosition),
          child: CustomPaint(
            size: Size(
              tilesPerRow * editorState.tileWidth.toDouble(),
              tilesPerColumn * editorState.tileHeight.toDouble(),
            ),
            painter: TilesetPainter(
              image: image,
              tileWidth: editorState.tileWidth,
              tileHeight: editorState.tileHeight,
              selectedTileIndex: editorState.selectedTileIndex,
            ),
            child: SizedBox(
              width: tilesPerRow * editorState.tileWidth.toDouble(),
              height: tilesPerColumn * editorState.tileHeight.toDouble(),
            ),
          ),
        );
      },
    );
  }

  void _onTilesetTap(Offset position) {
    final tileX = (position.dx / editorState.tileWidth).floor();
    final tileY = (position.dy / editorState.tileHeight).floor();

    if (tileX >= 0 &&
        tileX < editorState.tilesPerRow &&
        tileY >= 0 &&
        tileY < editorState.tilesPerColumn) {
      final tileIndex = tileY * editorState.tilesPerRow + tileX;
      editorState.selectTile(tileIndex);
    }
  }
}
