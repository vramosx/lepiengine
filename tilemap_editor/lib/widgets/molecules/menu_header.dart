import 'package:shadcn_flutter/shadcn_flutter.dart';

class MenuHeader extends StatelessWidget {
  final IconData iconData;
  final String title;
  final Widget? actionWidget;
  const MenuHeader({
    super.key,
    required this.iconData,
    required this.title,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, right: 8, bottom: 8),
        child: Row(
          spacing: 16,
          children: [
            Icon(
              iconData,
              color: Theme.of(context).colorScheme.mutedForeground,
              size: 14,
            ),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ).base,
            if (actionWidget != null) ...[Spacer(), actionWidget!],
          ],
        ),
      ),
    );
  }
}
