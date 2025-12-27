import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A section header widget with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null || actionIcon != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: actionIcon != null
                  ? Icon(actionIcon, size: 18)
                  : const SizedBox.shrink(),
              label: Text(actionLabel ?? ''),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
