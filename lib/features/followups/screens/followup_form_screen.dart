// lib/features/followups/screens/followup_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../leads/models/lead_model.dart';
import '../../leads/providers/lead_providers.dart';
import '../../leads/repositories/lead_repository.dart';
import '../models/followup_model.dart';
import '../repositories/followup_repository.dart';

class FollowUpFormScreen extends ConsumerStatefulWidget {
  final String? followUpId;
  final String? initialLeadId;
  final String? initialCompanyName;
  final String? initialDate;

  const FollowUpFormScreen({
    super.key,
    this.followUpId,
    this.initialLeadId,
    this.initialCompanyName,
    this.initialDate,
  });

  @override
  ConsumerState<FollowUpFormScreen> createState() => _FollowUpFormScreenState();
}

class _FollowUpFormScreenState extends ConsumerState<FollowUpFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selected Lead state
  String? _selectedLeadId;
  String _selectedLeadName = '';
  String _selectedCompanyName = '';
  String _selectedContactPhone = '';

  // Form controllers & values
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  FollowUpType _type = FollowUpType.call;
  FollowUpPriority _priority = FollowUpPriority.medium;

  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();

  String? _assignedTo;
  String _assignedToName = '';

  bool _reminderEnabled = true;
  ReminderOption _reminderOption = ReminderOption.thirtyMin;

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Default time is next hour rounded
    final now = DateTime.now();
    _scheduledDate = DateTime(now.year, now.month, now.day);
    _scheduledTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);

    // Initial lead from query params if passed
    if (widget.initialLeadId != null && widget.initialLeadId!.isNotEmpty) {
      _selectedLeadId = widget.initialLeadId;
      _selectedCompanyName = widget.initialCompanyName ?? '';
      _selectedLeadName = widget.initialCompanyName ?? '';
    }

    // Initial date from query params (e.g. calendar slot tap)
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      try {
        _scheduledDate = DateTime.parse(widget.initialDate!);
      } catch (_) {}
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserAndData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _initUserAndData() async {
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;

    if (_assignedTo == null && user != null) {
      _assignedTo = user.uid;
      _assignedToName = user.displayName ?? 'Admin';
    }

    // If initialLeadId was passed, load full lead info
    if (_selectedLeadId != null && _selectedCompanyName.isEmpty) {
      final lead = await ref.read(leadRepositoryProvider).getLeadById(_selectedLeadId!);
      if (lead != null && mounted) {
        setState(() {
          _selectedCompanyName = lead.companyName;
          _selectedLeadName = lead.contactPerson;
          _selectedContactPhone = lead.phone;
        });
      }
    }

    // If editing existing follow-up, load document
    if (widget.followUpId != null) {
      setState(() => _isLoading = true);
      final followup =
          await ref.read(followUpRepositoryProvider).getFollowUp(widget.followUpId!);
      if (followup != null && mounted) {
        setState(() {
          _selectedLeadId = followup.leadId;
          _selectedLeadName = followup.leadName;
          _selectedCompanyName = followup.companyName;
          _titleController.text = followup.title;
          _descController.text = followup.description;
          _type = followup.type;
          _priority = followup.priority;
          _scheduledDate = followup.scheduledAt;
          _scheduledTime = TimeOfDay.fromDateTime(followup.scheduledAt);
          _assignedTo = followup.assignedTo;
          _assignedToName = followup.assignedToName;
          _reminderEnabled = followup.reminderEnabled;
          _reminderOption = ReminderOption.fromMinutes(
            followup.reminderMinutesBefore,
            followup.reminderEnabled,
          );
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLead() async {
    final theme = Theme.of(context);
    final searchController = TextEditingController();
    List<LeadModel> searchResults = [];
    bool isSearching = false;

    // Load initial leads
    final initialBatch = await ref.read(leadRepositoryProvider).getLeadsPaginated(limit: 20);
    searchResults = initialBatch.leads;

    if (!mounted) return;

    final selected = await showModalBottomSheet<LeadModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Text(
                        'Select Lead *',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by company or contact name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    onChanged: (val) async {
                      setModalState(() => isSearching = true);
                      final res = await ref
                          .read(leadRepositoryProvider)
                          .getLeadsPaginated(searchQuery: val.trim(), limit: 20);
                      setModalState(() {
                        searchResults = res.leads;
                        isSearching = false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                Expanded(
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'No matching leads found.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, index) {
                                final lead = searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      lead.companyName.isNotEmpty
                                          ? lead.companyName.substring(0, 1).toUpperCase()
                                          : 'L',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    lead.companyName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${lead.contactPerson} · ${lead.phone}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () => Navigator.of(ctx).pop(lead),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedLeadId = selected.id;
        _selectedCompanyName = selected.companyName;
        _selectedLeadName = selected.contactPerson;
        _selectedContactPhone = selected.phone;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeadId == null || _selectedLeadId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a lead for this follow-up'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final scheduledAt = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    // Validate reminder timing
    if (_reminderEnabled && _reminderOption.minutes != null) {
      final reminderAt = scheduledAt.subtract(Duration(minutes: _reminderOption.minutes!));
      if (reminderAt.isAfter(scheduledAt)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder cannot be after the scheduled follow-up time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authRepositoryProvider);
      final user = auth.currentUser;

      final followup = FollowUpModel(
        id: widget.followUpId ?? '',
        leadId: _selectedLeadId!,
        leadName: _selectedLeadName.isNotEmpty ? _selectedLeadName : _selectedCompanyName,
        companyName: _selectedCompanyName,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _type,
        status: FollowUpStatus.pending,
        priority: _priority,
        scheduledAt: scheduledAt,
        reminderEnabled: _reminderEnabled,
        reminderMinutesBefore: _reminderOption.minutes ?? 0,
        assignedTo: _assignedTo ?? user?.uid ?? '',
        assignedToName: _assignedToName.isNotEmpty ? _assignedToName : (user?.displayName ?? 'Admin'),
        createdBy: user?.uid ?? '',
        createdByName: user?.displayName ?? 'Admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(followUpRepositoryProvider);
      final bus = ref.read(appEventBusProvider);

      if (widget.followUpId != null) {
        await repo.updateFollowUp(followup);
        bus.emit(FollowUpUpdatedEvent(followup));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Follow-up updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final newId = await repo.createFollowUp(followup);
        bus.emit(FollowUpCreatedEvent(followup.copyWith(id: newId)));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Follow-up scheduled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save follow-up: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.followUpId != null;
    final activeUsersAsync = ref.watch(activeUsersProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Follow-up' : 'New Follow-up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.followups);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 1. Lead Selection Card (Only show if not pre-populated from Lead Detail)
                  if (widget.initialLeadId == null || widget.initialLeadId!.isEmpty) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedLeadId == null
                              ? AppColors.warning.withOpacity(0.5)
                              : theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.business_rounded, size: 20, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Linked Lead *',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  icon: Icon(
                                    _selectedLeadId != null
                                        ? Icons.swap_horiz_rounded
                                        : Icons.add_link_rounded,
                                    size: 16,
                                  ),
                                  label: Text(_selectedLeadId != null ? 'Change' : 'Select Lead'),
                                  onPressed: _isSubmitting ? null : _pickLead,
                                ),
                              ],
                            ),
                            if (_selectedLeadId != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _selectedCompanyName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_selectedLeadName.isNotEmpty || _selectedContactPhone.isNotEmpty)
                                Text(
                                  '${_selectedLeadName.isNotEmpty ? _selectedLeadName : ""} · ${_selectedContactPhone.isNotEmpty ? _selectedContactPhone : ""}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ] else
                              Text(
                                'Please choose the lead this follow-up belongs to.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 2. Title & Description
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Follow up regarding quotation discussion',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description / Discussion Points (Optional)',
                      hintText: 'Key topics to discuss, client requirements, pricing notes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Type & Priority Row
                  Row(
                    children: [
                      // Type Dropdown
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<FollowUpType>(
                          value: _type,
                          decoration: InputDecoration(
                            labelText: 'Follow-up Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: FollowUpType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _type = val);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Priority Dropdown
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<FollowUpPriority>(
                          value: _priority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: FollowUpPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 4. Date & Time Selection
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 18),
                          label: Text(
                            DateFormat('MMM d, yyyy').format(_scheduledDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _scheduledDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _scheduledDate = picked);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(
                            _scheduledTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _scheduledTime,
                                  );
                                  if (picked != null) {
                                    setState(() => _scheduledTime = picked);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 5. Assigned User Selection
                  activeUsersAsync.when(
                    data: (users) => DropdownButtonFormField<String>(
                      value: _assignedTo,
                      decoration: InputDecoration(
                        labelText: 'Assigned To',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: users.map((u) {
                        return DropdownMenuItem(
                          value: u.uid,
                          child: Text(u.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final match = users.firstWhere((u) => u.uid == val);
                          setState(() {
                            _assignedTo = val;
                            _assignedToName = match.displayName;
                          });
                        }
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 6. Reminder Settings
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                color: _reminderEnabled
                                    ? AppColors.primary
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Enable Push Reminder',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _reminderEnabled,
                                onChanged: (val) {
                                  setState(() => _reminderEnabled = val);
                                },
                              ),
                            ],
                          ),
                          if (_reminderEnabled) ...[
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<ReminderOption>(
                              value: _reminderOption,
                              decoration: InputDecoration(
                                labelText: 'Reminder Schedule',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: ReminderOption.values
                                  .where((r) => r != ReminderOption.noReminder)
                                  .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r.displayName),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _reminderOption = val);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSubmitting
                            ? 'Saving...'
                            : (isEditing ? 'Update Follow-up' : 'Schedule Follow-up'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
