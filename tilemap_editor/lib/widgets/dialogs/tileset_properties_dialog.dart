import 'dart:ui' as ui;

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/widgets.dart' hide Form, FormField;

Future<({double tileWidth, double tileHeight})?> showTilesetPropertiesDialog(
  BuildContext context,
  ui.Image image,
) async {
  final FormController controller = FormController();
  final result = await showDialog<({double tileWidth, double tileHeight})>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tileset Properties'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set the tile width and height'),
            const Gap(16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                controller: controller,
                child: const FormTableLayout(
                  rows: [
                    FormField<String>(
                      key: FormKey(#width),
                      label: Text('Width'),
                      child: TextField(initialValue: '32', autofocus: true),
                    ),
                    FormField<String>(
                      key: FormKey(#height),
                      label: Text('Height'),
                      child: TextField(initialValue: '32'),
                    ),
                  ],
                ),
              ).withPadding(vertical: 16),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            child: const Text('Set'),
            onPressed: () {
              final values = controller.values;
              final dynamic widthRaw = values[const FormKey(#width)];
              final dynamic heightRaw = values[const FormKey(#height)];

              final double parsedWidth =
                  double.tryParse(widthRaw?.toString() ?? '') ?? 32;
              final double parsedHeight =
                  double.tryParse(heightRaw?.toString() ?? '') ?? 32;

              final double tileW = parsedWidth
                  .clamp(1.0, image.width.toDouble())
                  .toDouble();
              final double tileH = parsedHeight
                  .clamp(1.0, image.height.toDouble())
                  .toDouble();

              Navigator.of(context).pop((tileWidth: tileW, tileHeight: tileH));
            },
          ),
        ],
      );
    },
  );
  return result;
}
