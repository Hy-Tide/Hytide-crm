// lib/features/projects/widgets/project_filter_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/project_filter_model.dart';
import '../providers/project_providers.dart';

class ProjectFilterDrawer extends ConsumerStatefulWidget {
  const ProjectFilterDrawer({super.key});

  @override
  ConsumerState<ProjectFilterDrawer> createState() => _ProjectFilterDrawerState();
}

class _ProjectFilterDrawerState extends ConsumerState<ProjectFilterDrawer> {
  late ProjectFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = ref.read(projectFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffAsync = ref.watch(activeUsersProvider);

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Filter Projects',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 1. Status Filter
                  _buildSectionHeader('Status'),
                  DropdownButtonFormField<ProjectStatus?>(
                    initialValue: _tempFilter.status,
                    decoration: const InputDecoration(hintText: 'All Statuses'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...ProjectStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(status: () => val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Project Type
                  _buildSectionHeader('Project Type'),
                  DropdownButtonFormField<ProjectType?>(
                    initialValue: _tempFilter.projectType,
                    decoration: const InputDecoration(hintText: 'All Types'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ...ProjectType.values.map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.displayName)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(projectType: () => val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Priority
                  _buildSectionHeader('Priority'),
                  DropdownButtonFormField<ProjectPriority?>(
                    initialValue: _tempFilter.priority,
                    decoration: const InputDecoration(hintText: 'All Priorities'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Priorities')),
                      ...ProjectPriority.values.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.displayName)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(priority: () => val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Assigned Staff
                  _buildSectionHeader('Assigned Staff'),
                  staffAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, stack) => const SizedBox.shrink(),
                    data: (staff) {
                      return DropdownButtonFormField<String?>(
                        initialValue: _tempFilter.assignedTo,
                        decoration: const InputDecoration(hintText: 'All Staff Members'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Staff Members')),
                          ...staff.map((s) => DropdownMenuItem(value: s.uid, child: Text(s.displayName))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(assignedTo: () => val);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 5. Date Filter
                  _buildSectionHeader('Date Filter'),
                  DropdownButtonFormField<ProjectDateFilter>(
                    initialValue: _tempFilter.dateFilter,
                    decoration: const InputDecoration(hintText: 'Date Range'),
                    items: ProjectDateFilter.values.map(
                      (d) => DropdownMenuItem(value: d, child: Text(d.displayName)),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(dateFilter: val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. Sort By
                  _buildSectionHeader('Sort By'),
                  DropdownButtonFormField<ProjectSortBy>(
                    initialValue: _tempFilter.sortBy,
                    decoration: const InputDecoration(hintText: 'Sort Order'),
                    items: ProjectSortBy.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(sortBy: val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. Overdue Switch
                  SwitchListTile(
                    title: const Text('Show Overdue Only'),
                    subtitle: const Text('Projects past expected completion date'),
                    contentPadding: EdgeInsets.zero,
                    value: _tempFilter.isOverdueOnly,
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(isOverdueOnly: val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 8. Archived Toggle
                  SwitchListTile(
                    title: const Text('Show Archived Projects'),
                    subtitle: const Text('Include archived/inactive records'),
                    contentPadding: EdgeInsets.zero,
                    value: _tempFilter.isArchived,
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(isArchived: val);
                      });
                    },
                  ),
                ],
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _tempFilter = const ProjectFilter();
                        });
                        ref.read(projectFilterProvider.notifier).state = const ProjectFilter();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(projectFilterProvider.notifier).state = _tempFilter;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
