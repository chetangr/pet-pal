import 'package:flutter/material.dart';

class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool multiline;
  final VoidCallback? onTap;

  const InfoItem({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
    this.multiline = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium,
                    overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}