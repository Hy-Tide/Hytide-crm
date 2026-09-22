// lib/features/followups/widgets/followup_filter_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/followup_filter_model.dart';
import '../providers/followup_providers.dart';

class FollowUpFilterDrawer extends ConsumerStatefulWidget {
  const FollowUpFilterDrawer({super.key});

  @override
  ConsumerState<FollowUpFilterDrawer> createState() => _FollowUpFilterDrawerState();
}

class _FollowUpFilterDrawerState extends ConsumerState<FollowUpFilterDrawer> {
  late FollowUpFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = ref.read(followUpFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeUsersAsync = ref.watch(activeUsersProvider);

    return Drawer(
      width: 380,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Filter Follow-ups',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!_tempFilter.isEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _tempFilter = const FollowUpFilter());
                      },
                      child: const Text('Reset'),
                    ),
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
                  // 1. Date Range
                  _buildSectionTitle(theme, 'Date Range'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: FollowUpDateFilter.values.map((option) {
                      final isSelected = _tempFilter.dateFilter == option;
                      return FilterChip(
                        label: Text(option.displayName),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (option == FollowUpDateFilter.custom && selected) {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (range != null) {
                              setState(() {
                                _tempFilter = _tempFilter.copyWith(
                                  dateFilter: FollowUpDateFilter.custom,
                                  customStartDate: range.start,
                                  customEndDate: range.end,
                                );
                              });
                            }
                          } else {
                            setState(() {
                              _tempFilter = _tempFilter.copyWith(
                                dateFilter: selected ? option : FollowUpDateFilter.all,
                                clearCustomDates: true,
                              );
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. Status
                  _buildSectionTitle(theme, 'Status'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: FollowUpStatus.values.map((status) {
                      final isSelected = _tempFilter.status == status;
                      return ChoiceChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              status: selected ? status : null,
                              clearStatus: !selected,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Priority
                  _buildSectionTitle(theme, 'Priority'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: FollowUpPriority.values.map((priority) {
                      final isSelected = _tempFilter.priority == priority;
                      return ChoiceChip(
                        label: Text(priority.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              priority: selected ? priority : null,
                              clearPriority: !selected,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 4. Follow-up Type
                  _buildSectionTitle(theme, 'Type'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: FollowUpType.values.map((type) {
                      final isSelected = _tempFilter.type == type;
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              type: selected ? type : null,
                              clearType: !selected,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 5. Assigned Staff
                  _buildSectionTitle(theme, 'Assigned Team Member'),
                  activeUsersAsync.when(
                    data: (users) => DropdownButtonFormField<String>(
                      value: _tempFilter.assignedTo,
                      decoration: InputDecoration(
                        hintText: 'All Team Members',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Team Members'),
                        ),
                        ...users.map((u) => DropdownMenuItem(
                              value: u.uid,
                              child: Text(u.displayName),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(
                            assignedTo: val,
                            clearAssignedTo: val == null,
                          );
                        });
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 6. Reminder
                  _buildSectionTitle(theme, 'Reminder'),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _tempFilter.reminderEnabled == null,
                        onSelected: (_) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(clearReminderEnabled: true);
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Reminder Enabled'),
                        selected: _tempFilter.reminderEnabled == true,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              reminderEnabled: selected ? true : null,
                              clearReminderEnabled: !selected,
                            );
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('No Reminder'),
                        selected: _tempFilter.reminderEnabled == false,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              reminderEnabled: selected ? false : null,
                              clearReminderEnabled: !selected,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom action buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(followUpFilterProvider.notifier).state =
                            const FollowUpFilter();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(followUpFilterProvider.notifier).state = _tempFilter;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply Filters'),
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
