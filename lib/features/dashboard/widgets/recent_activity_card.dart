// lib/features/dashboard/widgets/recent_activity_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/activity_model.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  void _navigateToEntity(BuildContext context, ActivityModel item) {
    if (item.entityId == null || item.entityId!.isEmpty) return;

    switch (item.entityType?.toLowerCase()) {
      case 'lead':
        context.go('${AppRoutes.leads}/${item.entityId}');
        break;
      case 'client':
        context.go('${AppRoutes.clients}/${item.entityId}');
        break;
      case 'project':
        context.go('${AppRoutes.projects}/${item.entityId}');
        break;
      case 'quotation':
        context.go('${AppRoutes.quotations}/${item.entityId}');
        break;
      case 'followup':
        context.go(AppRoutes.followups);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(recentActivitiesStreamProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      onTap: () => context.go(AppRoutes.notifications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Activity',
            subtitle: 'Real-time audit log of team actions and deal updates',
          ),
          AppSpacing.gapH20,
          activitiesAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Recent Activity',
              message: 'Failed to load activity stream: $err',
              onRetry: () => ref.invalidate(recentActivitiesStreamProvider),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No recent activity yet',
                  description:
                      'Audit events such as lead creation, status changes, and follow-up completions will be logged here.',
                  iconSize: 40,
                );
              }

              return ListView.builder(
                itemCount: activities.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = activities[index];
                  final isLast = index == activities.length - 1;
                  return _buildTimelineItem(context, item, isLast);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    ActivityModel item,
    bool isLast,
  ) {
    return InkWell(
      onTap: item.entityId != null
          ? () => _navigateToEntity(context, item)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Node and Connecting Line
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 14, color: item.color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.surfaceBorder,
                      ),
                    ),
                ],
              ),
              AppSpacing.gapW12,

              // Activity Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 4 : AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.relativeTime,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapH4,
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          AppSpacing.gapW4,
                          Text(
                            item.userName,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 28, height: 28, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 120),
                    SizedBox(height: 6),
                    SkeletonBox(height: 12, width: 220),
                    SizedBox(height: 4),
                    SkeletonBox(height: 10, width: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
