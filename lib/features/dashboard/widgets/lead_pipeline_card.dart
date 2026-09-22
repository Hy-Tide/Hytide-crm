// lib/features/dashboard/widgets/lead_pipeline_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class LeadPipelineCard extends ConsumerWidget {
  const LeadPipelineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipelineAsync = ref.watch(dashboardPipelineProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      onTap: () => context.go(AppRoutes.leads),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Lead Pipeline',
            subtitle: 'Stage-by-stage distribution of active deals',
          ),
          AppSpacing.gapH20,
          pipelineAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Lead Pipeline',
              message: 'Failed to load pipeline stages: $err',
              onRetry: () => ref.invalidate(dashboardPipelineProvider),
            ),
            data: (items) {
              final totalCount = items.fold<int>(0, (sum, i) => sum + i.count);
              if (totalCount == 0) {
                return const EmptyState(
                  icon: Icons.filter_alt_outlined,
                  title: 'No leads yet',
                  description:
                      'Create your first lead to start building your pipeline.',
                  iconSize: 40,
                );
              }

              return Column(
                children: [
                  // Segmented Bar at top
                  _buildSegmentedBar(items, totalCount),
                  AppSpacing.gapH20,
                  // Status list with progress bars
                  ...items.map(
                    (item) => _buildStageRow(context, item, totalCount),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedBar(List<LeadPipelineItem> items, int total) {
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: items.where((i) => i.count > 0).map((item) {
            return Expanded(
              flex: (item.percentage * 10).round().clamp(1, 1000),
              child: Container(
                color: item.status.color,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStageRow(
    BuildContext context,
    LeadPipelineItem item,
    int total,
  ) {
    final ratio = total > 0 ? (item.count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: InkWell(
        onTap: () =>
            context.go('${AppRoutes.leads}?status=${item.status.name}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Text(
                      item.status.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapW12,
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${item.percentage}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  AppSpacing.gapW4,
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: item.status.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(item.status.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        8,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: Row(
            children: const [
              SkeletonBox(width: 12, height: 12, borderRadius: 6),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 14)),
              SizedBox(width: 16),
              SkeletonBox(width: 32, height: 14),
              SizedBox(width: 8),
              SkeletonBox(width: 36, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
