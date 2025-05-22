import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final VoidCallback? onAction;
  final double? iconSize;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
    this.onAction,
    this.iconSize,
    this.iconColor,
  }) : assert(
         (actionRoute != null && onAction == null) ||
         (actionRoute == null && onAction != null) ||
         (actionRoute == null && onAction == null),
         'Provide either actionRoute or onAction, not both',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize ?? 80,
              color: iconColor ?? colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (actionRoute != null) {
                    context.push(actionRoute!);
                  } else if (onAction != null) {
                    onAction!();
                  }
                },
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}