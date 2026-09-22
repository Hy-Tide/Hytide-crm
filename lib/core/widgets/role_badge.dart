// lib/core/widgets/role_badge.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    switch (role) {
      case UserRole.admin:
        textColor = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFF5F3FF);
        break;
      case UserRole.manager:
        textColor = AppColors.primary;
        bgColor = AppColors.primaryContainer;
        break;
      case UserRole.salesStaff:
        textColor = AppColors.onSurfaceVariant;
        bgColor = AppColors.surfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.badge,
      ),
      child: Text(
        role.displayName,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
