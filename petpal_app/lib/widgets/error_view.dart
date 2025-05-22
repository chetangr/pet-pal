import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? routeAction;
  final IconData icon;

  const ErrorView({
    Key? key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.routeAction,
    this.icon = Icons.error_outline,
  }) : assert(
         (onAction != null && routeAction == null) ||
         (onAction == null && routeAction != null) ||
         (onAction == null && routeAction == null),
         'Provide either onAction or routeAction, not both',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (onAction != null) {
                    onAction!();
                  } else if (routeAction != null) {
                    context.go(routeAction!);
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