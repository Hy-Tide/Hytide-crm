// lib/features/dashboard/widgets/conversion_overview_card.dart
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

class ConversionOverviewCard extends ConsumerWidget {
  const ConversionOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversionAsync = ref.watch(dashboardConversionProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Conversion Overview',
            subtitle: 'Outcome ratio of finalized deals',
          ),
          AppSpacing.gapH24,
          conversionAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Conversion Overview',
              message: 'Failed to calculate conversion rate: $err',
              onRetry: () => ref.invalidate(dashboardConversionProvider),
            ),
            data: (stats) => _buildContent(context, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConversionStats stats) {
    final rateProgress = (stats.conversionRate / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        // Central Conversion Indicator
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: rateProgress,
                  strokeWidth: 12,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stats.conversionRate}%',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Win Rate',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapH24,

        // Metric Breakdown Tiles
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context,
                label: 'Total Leads',
                value: '${stats.totalLeads}',
                color: AppColors.primary,
                bgColor: AppColors.primaryContainer,
                icon: Icons.people_outline_rounded,
                onTap: () => context.go(AppRoutes.leads),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: _buildMetricTile(
                context,
                label: 'Won',
                value: '${stats.wonLeads}',
                color: AppColors.success,
                bgColor: AppColors.successContainer,
                icon: Icons.check_circle_outline_rounded,
                onTap: () => context.go('${AppRoutes.leads}?status=won'),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: _buildMetricTile(
                context,
                label: 'Lost',
                value: '${stats.lostLeads}',
                color: AppColors.error,
                bgColor: AppColors.errorContainer,
                icon: Icons.cancel_outlined,
                onTap: () => context.go('${AppRoutes.leads}?status=lost'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Center(
          child: SkeletonBox(width: 140, height: 140, borderRadius: 70),
        ),
        AppSpacing.gapH24,
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 72, borderRadius: 8)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, borderRadius: 8)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, borderRadius: 8)),
          ],
        ),
      ],
    );
  }
}
