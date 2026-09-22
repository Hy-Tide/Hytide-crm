// lib/features/clients/widgets/client_filter_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/client_filter_model.dart';
import '../providers/client_providers.dart';

class ClientFilterDrawer extends ConsumerStatefulWidget {
  const ClientFilterDrawer({super.key});

  @override
  ConsumerState<ClientFilterDrawer> createState() => _ClientFilterDrawerState();
}

class _ClientFilterDrawerState extends ConsumerState<ClientFilterDrawer> {
  late ClientFilter _tempFilter;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _tempFilter = ref.read(clientFilterProvider);
    _cityController = TextEditingController(text: _tempFilter.city ?? '');
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
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
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Filter Clients',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter Options Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 1. Status Filter
                  _buildSectionHeader('Status'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: ClientStatus.values.map((status) {
                      final isSelected = _tempFilter.status == status;
                      return ChoiceChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              status: () => selected ? status : null,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Priority Filter
                  _buildSectionHeader('Priority'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: ClientPriority.values.map((priority) {
                      final isSelected = _tempFilter.priority == priority;
                      return ChoiceChip(
                        label: Text(priority.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              priority: () => selected ? priority : null,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Client Type Filter
                  _buildSectionHeader('Client Type'),
                  DropdownButtonFormField<ClientType?>(
                    value: _tempFilter.clientType,
                    decoration: const InputDecoration(
                      hintText: 'All Client Types',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Client Types')),
                      ...ClientType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(clientType: () => val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Industry Filter
                  _buildSectionHeader('Industry'),
                  DropdownButtonFormField<String?>(
                    value: _tempFilter.industry,
                    decoration: const InputDecoration(
                      hintText: 'All Industries',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Industries')),
                      ...clientIndustries.map((ind) => DropdownMenuItem(value: ind, child: Text(ind))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(industry: () => val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 5. Assigned Staff
                  _buildSectionHeader('Assigned Staff'),
                  staffAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (staff) {
                      return DropdownButtonFormField<String?>(
                        value: _tempFilter.assignedTo,
                        decoration: const InputDecoration(
                          hintText: 'All Staff Members',
                        ),
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

                  // 6. City Filter
                  _buildSectionHeader('City'),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      hintText: 'Filter by city (e.g. Mumbai, Delhi)',
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                    onChanged: (val) {
                      _tempFilter = _tempFilter.copyWith(
                        city: () => val.trim().isNotEmpty ? val.trim() : null,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. Date Range Filter
                  _buildSectionHeader('Created Date'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: ClientDateFilter.values.map((df) {
                      final isSelected = _tempFilter.dateFilter == df;
                      return ChoiceChip(
                        label: Text(df.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _tempFilter = _tempFilter.copyWith(dateFilter: df);
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 8. Sort By
                  _buildSectionHeader('Sort Order'),
                  DropdownButtonFormField<ClientSortBy>(
                    value: _tempFilter.sortBy,
                    decoration: const InputDecoration(
                      hintText: 'Sort by',
                    ),
                    items: ClientSortBy.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(sortBy: val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 9. Show Archived Switch
                  SwitchListTile(
                    title: const Text('Show Archived Clients'),
                    subtitle: const Text('Include archived accounts in results'),
                    value: _tempFilter.showArchived,
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(showArchived: val);
                      });
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _tempFilter = const ClientFilter();
                          _cityController.clear();
                        });
                        ref.read(clientFilterProvider.notifier).state = const ClientFilter();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(clientFilterProvider.notifier).state = _tempFilter;
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
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
