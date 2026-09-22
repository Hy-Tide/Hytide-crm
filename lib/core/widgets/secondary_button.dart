// lib/core/widgets/secondary_button.dart
import 'package:flutter/material.dart';
import '../theme/app_button_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final double minHeight;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.minHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: AppButtonStyles.secondary(isFullWidth: isFullWidth, minHeight: minHeight),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            AppSpacing.gapW8,
          ],
          Text(
            label,
            style: AppTypography.labelLarge,
          ),
        ],
      ),
    );
  }
}
