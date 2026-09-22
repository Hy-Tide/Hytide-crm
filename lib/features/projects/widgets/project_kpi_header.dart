// lib/features/projects/widgets/project_kpi_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/project_filter_model.dart';
import '../providers/project_providers.dart';

class ProjectKpiHeader extends ConsumerWidget {
  const ProjectKpiHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(projectKpiCountsProvider);
    final filter = ref.watch(projectFilterProvider);

    return countsAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, stack) => const SizedBox.shrink(),
      data: (counts) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

            final cards = [
              _KpiCardData(
                label: 'Total Projects',
                count: counts.total,
                icon: Icons.folder_copy_rounded,
                color: AppColors.primary,
                isSelected: !filter.hasActiveFilters,
                onTap: () {
                  ref.read(projectFilterProvider.notifier).state = const ProjectFilter();
                },
              ),
              _KpiCardData(
                label: 'Active',
                count: counts.active,
                icon: Icons.play_circle_outline_rounded,
                color: AppColors.success,
                isSelected: filter.status == ProjectStatus.active && !filter.isOverdueOnly && !filter.isArchived,
                onTap: () {
                  final cur = ref.read(projectFilterProvider);
                  if (cur.status == ProjectStatus.active && !cur.isOverdueOnly) {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(status: () => null);
                  } else {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(
                      status: () => ProjectStatus.active,
                      isOverdueOnly: false,
                      isArchived: false,
                    );
                  }
                },
              ),
              _KpiCardData(
                label: 'Planning',
                count: counts.planning,
                icon: Icons.engineering_rounded,
                color: AppColors.info,
                isSelected: filter.status == ProjectStatus.planning && !filter.isOverdueOnly && !filter.isArchived,
                onTap: () {
                  final cur = ref.read(projectFilterProvider);
                  if (cur.status == ProjectStatus.planning && !cur.isOverdueOnly) {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(status: () => null);
                  } else {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(
                      status: () => ProjectStatus.planning,
                      isOverdueOnly: false,
                      isArchived: false,
                    );
                  }
                },
              ),
              _KpiCardData(
                label: 'On Hold',
                count: counts.onHold,
                icon: Icons.pause_circle_outline_rounded,
                color: AppColors.warning,
                isSelected: filter.status == ProjectStatus.onHold && !filter.isOverdueOnly && !filter.isArchived,
                onTap: () {
                  final cur = ref.read(projectFilterProvider);
                  if (cur.status == ProjectStatus.onHold && !cur.isOverdueOnly) {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(status: () => null);
                  } else {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(
                      status: () => ProjectStatus.onHold,
                      isOverdueOnly: false,
                      isArchived: false,
                    );
                  }
                },
              ),
              _KpiCardData(
                label: 'Completed',
                count: counts.completed,
                icon: Icons.task_alt_rounded,
                color: AppColors.primary,
                isSelected: filter.status == ProjectStatus.completed && !filter.isOverdueOnly && !filter.isArchived,
                onTap: () {
                  final cur = ref.read(projectFilterProvider);
                  if (cur.status == ProjectStatus.completed && !cur.isOverdueOnly) {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(status: () => null);
                  } else {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(
                      status: () => ProjectStatus.completed,
                      isOverdueOnly: false,
                      isArchived: false,
                    );
                  }
                },
              ),
              _KpiCardData(
                label: 'Overdue',
                count: counts.overdue,
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
                isSelected: filter.isOverdueOnly && !filter.isArchived,
                onTap: () {
                  final cur = ref.read(projectFilterProvider);
                  if (cur.isOverdueOnly) {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(isOverdueOnly: false);
                  } else {
                    ref.read(projectFilterProvider.notifier).state = cur.copyWith(
                      isOverdueOnly: true,
                      status: () => null,
                      isArchived: false,
                    );
                  }
                },
              ),
            ];

            if (isMobile) {
              return SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: cards.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => SizedBox(
                    width: 150,
                    child: _KpiCard(data: cards[i]),
                  ),
                ),
              );
            }

            if (isTablet) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: cards
                      .map((c) => SizedBox(
                            width: (constraints.maxWidth - (AppSpacing.lg * 2) - (AppSpacing.md * 2)) / 3,
                            child: _KpiCard(data: c),
                          ))
                      .toList(),
                ),
              );
            }

            // Desktop layout (6 columns)
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: cards
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _KpiCard(data: c),
                          ),
                        ))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: List.generate(
          6,
          (index) => Expanded(
            child: Container(
              height: 84,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCardData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiCardData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
}

class _KpiCard extends StatefulWidget {
  final _KpiCardData data;

  const _KpiCard({required this.data});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final selectedBg = widget.data.color.withValues(alpha: isDark ? 0.22 : 0.12);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.data.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.data.isSelected
                ? selectedBg
                : _isHovered
                    ? widget.data.color.withValues(alpha: 0.05)
                    : baseBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.data.isSelected
                  ? widget.data.color
                  : _isHovered
                      ? widget.data.color.withValues(alpha: 0.5)
                      : (isDark ? AppColors.borderDark : AppColors.border),
              width: widget.data.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.data.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: widget.data.isSelected
                            ? widget.data.color
                            : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                        fontWeight: widget.data.isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    widget.data.icon,
                    size: 18,
                    color: widget.data.color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.data.count.toString(),
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
