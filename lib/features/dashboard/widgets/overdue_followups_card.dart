// lib/features/dashboard/widgets/overdue_followups_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

class OverdueFollowupsCard extends ConsumerWidget {
  const OverdueFollowupsCard({super.key});

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
            content: Text('Completed overdue follow-up for ${item.leadName}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete follow-up: $e'),
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
      await ref.read(dashboardRepositoryProvider).rescheduleFollowUp(
            item.id,
            pickedDate,
            pickedTime,
            item.leadName,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rescheduled follow-up for ${item.leadName}'),
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
    final overdueAsync = ref.watch(overdueFollowUpsStreamProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          overdueAsync.maybeWhen(
            data: (items) => SectionHeader(
              title: 'Needs Attention',
              subtitle: items.isNotEmpty
                  ? '${items.length} overdue communication tasks requiring resolution'
                  : 'All scheduled tasks are on schedule',
              trailing: items.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length} Overdue',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
            orElse: () => const SectionHeader(
              title: 'Needs Attention',
              subtitle: 'Communication tasks requiring resolution',
            ),
          ),
          AppSpacing.gapH20,
          overdueAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Needs Attention',
              message: 'Failed to load overdue follow-ups: $err',
              onRetry: () => ref.invalidate(overdueFollowUpsStreamProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: "You're all caught up",
                  description: 'No overdue follow-ups. Outstanding communications are on schedule.',
                  iconSize: 40,
                );
              }

              return ListView.separated(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, index) => const Divider(
                  height: AppSpacing.s16,
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
    final now = DateTime.now();
    final daysOverdue = now.difference(item.date).inDays;
    final overdueLabel = daysOverdue <= 0
        ? 'Due earlier today'
        : (daysOverdue == 1 ? 'Due 1 day ago' : 'Due $daysOverdue days ago');

    final originalDateStr = DateFormat('MMM d').format(item.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Warning overdue pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.error),
                const SizedBox(height: 2),
                Text(
                  originalDateStr,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ],
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
                        item.leadName.isNotEmpty ? item.leadName : 'Untitled Lead',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.gapW8,
                    Text(
                      overdueLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH4,
                Row(
                  children: [
                    Text(
                      item.type.displayName,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (item.assignedToName.isNotEmpty) ...[
                      Text(' • ', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      Text(
                        item.assignedToName,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
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
                tooltip: 'Complete',
                color: AppColors.success,
                onPressed: () => _handleComplete(context, ref, item),
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                tooltip: 'Reschedule',
                color: AppColors.warning,
                onPressed: () => _handleReschedule(context, ref, item),
              ),
              if (item.leadId.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'Open',
                  color: AppColors.onSurfaceVariant,
                  onPressed: () => context.go('${AppRoutes.leads}/${item.leadId}'),
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
        2,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              SkeletonBox(width: 44, height: 44, borderRadius: 6),
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
              SkeletonBox(width: 72, height: 28, borderRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
