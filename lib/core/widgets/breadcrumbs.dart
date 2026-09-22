// lib/core/widgets/breadcrumbs.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class BreadcrumbItem {
  final String label;
  final String? route;

  const BreadcrumbItem({
    required this.label,
    this.route,
  });
}

class Breadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumbs({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isSmall = MediaQuery.of(context).size.width < 768;
    if (isSmall) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            _buildItem(context, items[i], isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, BreadcrumbItem item, {required bool isLast}) {
    final text = Text(
      item.label,
      style: AppTypography.labelMedium.copyWith(
        color: isLast ? AppColors.onSurface : AppColors.onSurfaceVariant,
        fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
      ),
    );

    if (!isLast && item.route != null) {
      return InkWell(
        onTap: () => context.go(item.route!),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: text,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: text,
    );
  }
}
