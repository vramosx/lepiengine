import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class TilesetSelector extends StatefulWidget {
  final ImageProvider image;
  final double tileWidth;
  final double tileHeight;
  final Color gridColor;
  final Color highlightColor;
  final void Function(int x, int y)? onTileSelected;
  final int? selectedX;
  final int? selectedY;

  /// Tamanho opcional de exibição. Se não informado, usa o tamanho da imagem.
  final double? displayWidth;
  final double? displayHeight;

  const TilesetSelector({
    super.key,
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    this.gridColor = const Color(0xFFCCCCCC),
    this.highlightColor = const Color.fromARGB(84, 68, 189, 245),
    this.onTileSelected,
    this.displayWidth,
    this.displayHeight,
    this.selectedX,
    this.selectedY,
  });

  @override
  State<TilesetSelector> createState() => _TilesetSelectorState();
}

class _TilesetSelectorState extends State<TilesetSelector> {
  Size? _intrinsicImageLogicalSize;
  Offset? _hoverPosition;

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unresolveImage();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant TilesetSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _unresolveImage();
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _unresolveImage();
    super.dispose();
  }

  void _resolveImage() {
    final ImageStream stream = widget.image.resolve(
      createLocalImageConfiguration(context),
    );
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener((ImageInfo info, bool _) {
      final double logicalWidth = info.image.width / info.scale;
      final double logicalHeight = info.image.height / info.scale;
      if (mounted) {
        setState(() {
          _intrinsicImageLogicalSize = Size(logicalWidth, logicalHeight);
        });
      }
    });
    stream.addListener(_imageStreamListener!);
  }

  void _unresolveImage() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _onHover(PointerHoverEvent event) {
    setState(() => _hoverPosition = event.localPosition);
  }

  void _onExit(PointerExitEvent event) {
    setState(() => _hoverPosition = null);
  }

  void _onTapDown(TapDownDetails details, Size displaySize) {
    if (_intrinsicImageLogicalSize == null) return;

    final Size intrinsic = _intrinsicImageLogicalSize!;

    final double scaleX = displaySize.width / intrinsic.width;
    final double scaleY = displaySize.height / intrinsic.height;

    final double displayedTileWidth = widget.tileWidth * scaleX;
    final double displayedTileHeight = widget.tileHeight * scaleY;

    final int cols = (intrinsic.width / widget.tileWidth).floor().clamp(
      0,
      1000000,
    );
    final int rows = (intrinsic.height / widget.tileHeight).floor().clamp(
      0,
      1000000,
    );

    if (cols == 0 || rows == 0) return;

    final Offset p = details.localPosition;
    int tileX = (p.dx / displayedTileWidth).floor();
    int tileY = (p.dy / displayedTileHeight).floor();

    tileX = tileX.clamp(0, cols - 1).toInt();
    tileY = tileY.clamp(0, rows - 1).toInt();

    widget.onTileSelected?.call(tileX, tileY);
  }

  @override
  Widget build(BuildContext context) {
    final Size? intrinsic = _intrinsicImageLogicalSize;

    if (intrinsic == null) {
      return const SizedBox.shrink();
    }

    final double width = widget.displayWidth ?? intrinsic.width;
    final double height = widget.displayHeight ?? intrinsic.height;
    final Size displaySize = Size(width, height);

    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _onTapDown(details, displaySize),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: widget.image,
                width: width,
                height: height,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
              CustomPaint(
                painter: _TilesetGridPainter(
                  intrinsicSize: intrinsic,
                  displaySize: displaySize,
                  tileWidth: widget.tileWidth,
                  tileHeight: widget.tileHeight,
                  gridColor: widget.gridColor,
                  highlightColor: widget.highlightColor,
                  hoverPosition: _hoverPosition,
                  selectedX: widget.selectedX,
                  selectedY: widget.selectedY,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TilesetGridPainter extends CustomPainter {
  final Size intrinsicSize;
  final Size displaySize;
  final double tileWidth;
  final double tileHeight;
  final Color gridColor;
  final Color highlightColor;
  final Offset? hoverPosition;
  final int? selectedX;
  final int? selectedY;

  _TilesetGridPainter({
    required this.intrinsicSize,
    required this.displaySize,
    required this.tileWidth,
    required this.tileHeight,
    required this.gridColor,
    required this.highlightColor,
    required this.hoverPosition,
    required this.selectedX,
    required this.selectedY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = displaySize.width / intrinsicSize.width;
    final double scaleY = displaySize.height / intrinsicSize.height;

    final double displayedTileWidth = tileWidth * scaleX;
    final double displayedTileHeight = tileHeight * scaleY;

    final int cols = (intrinsicSize.width / tileWidth).floor();
    final int rows = (intrinsicSize.height / tileHeight).floor();

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;

    for (int x = 0; x <= cols; x++) {
      final double dx = x * displayedTileWidth;
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, rows * displayedTileHeight),
        gridPaint,
      );
    }

    for (int y = 0; y <= rows; y++) {
      final double dy = y * displayedTileHeight;
      canvas.drawLine(
        Offset(0, dy),
        Offset(cols * displayedTileWidth, dy),
        gridPaint,
      );
    }

    if (hoverPosition != null && cols > 0 && rows > 0) {
      final int tileX = (hoverPosition!.dx / displayedTileWidth)
          .floor()
          .clamp(0, cols - 1)
          .toInt();
      final int tileY = (hoverPosition!.dy / displayedTileHeight)
          .floor()
          .clamp(0, rows - 1)
          .toInt();

      final Rect rect = Rect.fromLTWH(
        tileX * displayedTileWidth,
        tileY * displayedTileHeight,
        displayedTileWidth,
        displayedTileHeight,
      );

      final Paint borderPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(rect, borderPaint);

      final Paint highlightPaint = Paint()
        ..color = highlightColor.withAlpha(100)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, highlightPaint);
    }

    // Selected tile persistent highlight
    if (selectedX != null && selectedY != null && cols > 0 && rows > 0) {
      final int sx = selectedX!.clamp(0, cols - 1);
      final int sy = selectedY!.clamp(0, rows - 1);
      final Rect rect = Rect.fromLTWH(
        sx * displayedTileWidth,
        sy * displayedTileHeight,
        displayedTileWidth,
        displayedTileHeight,
      );

      final Paint borderPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TilesetGridPainter oldDelegate) {
    return hoverPosition != oldDelegate.hoverPosition ||
        intrinsicSize != oldDelegate.intrinsicSize ||
        displaySize != oldDelegate.displaySize ||
        tileWidth != oldDelegate.tileWidth ||
        tileHeight != oldDelegate.tileHeight ||
        gridColor != oldDelegate.gridColor ||
        highlightColor != oldDelegate.highlightColor ||
        selectedX != oldDelegate.selectedX ||
        selectedY != oldDelegate.selectedY;
  }
}
