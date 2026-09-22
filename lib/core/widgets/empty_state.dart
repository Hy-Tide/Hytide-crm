// lib/core/widgets/empty_state.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Premium empty state component with gradient icon container.
/// Use [EmptyState.filtered] for "no search/filter results" variant.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;
  final double iconSize;
  final Color? iconColor;
  final bool isFiltered;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    String? description,
    String? subtitle,
    this.actionLabel,
    this.onAction,
    this.customAction,
    this.iconSize = 40,
    this.iconColor,
    this.isFiltered = false,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : description = description ?? subtitle;

  /// Filtered variant for "no search results" states.
  const EmptyState.filtered({
    super.key,
    required this.title,
    this.description = 'Try adjusting your search or filters.',
    this.actionLabel = 'Clear Filters',
    this.onAction,
    this.customAction,
  })  : icon = Icons.filter_list_off_rounded,
        iconSize = 36,
        iconColor = AppColors.onSurfaceVariant,
        isFiltered = true,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ??
        (isFiltered ? AppColors.onSurfaceVariant : AppColors.primary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container with gradient
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                gradient: isFiltered
                    ? null
                    : LinearGradient(
                        colors: [
                          effectiveIconColor.withValues(alpha: 0.15),
                          effectiveIconColor.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isFiltered
                    ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border.all(
                  color: isFiltered
                      ? (isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder)
                      : effectiveIconColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ),
            AppSpacing.gapH20,

            // Title
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null && description!.isNotEmpty) ...[
              AppSpacing.gapH8,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  description!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            AppSpacing.gapH24,

            // Actions
            if (customAction != null)
              customAction!
            else if (actionLabel != null && onAction != null) ...[
              PrimaryButton(label: actionLabel!, onPressed: onAction),
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                AppSpacing.gapH12,
                SecondaryButton(label: secondaryActionLabel!, onPressed: onSecondaryAction),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
