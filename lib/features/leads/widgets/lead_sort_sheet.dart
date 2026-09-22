import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/lead_filter_model.dart';
import '../providers/lead_providers.dart';

class LeadSortSheet extends ConsumerWidget {
  const LeadSortSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LeadSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(leadSortProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.3) : AppColors.lightTextSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort Leads',
                  style: AppTypography.heading4.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: LeadSortOption.values.map((option) {
                    final isSelected = option == currentSort;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      leading: Icon(
                        _getIconForSort(option),
                        size: 20,
                        color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      title: Text(
                        option.label,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 20)
                          : null,
                      onTap: () {
                        ref.read(leadSortProvider.notifier).state = option;
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSort(LeadSortOption option) {
    switch (option) {
      case LeadSortOption.recentlyUpdated:
        return Icons.update_rounded;
      case LeadSortOption.newestFirst:
      case LeadSortOption.oldestFirst:
        return Icons.calendar_today_rounded;
      case LeadSortOption.highestValue:
      case LeadSortOption.lowestValue:
        return Icons.attach_money_rounded;
      case LeadSortOption.followupSoonest:
      case LeadSortOption.followupLatest:
        return Icons.access_time_rounded;
      case LeadSortOption.companyAsc:
      case LeadSortOption.companyDesc:
        return Icons.sort_by_alpha_rounded;
    }
  }
}
