import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../leads/models/lead_model.dart';
import '../../leads/repositories/lead_repository.dart';
import '../models/followup_model.dart';
import '../providers/followup_providers.dart';
import '../widgets/followup_action_dialogs.dart';
import '../widgets/followup_notes_section.dart';

class FollowUpDetailScreen extends ConsumerStatefulWidget {
  final String followUpId;

  const FollowUpDetailScreen({
    super.key,
    required this.followUpId,
  });

  @override
  ConsumerState<FollowUpDetailScreen> createState() => _FollowUpDetailScreenState();
}

class _FollowUpDetailScreenState extends ConsumerState<FollowUpDetailScreen> {
  LeadModel? _lead;

  @override
  void initState() {
    super.initState();
    _loadLinkedLead();
  }

  Future<void> _loadLinkedLead() async {
    final followup =
        await ref.read(followUpDetailStreamProvider(widget.followUpId).future);
    if (followup != null && followup.leadId.isNotEmpty) {
      final lead = await ref.read(leadRepositoryProvider).getLeadById(followup.leadId);
      if (mounted) {
        setState(() {
          _lead = lead;
        });
      }
    }
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this lead')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call to $cleanPhone')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for WhatsApp')),
      );
      return;
    }
    var cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '91$cleanPhone'; // Default country code if missing
    } else {
      cleanPhone = cleanPhone.replaceAll('+', '');
    }

    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp for $cleanPhone')),
        );
      }
    }
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address recorded for this lead')),
      );
      return;
    }
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email client for ${email.trim()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final followupAsync = ref.watch(followUpDetailStreamProvider(widget.followUpId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Details'),
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
      body: followupAsync.when(
        data: (followup) {
          if (followup == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 56, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Follow-up not found or has been deleted.'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.followups),
                    child: const Text('Back to Follow-ups'),
                  ),
                ],
              ),
            );
          }

          final isOverdue = followup.isOverdue;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Top Card: Lead Header & Quick Communication Actions
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isOverdue
                              ? AppColors.error.withOpacity(0.5)
                              : theme.colorScheme.outlineVariant.withOpacity(0.5),
                          width: isOverdue ? 1.5 : 1.0,
                        ),
                      ),
                      color: isOverdue
                          ? (isDark ? const Color(0xFF2C1517) : const Color(0xFFFFF5F5))
                          : theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Type icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        followup.title,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          if (followup.leadId.isNotEmpty) {
                                            context.push('/leads/${followup.leadId}');
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              followup.companyName.isNotEmpty
                                                  ? followup.companyName
                                                  : followup.leadName,
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_outward_rounded,
                                              size: 14,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_lead?.contactPerson != null &&
                                          _lead!.contactPerson.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Contact: ${_lead!.contactPerson} · ${_lead?.phone ?? ""}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Status chip
                                _buildStatusBadge(followup),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.lg),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.md),

                            // Quick Contact Launchers (tel, whatsapp, mailto)
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.phone_rounded, size: 16),
                                  label: const Text('Call'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.infoContainer,
                                    foregroundColor: AppColors.info,
                                  ),
                                  onPressed: () => _launchPhone(_lead?.phone),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.chat_rounded, size: 16),
                                  label: const Text('WhatsApp'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFDCF8C6),
                                    foregroundColor: const Color(0xFF075E54),
                                  ),
                                  onPressed: () => _launchWhatsApp(_lead?.phone),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.mail_outline_rounded, size: 16),
                                  label: const Text('Email'),
                                  onPressed: () => _launchEmail(_lead?.email),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Key Details Grid (Type, Schedule, Priority, Assignee, Reminder)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule & Details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.xl,
                              runSpacing: AppSpacing.md,
                              children: [
                                _buildInfoTile(
                                  theme,
                                  'Scheduled Date & Time',
                                  followup.formattedDateTime,
                                  subtitle: isOverdue ? followup.overdueDurationString : null,
                                  subtitleColor: AppColors.error,
                                ),
                                _buildInfoTile(
                                  theme,
                                  'Follow-up Type',
                                  followup.type.displayName,
                                ),
                                _buildInfoTile(
                                  theme,
                                  'Priority',
                                  followup.priority.displayName,
                                ),
                                _buildInfoTile(
                                  theme,
                                  'Assigned To',
                                  followup.assignedToName.isNotEmpty
                                      ? followup.assignedToName
                                      : 'Unassigned',
                                ),
                                _buildInfoTile(
                                  theme,
                                  'Push Reminder',
                                  followup.reminderEnabled
                                      ? '${followup.reminderMinutesBefore} minutes before'
                                      : 'Disabled',
                                  subtitle: followup.reminderSent
                                      ? 'Reminder sent to device'
                                      : null,
                                  subtitleColor: AppColors.success,
                                ),
                              ],
                            ),

                            if (followup.description.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Description / Notes',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                followup.description,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],

                            // Completion note
                            if (followup.completionNote != null &&
                                followup.completionNote!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.successContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 18, color: AppColors.success),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Completion Note: ${followup.completionNote}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Reschedule reason
                            if (followup.rescheduleReason != null &&
                                followup.rescheduleReason!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.infoContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_repeat,
                                        size: 18, color: AppColors.info),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Reschedule Reason: ${followup.rescheduleReason}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Cancel reason
                            if (followup.cancelReason != null &&
                                followup.cancelReason!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cancel_outlined,
                                        size: 18, color: AppColors.error),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Cancellation Reason: ${followup.cancelReason}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Action Toolbar: Complete, Reschedule, Edit, Cancel, Delete
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (followup.status == FollowUpStatus.pending) ...[
                          FilledButton.icon(
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Complete Follow-up'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            onPressed: () {
                              FollowUpActionDialogs.showCompleteDialog(
                                context: context,
                                ref: ref,
                                followup: followup,
                                onCreateNext: () => context.push(
                                  '${AppRoutes.followupCreate}?leadId=${followup.leadId}&companyName=${Uri.encodeComponent(followup.companyName)}',
                                ),
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.event_repeat_rounded),
                            label: const Text('Reschedule'),
                            onPressed: () {
                              FollowUpActionDialogs.showRescheduleDialog(
                                context: context,
                                ref: ref,
                                followup: followup,
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                            onPressed: () {
                              context.push('/followups/${followup.id}/edit');
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                            label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                            onPressed: () {
                              FollowUpActionDialogs.showCancelDialog(
                                context: context,
                                ref: ref,
                                followup: followup,
                              );
                            },
                          ),
                        ],
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                          onPressed: () async {
                            final deleted = await FollowUpActionDialogs.showDeleteDialog(
                              context: context,
                              ref: ref,
                              followup: followup,
                            );
                            if (deleted == true && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Internal Notes Subcollection
                    FollowUpNotesSection(followUpId: followup.id),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading follow-up: $err')),
      ),
    );
  }

  Widget _buildStatusBadge(FollowUpModel followup) {
    Color color = AppColors.primary;
    String label = followup.status.displayName;

    if (followup.status == FollowUpStatus.completed) {
      color = AppColors.success;
    } else if (followup.status == FollowUpStatus.cancelled) {
      color = AppColors.onSurfaceVariant;
    } else if (followup.isOverdue) {
      color = AppColors.error;
      label = 'Overdue';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme,
    String label,
    String value, {
    String? subtitle,
    Color? subtitleColor,
  }) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
