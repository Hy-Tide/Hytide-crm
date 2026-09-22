// lib/features/followups/widgets/followup_action_dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/followup_model.dart';
import '../repositories/followup_repository.dart';

class FollowUpActionDialogs {
  /// Complete Follow-up Dialog
  static Future<bool?> showCompleteDialog({
    required BuildContext context,
    required WidgetRef ref,
    required FollowUpModel followup,
    VoidCallback? onCreateNext,
  }) async {
    final noteController = TextEditingController();
    bool isSubmitting = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Complete Follow-up'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mark "${followup.title}" with ${followup.companyName} as completed.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Completion Note (Optional)',
                      hintText: 'Discussed pricing, will send revised quotation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          await ref
                              .read(followUpRepositoryProvider)
                              .completeFollowUp(
                                followup.id,
                                completionNote: noteController.text.trim(),
                              );
                          ref.read(appEventBusProvider).emit(
                            FollowUpCompletedEvent(
                              followup.copyWith(
                                status: FollowUpStatus.completed,
                                completionNote: noteController.text.trim(),
                                completedAt: DateTime.now(),
                              ),
                            ),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Follow-up marked as completed'),
                                backgroundColor: AppColors.success,
                                action: onCreateNext != null
                                    ? SnackBarAction(
                                        label: 'Create Next',
                                        textColor: Colors.white,
                                        onPressed: onCreateNext,
                                      )
                                    : null,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to complete: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Reschedule Follow-up Dialog
  static Future<bool?> showRescheduleDialog({
    required BuildContext context,
    required WidgetRef ref,
    required FollowUpModel followup,
  }) async {
    DateTime selectedDate = followup.scheduledAt.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(days: 1))
        : followup.scheduledAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(followup.scheduledAt);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_repeat_rounded,
                      color: AppColors.info, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Reschedule Follow-up'),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reschedule "${followup.title}" with ${followup.companyName}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Date & Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = picked);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.schedule_rounded, size: 16),
                            label: Text(selectedTime.format(context)),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                    );
                                    if (picked != null) {
                                      setState(() => selectedTime = picked);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Reason for Rescheduling *',
                        hintText: 'Client requested postponement, in meeting, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a reason';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => isSubmitting = true);
                        try {
                          final newScheduledAt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          await ref
                              .read(followUpRepositoryProvider)
                              .rescheduleFollowUp(
                                followup.id,
                                newScheduledAt: newScheduledAt,
                                reason: reasonController.text.trim(),
                              );
                          ref.read(appEventBusProvider).emit(
                            FollowUpUpdatedEvent(
                              followup.copyWith(scheduledAt: newScheduledAt),
                            ),
                          );

                          if (ctx.mounted) {
                            Navigator.of(ctx).pop(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Follow-up rescheduled successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to reschedule: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Cancel Follow-up Dialog
  static Future<bool?> showCancelDialog({
    required BuildContext context,
    required WidgetRef ref,
    required FollowUpModel followup,
  }) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Cancel Follow-up'),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to cancel "${followup.title}" with ${followup.companyName}?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Cancellation Reason *',
                        hintText: 'Lead not interested, project dropped, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a cancellation reason';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Follow-up'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => isSubmitting = true);
                        try {
                          await ref
                              .read(followUpRepositoryProvider)
                              .cancelFollowUp(
                                followup.id,
                                reason: reasonController.text.trim(),
                              );
                          ref.read(appEventBusProvider).emit(
                            FollowUpCancelledEvent(
                              followup.copyWith(status: FollowUpStatus.cancelled),
                            ),
                          );

                          if (ctx.mounted) {
                            Navigator.of(ctx).pop(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Follow-up cancelled'),
                                backgroundColor: AppColors.onSurfaceVariant,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to cancel: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Delete Follow-up Dialog
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required WidgetRef ref,
    required FollowUpModel followup,
  }) async {
    bool isSubmitting = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: const Text('Delete Follow-up?'),
            content: Text(
              'Are you sure you want to permanently delete "${followup.title}"? This cannot be undone and will remove it from CRM history.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          await ref
                              .read(followUpRepositoryProvider)
                              .deleteFollowUp(followup.id);
                          ref.read(appEventBusProvider).emit(
                            FollowUpDeletedEvent(followup.id),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Follow-up deleted'),
                                backgroundColor: AppColors.onSurfaceVariant,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }
}
