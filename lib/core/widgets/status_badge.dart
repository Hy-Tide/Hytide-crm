// lib/core/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final bool showDot;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.showDot = false,
    this.compact = false,
  });

  factory StatusBadge.success(String label, {bool showDot = false}) => StatusBadge(
        label: label,
        color: AppColors.success,
        backgroundColor: AppColors.successContainer,
        showDot: showDot,
      );

  factory StatusBadge.warning(String label, {bool showDot = false}) => StatusBadge(
        label: label,
        color: AppColors.warning,
        backgroundColor: AppColors.warningContainer,
        showDot: showDot,
      );

  factory StatusBadge.error(String label, {bool showDot = false}) => StatusBadge(
        label: label,
        color: AppColors.error,
        backgroundColor: AppColors.errorContainer,
        showDot: showDot,
      );

  factory StatusBadge.info(String label, {bool showDot = false}) => StatusBadge(
        label: label,
        color: AppColors.info,
        backgroundColor: AppColors.infoContainer,
        showDot: showDot,
      );

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.onSurfaceVariant;
    final effectiveBg = backgroundColor ?? AppColors.surfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : AppSpacing.s8,
        vertical: compact ? 2 : AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: AppRadius.badge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: effectiveColor,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.gapW4,
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : null,
            ),
          ),
        ],
      ),
    );
  }
}
