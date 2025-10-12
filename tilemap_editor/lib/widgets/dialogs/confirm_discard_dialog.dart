import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/widgets.dart';

Future<bool> showConfirmDiscardDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'Existem alterações não salvas. Esta ação é irreversível. Continuar?',
        ),
        actions: [
          OutlineButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          DestructiveButton(
            child: const Text('Discard'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    },
  );
  return result == true;
}
