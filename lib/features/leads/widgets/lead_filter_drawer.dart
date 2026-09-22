// lib/features/leads/widgets/lead_filter_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../models/lead_filter_model.dart';
import '../providers/lead_providers.dart';

class LeadFilterDrawer extends ConsumerStatefulWidget {
  const LeadFilterDrawer({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LeadFilterDrawer(),
    );
  }

  @override
  ConsumerState<LeadFilterDrawer> createState() => _LeadFilterDrawerState();
}

class _LeadFilterDrawerState extends ConsumerState<LeadFilterDrawer> {
  late Set<LeadStatus> _selectedStatuses;
  late Set<LeadPriority> _selectedPriorities;
  late Set<LeadSource> _selectedSources;
  String? _selectedAssignedTo;
  String? _selectedAssignedToName;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(leadFilterProvider);
    _selectedStatuses = Set.from(current.statuses);
    _selectedPriorities = Set.from(current.priorities);
    _selectedSources = Set.from(current.sources);
    _selectedAssignedTo = current.assignedTo;
    _selectedAssignedToName = current.assignedToName;
    _isArchived = current.isArchived;
  }

  void _apply() {
    ref.read(leadFilterProvider.notifier).state = LeadFilter(
      statuses: _selectedStatuses,
      priorities: _selectedPriorities,
      sources: _selectedSources,
      assignedTo: _selectedAssignedTo,
      assignedToName: _selectedAssignedToName,
      isArchived: _isArchived,
    );
    Navigator.of(context).pop();
  }

  void _clearAll() {
    setState(() {
      _selectedStatuses.clear();
      _selectedPriorities.clear();
      _selectedSources.clear();
      _selectedAssignedTo = null;
      _selectedAssignedToName = null;
      _isArchived = false;
    });
    ref.read(leadFilterProvider.notifier).state = const LeadFilter();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(activeUsersProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                    AppSpacing.gapW8,
                    Text('Filter Leads', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          // Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s20),
              children: [
                // 1. Status Filter
                Text('Deal Stage / Status', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                AppSpacing.gapH8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeadStatus.values.map((status) {
                    final selected = _selectedStatuses.contains(status);
                    return FilterChip(
                      label: Text(status.displayName),
                      selected: selected,
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedStatuses.add(status);
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                AppSpacing.gapH24,

                // 2. Priority Filter
                Text('Priority Level', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                AppSpacing.gapH8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeadPriority.values.map((priority) {
                    final selected = _selectedPriorities.contains(priority);
                    return FilterChip(
                      label: Text(priority.displayName),
                      selected: selected,
                      selectedColor: AppColors.warningContainer,
                      checkmarkColor: AppColors.warning,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.warning : AppColors.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPriorities.add(priority);
                          } else {
                            _selectedPriorities.remove(priority);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                AppSpacing.gapH24,

                // 3. Lead Source Filter
                Text('Acquisition Channel', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                AppSpacing.gapH8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeadSource.values.map((src) {
                    final selected = _selectedSources.contains(src);
                    return FilterChip(
                      label: Text(src.displayName),
                      selected: selected,
                      selectedColor: AppColors.infoContainer,
                      checkmarkColor: AppColors.info,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.info : AppColors.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedSources.add(src);
                          } else {
                            _selectedSources.remove(src);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                AppSpacing.gapH24,

                // 4. Assigned Staff Filter
                Text('Assigned Team Member', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                AppSpacing.gapH8,
                usersAsync.when(
                  loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, err) => const Text('Unable to load staff list'),
                  data: (users) {
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedAssignedTo,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Team Members'),
                        ),
                        ...users.map((u) {
                          return DropdownMenuItem<String?>(
                            value: u.uid,
                            child: Text('${u.displayName} (${u.role.displayName})'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedAssignedTo = val;
                          if (val != null) {
                            final match = users.firstWhere((u) => u.uid == val, orElse: () => users.first);
                            _selectedAssignedToName = match.displayName;
                          } else {
                            _selectedAssignedToName = null;
                          }
                        });
                      },
                    );
                  },
                ),
                AppSpacing.gapH24,

                // 5. Archive Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show Archived Leads', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View leads that have been archived from the active pipeline'),
                  value: _isArchived,
                  onChanged: (val) => setState(() => _isArchived = val),
                ),
              ],
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: PrimaryButton(
                    label: 'Apply Filters',
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
