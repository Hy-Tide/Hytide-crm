// lib/features/dashboard/widgets/todays_followups_card.dart
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
import '../../followups/models/followup_model.dart';
import '../providers/dashboard_providers.dart';
import '../repositories/dashboard_repository.dart';
import 'section_error_card.dart';

class TodaysFollowupsCard extends ConsumerWidget {
  const TodaysFollowupsCard({super.key});

  Future<void> _handleComplete(
    BuildContext context,
    WidgetRef ref,
    FollowUpModel item,
  ) async {
    try {
      await ref
          .read(dashboardRepositoryProvider)
          .markFollowUpComplete(item.id, item.leadName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked follow-up with ${item.leadName} as complete'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow-up: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReschedule(
    BuildContext context,
    WidgetRef ref,
    FollowUpModel item,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: item.time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null || !context.mounted) return;

    try {
      await ref
          .read(dashboardRepositoryProvider)
          .rescheduleFollowUp(item.id, pickedDate, pickedTime, item.leadName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rescheduled follow-up with ${item.leadName}'),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysAsync = ref.watch(todaysFollowUpsStreamProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      onTap: () => context.go('${AppRoutes.followups}?filter=today'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: "Today's Follow-ups",
            subtitle: "Scheduled customer communications due today",
          ),
          AppSpacing.gapH20,
          todaysAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: "Today's Follow-ups",
              message: 'Failed to load follow-ups: $err',
              onRetry: () => ref.invalidate(todaysFollowUpsStreamProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No follow-ups scheduled',
                  description: 'Your upcoming follow-ups will appear here.',
                  iconSize: 40,
                );
              }

              return ListView.separated(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, index) => const Divider(
                  height: AppSpacing.s20,
                  color: AppColors.surfaceBorder,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildItemRow(context, ref, item);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    WidgetRef ref,
    FollowUpModel item,
  ) {
    final timeStr = item.time.format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeStr,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          AppSpacing.gapW12,

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.leadName.isNotEmpty
                            ? item.leadName
                            : 'Untitled Lead',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.gapW8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH4,
                Row(
                  children: [
                    if (item.assignedToName.isNotEmpty) ...[
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      AppSpacing.gapW4,
                      Text(
                        item.assignedToName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      AppSpacing.gapW12,
                    ],
                    if (item.notes.isNotEmpty)
                      Expanded(
                        child: Text(
                          item.notes,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                tooltip: 'Mark Complete',
                color: AppColors.success,
                onPressed: () => _handleComplete(context, ref, item),
              ),
              IconButton(
                icon: const Icon(Icons.schedule_rounded, size: 20),
                tooltip: 'Reschedule',
                color: AppColors.warning,
                onPressed: () => _handleReschedule(context, ref, item),
              ),
              if (item.leadId.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'Open Lead',
                  color: AppColors.onSurfaceVariant,
                  onPressed: () =>
                      context.go('${AppRoutes.leads}/${item.leadId}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              SkeletonBox(width: 64, height: 28, borderRadius: 6),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 140),
                    SizedBox(height: 6),
                    SkeletonBox(height: 10, width: 90),
                  ],
                ),
              ),
              SkeletonBox(width: 80, height: 28, borderRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
