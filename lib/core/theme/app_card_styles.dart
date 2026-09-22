// lib/core/theme/app_card_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppCardStyles {
  AppCardStyles._();

  static BoxDecoration defaultDecoration({
    Color? color,
    Color? borderColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: borderRadius ?? AppRadius.card,
      border: Border.all(
        color: borderColor ?? AppColors.surfaceBorder,
        width: 1,
      ),
      boxShadow: shadows ?? AppShadows.card,
    );
  }

  static BoxDecoration subtleDecoration() {
    return BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: AppRadius.card,
      border: Border.all(
        color: AppColors.surfaceBorderSubtle,
        width: 1,
      ),
    );
  }
}
