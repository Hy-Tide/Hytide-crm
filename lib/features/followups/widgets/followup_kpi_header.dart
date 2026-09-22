// lib/features/followups/widgets/followup_kpi_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/followup_filter_model.dart';
import '../providers/followup_providers.dart';
import '../repositories/followup_repository.dart';

class FollowUpKpiHeader extends ConsumerWidget {
  const FollowUpKpiHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(followUpCountsProvider);
    final activeFilter = ref.watch(followUpFilterProvider);

    return countsAsync.when(
      data: (counts) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600 && !isDesktop;

            final cards = [
              _KpiCard(
                title: "Today's",
                count: counts.today,
                icon: Icons.today_rounded,
                color: AppColors.primary,
                bgColor: AppColors.primaryContainer,
                isSelected: activeFilter.dateFilter == FollowUpDateFilter.today,
                onTap: () {
                  final notifier = ref.read(followUpFilterProvider.notifier);
                  if (activeFilter.dateFilter == FollowUpDateFilter.today) {
                    notifier.state = activeFilter.copyWith(
                      dateFilter: FollowUpDateFilter.all,
                      clearStatus: true,
                    );
                  } else {
                    notifier.state = activeFilter.copyWith(
                      dateFilter: FollowUpDateFilter.today,
                      status: FollowUpStatus.pending,
                    );
                  }
                },
              ),
              _KpiCard(
                title: 'Overdue',
                count: counts.overdue,
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
                bgColor: AppColors.errorContainer,
                isUrgent: counts.overdue > 0,
                isSelected: activeFilter.dateFilter == FollowUpDateFilter.overdue,
                onTap: () {
                  final notifier = ref.read(followUpFilterProvider.notifier);
                  if (activeFilter.dateFilter == FollowUpDateFilter.overdue) {
                    notifier.state = activeFilter.copyWith(
                      dateFilter: FollowUpDateFilter.all,
                      clearStatus: true,
                    );
                  } else {
                    notifier.state = activeFilter.copyWith(
                      dateFilter: FollowUpDateFilter.overdue,
                      status: FollowUpStatus.pending,
                    );
                  }
                },
              ),
              _KpiCard(
                title: 'Upcoming',
                count: counts.upcoming,
                icon: Icons.upcoming_rounded,
                color: AppColors.secondary,
                bgColor: AppColors.secondaryContainer,
                isSelected: activeFilter.dateFilter == FollowUpDateFilter.thisWeek,
                onTap: () {
                  final notifier = ref.read(followUpFilterProvider.notifier);
                  if (activeFilter.dateFilter == FollowUpDateFilter.thisWeek) {
                    notifier.state = activeFilter.copyWith(
                      dateFilter: FollowUpDateFilter.all,
                      clearStatus: true,
                    );
                  } else {
                    notifier.state = activeFilter.copyWith(
                      dateFilter: FollowUpDateFilter.thisWeek,
                      status: FollowUpStatus.pending,
                    );
                  }
                },
              ),
              _KpiCard(
                title: 'High Priority',
                count: counts.highPriority,
                icon: Icons.flag_rounded,
                color: AppColors.warning,
                bgColor: AppColors.warningContainer,
                isSelected: activeFilter.priority == FollowUpPriority.high ||
                    activeFilter.priority == FollowUpPriority.urgent,
                onTap: () {
                  final notifier = ref.read(followUpFilterProvider.notifier);
                  if (activeFilter.priority == FollowUpPriority.high) {
                    notifier.state = activeFilter.copyWith(clearPriority: true);
                  } else {
                    notifier.state = activeFilter.copyWith(
                      priority: FollowUpPriority.high,
                    );
                  }
                },
              ),
              _KpiCard(
                title: 'Completed',
                count: counts.completed,
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                bgColor: AppColors.successContainer,
                isSelected: activeFilter.status == FollowUpStatus.completed,
                onTap: () {
                  final notifier = ref.read(followUpFilterProvider.notifier);
                  if (activeFilter.status == FollowUpStatus.completed) {
                    notifier.state = activeFilter.copyWith(clearStatus: true);
                  } else {
                    notifier.state = activeFilter.copyWith(
                      status: FollowUpStatus.completed,
                      dateFilter: FollowUpDateFilter.all,
                    );
                  }
                },
              ),
            ];

            if (isDesktop) {
              return Row(
                children: cards
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            child: c,
                          ),
                        ))
                    .toList(),
              );
            }

            if (isTablet) {
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cards
                    .map((c) => SizedBox(
                          width: (constraints.maxWidth - (AppSpacing.sm * 2)) / 3,
                          child: c,
                        ))
                    .toList(),
              );
            }

            // Mobile: Horizontal swipeable row
            return SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) => SizedBox(
                  width: 140,
                  child: cards[index],
                ),
              ),
            );
          },
        );
      },
      loading: () => _buildSkeletonHeader(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSkeletonHeader(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 900;
      if (!isDesktop) return const SizedBox(height: 80);
      return Row(
        children: List.generate(
          5,
          (index) => Expanded(
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isUrgent;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isUrgent = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.25 : 0.12)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.2) : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isUrgent ? color : theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
