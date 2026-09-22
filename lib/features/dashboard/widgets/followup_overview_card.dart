// lib/features/dashboard/widgets/followup_overview_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class FollowupOverviewCard extends ConsumerWidget {
  const FollowupOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardFollowUpSummaryProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Follow-up Overview',
            subtitle: 'Schedule compliance and task execution metrics',
            trailing: TextButton(
              onPressed: () => context.go(AppRoutes.followups),
              child: const Text('View all'),
            ),
          ),
          AppSpacing.gapH20,
          summaryAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Follow-up Overview',
              message: 'Failed to load follow-up counts: $err',
              onRetry: () => ref.invalidate(dashboardFollowUpSummaryProvider),
            ),
            data: (summary) => _buildContent(context, summary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FollowUpSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return GridView.count(
          crossAxisCount: isNarrow ? 1 : 2,
          crossAxisSpacing: AppSpacing.s12,
          mainAxisSpacing: AppSpacing.s12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isNarrow ? 3.0 : 1.7,
          children: [
            _buildTile(
              context,
              label: 'Today',
              count: summary.todayCount,
              icon: Icons.today_rounded,
              color: AppColors.primary,
              bgColor: AppColors.primaryContainer,
              filter: 'today',
            ),
            _buildTile(
              context,
              label: 'Upcoming',
              count: summary.upcomingCount,
              icon: Icons.upcoming_rounded,
              color: AppColors.info,
              bgColor: AppColors.infoContainer,
              filter: 'upcoming',
            ),
            _buildTile(
              context,
              label: 'Overdue',
              count: summary.overdueCount,
              icon: Icons.warning_amber_rounded,
              color: summary.overdueCount > 0 ? AppColors.error : AppColors.onSurfaceVariant,
              bgColor: summary.overdueCount > 0 ? AppColors.errorContainer : AppColors.surfaceVariant,
              filter: 'overdue',
              highlight: summary.overdueCount > 0,
            ),
            _buildTile(
              context,
              label: 'Completed',
              count: summary.completedCount,
              icon: Icons.task_alt_rounded,
              color: AppColors.success,
              bgColor: AppColors.successContainer,
              filter: 'completed',
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String filter,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: () => context.go('${AppRoutes.followups}?filter=$filter'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight ? color.withValues(alpha: 0.4) : AppColors.surfaceBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: highlight ? color : AppColors.onSurfaceVariant,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(
              '$count',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? color : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.s12,
      mainAxisSpacing: AppSpacing.s12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: List.generate(
        4,
        (index) => const SkeletonBox(height: 70, borderRadius: 10),
      ),
    );
  }
}
