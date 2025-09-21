import 'package:flutter/material.dart';
import '../models/tilemap_editor_state.dart';
import 'map_painter.dart';

class MapCanvas extends StatefulWidget {
  final TilemapEditorState editorState;

  const MapCanvas({super.key, required this.editorState});

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isPainting = false;
  bool _isErasing = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 5.0,
        child: Container(
          width:
              widget.editorState.width *
                  widget.editorState.tileWidth.toDouble() +
              200,
          height:
              widget.editorState.height *
                  widget.editorState.tileHeight.toDouble() +
              200,
          color: Colors.grey[200],
          child: Center(
            child: GestureDetector(
              onTapDown: _onTapDown,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onSecondaryTapDown: _onSecondaryTapDown,
              child: CustomPaint(
                size: Size(
                  widget.editorState.width *
                      widget.editorState.tileWidth.toDouble(),
                  widget.editorState.height *
                      widget.editorState.tileHeight.toDouble(),
                ),
                painter: MapPainter(editorState: widget.editorState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final position = details.localPosition;
    final tileCoords = _getTileCoordinates(position);

    if (tileCoords != null) {
      widget.editorState.paintTile(
        tileCoords.dx.toInt(),
        tileCoords.dy.toInt(),
      );
    }
  }

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    final tileCoords = _getTileCoordinates(position);

    if (tileCoords != null) {
      _isPainting = true;
      _isErasing = false;
      widget.editorState.paintTile(
        tileCoords.dx.toInt(),
        tileCoords.dy.toInt(),
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPainting) return;

    final position = details.localPosition;
    final tileCoords = _getTileCoordinates(position);

    if (tileCoords != null) {
      if (_isErasing) {
        widget.editorState.eraseTile(
          tileCoords.dx.toInt(),
          tileCoords.dy.toInt(),
        );
      } else {
        widget.editorState.paintTile(
          tileCoords.dx.toInt(),
          tileCoords.dy.toInt(),
        );
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isPainting = false;
    _isErasing = false;
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    final position = details.localPosition;
    final tileCoords = _getTileCoordinates(position);

    if (tileCoords != null) {
      widget.editorState.eraseTile(
        tileCoords.dx.toInt(),
        tileCoords.dy.toInt(),
      );
    }
  }

  Offset? _getTileCoordinates(Offset position) {
    final tileWidth = widget.editorState.tileWidth.toDouble();
    final tileHeight = widget.editorState.tileHeight.toDouble();

    final tileX = (position.dx / tileWidth).floor();
    final tileY = (position.dy / tileHeight).floor();

    if (tileX >= 0 &&
        tileX < widget.editorState.width &&
        tileY >= 0 &&
        tileY < widget.editorState.height) {
      return Offset(tileX.toDouble(), tileY.toDouble());
    }

    return null;
  }
}
