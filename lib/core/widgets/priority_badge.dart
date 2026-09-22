// lib/core/widgets/priority_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PriorityBadge extends StatelessWidget {
  final dynamic priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String priorityStr;
    if (priority is Enum) {
      priorityStr = (priority as Enum).name;
    } else if (priority is String) {
      priorityStr = priority as String;
    } else {
      priorityStr = priority?.toString() ?? '';
    }

    final lower = priorityStr.toLowerCase();
    Color textColor;
    Color bgColor;

    switch (lower) {
      case 'urgent':
      case 'critical':
      case 'high':
        textColor = AppColors.error;
        break;
      case 'medium':
        textColor = AppColors.warning;
        break;
      case 'low':
      default:
        textColor = AppColors.success;
        break;
    }
    bgColor = textColor.withValues(alpha: 0.15);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : AppSpacing.s8,
        vertical: compact ? 2 : AppSpacing.s4,
      ),
      decoration: BoxDecoration(color: bgColor, borderRadius: AppRadius.badge),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          AppSpacing.gapW4,
          Text(
            priorityStr.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 9 : 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
