import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../models/lead_activity_model.dart';
import '../providers/lead_providers.dart';

class LeadActivityTimeline extends ConsumerWidget {
  final String leadId;

  const LeadActivityTimeline({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(leadActivitiesStreamProvider(leadId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Error loading activities: $e'),
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No activity recorded yet',
            subtitle: 'Any updates, notes, or status changes will be logged here automatically.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final isLast = index == activities.length - 1;

            return _ActivityTimelineItem(
              activity: activity,
              isLast: isLast,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final LeadActivityModel activity;
  final bool isLast;
  final bool isDark;

  const _ActivityTimelineItem({
    required this.activity,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = activity.color;
    final icon = activity.icon;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        activity.timeAgo,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (activity.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      activity.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'by ${activity.actorName}',
                    style: AppTypography.caption.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
