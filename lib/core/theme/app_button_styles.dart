// lib/core/theme/app_button_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle primary({
    bool isFullWidth = false,
    double minHeight = 40,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s12,
      ),
      minimumSize: Size(isFullWidth ? double.infinity : 0, minHeight),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled))
          return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.primaryDark.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return AppColors.primaryDark.withValues(alpha: 0.24);
        }
        return null;
      }),
    );
  }

  static ButtonStyle secondary({
    bool isFullWidth = false,
    double minHeight = 40,
  }) {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      minimumSize: Size(isFullWidth ? double.infinity : 0, minHeight),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled))
          return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered))
          return AppColors.surfaceVariant;
        return null;
      }),
    );
  }

  static ButtonStyle danger({bool isFullWidth = false, double minHeight = 40}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.onError,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      minimumSize: Size(isFullWidth ? double.infinity : 0, minHeight),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled))
          return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
    );
  }

  static ButtonStyle warning({
    bool isFullWidth = false,
    double minHeight = 40,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.warning,
      foregroundColor: AppColors.onWarning,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      minimumSize: Size(isFullWidth ? double.infinity : 0, minHeight),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled))
          return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
    );
  }

  static ButtonStyle ghost({double minHeight = 36}) {
    return TextButton.styleFrom(
      foregroundColor: AppColors.onSurfaceVariant,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      minimumSize: Size(0, minHeight),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.labelMedium,
    ).copyWith(
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled))
          return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
    );
  }

  static ButtonStyle icon({double size = 36}) {
    return IconButton.styleFrom(
      minimumSize: Size(size, size),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
    ).copyWith(mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click));
  }
}
