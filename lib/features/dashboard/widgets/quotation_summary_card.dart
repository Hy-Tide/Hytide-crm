// lib/features/dashboard/widgets/quotation_summary_card.dart
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
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class QuotationSummaryCard extends ConsumerWidget {
  const QuotationSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(quotationSummaryProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Quotation Overview',
            subtitle: 'Commercial proposals across life-cycle stages',
            trailing: TextButton(
              onPressed: () => context.go(AppRoutes.quotations),
              child: const Text('View all quotations'),
            ),
          ),
          AppSpacing.gapH20,
          summaryAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Quotation Overview',
              message: 'Failed to load quotations: $err',
              onRetry: () => ref.invalidate(quotationSummaryProvider),
            ),
            data: (summary) {
              final total = summary.draftCount +
                  summary.sentCount +
                  summary.viewedCount +
                  summary.acceptedCount +
                  summary.rejectedCount +
                  summary.expiredCount;

              if (total == 0) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No quotations created',
                  description:
                      'Create sales estimates and commercial quotations for prospective clients.',
                  iconSize: 40,
                );
              }

              return Column(
                children: [
                  // Prominent Pending Quotations Banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.pending_actions_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Proposals',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${summary.pendingCount} quotations awaiting client decision',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${summary.pendingCount}',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH20,

                  // Status Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusTile(
                          context,
                          status: QuotationStatus.draft,
                          count: summary.draftCount,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: _buildStatusTile(
                          context,
                          status: QuotationStatus.sent,
                          count: summary.sentCount,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: _buildStatusTile(
                          context,
                          status: QuotationStatus.viewed,
                          count: summary.viewedCount,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH8,
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusTile(
                          context,
                          status: QuotationStatus.accepted,
                          count: summary.acceptedCount,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: _buildStatusTile(
                          context,
                          status: QuotationStatus.rejected,
                          count: summary.rejectedCount,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: _buildStatusTile(
                          context,
                          status: QuotationStatus.expired,
                          count: summary.expiredCount,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(
    BuildContext context, {
    required QuotationStatus status,
    required int count,
  }) {
    return InkWell(
      onTap: () => context.go('${AppRoutes.quotations}?status=${status.name}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: status.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status.displayName,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
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
        const SkeletonBox(height: 64, borderRadius: 10),
        AppSpacing.gapH16,
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 54, borderRadius: 8)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 54, borderRadius: 8)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 54, borderRadius: 8)),
          ],
        ),
        AppSpacing.gapH8,
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 54, borderRadius: 8)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 54, borderRadius: 8)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 54, borderRadius: 8)),
          ],
        ),
      ],
    );
  }
}
