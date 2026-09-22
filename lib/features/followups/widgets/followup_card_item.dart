// lib/features/followups/widgets/followup_card_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/followup_model.dart';
import 'followup_action_dialogs.dart';

class FollowUpCardItem extends ConsumerWidget {
  final FollowUpModel followup;
  final VoidCallback? onTap;

  const FollowUpCardItem({super.key, required this.followup, this.onTap});

  IconData _getTypeIcon(FollowUpType type) {
    switch (type) {
      case FollowUpType.call:
        return Icons.phone_in_talk_rounded;
      case FollowUpType.whatsapp:
        return Icons.chat_rounded;
      case FollowUpType.email:
        return Icons.mail_rounded;
      case FollowUpType.meeting:
        return Icons.groups_rounded;
      case FollowUpType.demo:
        return Icons.laptop_mac_rounded;
      case FollowUpType.siteVisit:
        return Icons.location_on_rounded;
      case FollowUpType.quotationFollowUp:
        return Icons.request_quote_rounded;
      case FollowUpType.paymentFollowUp:
        return Icons.payments_rounded;
      case FollowUpType.general:
        return Icons.task_alt_rounded;
      case FollowUpType.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color _getTypeColor(FollowUpType type) {
    switch (type) {
      case FollowUpType.call:
        return AppColors.info;
      case FollowUpType.whatsapp:
        return const Color(0xFF25D366);
      case FollowUpType.email:
        return AppColors.primary;
      case FollowUpType.meeting:
        return const Color(0xFF8B5CF6);
      case FollowUpType.demo:
        return AppColors.secondary;
      case FollowUpType.siteVisit:
        return const Color(0xFFEC4899);
      case FollowUpType.quotationFollowUp:
        return AppColors.warning;
      case FollowUpType.paymentFollowUp:
        return const Color(0xFF10B981);
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _getPriorityColor(FollowUpPriority priority) {
    switch (priority) {
      case FollowUpPriority.urgent:
        return AppColors.error;
      case FollowUpPriority.high:
        return AppColors.warning;
      case FollowUpPriority.medium:
        return AppColors.secondary;
      case FollowUpPriority.low:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOverdue = followup.isOverdue;
    final typeColor = _getTypeColor(followup.type);
    final priorityColor = _getPriorityColor(followup.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: isOverdue ? 1.5 : 0,
      color: isOverdue
          ? (isDark ? const Color(0xFF2C1517) : const Color(0xFFFFF5F5))
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => context.push('/followups/${followup.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Company name + Type icon badge + Priority + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(followup.type),
                      color: typeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Company & Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                followup.companyName.isNotEmpty
                                    ? followup.companyName
                                    : followup.leadName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (followup.priority == FollowUpPriority.urgent ||
                                followup.priority == FollowUpPriority.high) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  followup.priority.displayName,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          followup.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Context popup menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          context.push('/followups/${followup.id}');
                          break;
                        case 'lead':
                          if (followup.leadId.isNotEmpty) {
                            context.push('/leads/${followup.leadId}');
                          }
                          break;
                        case 'complete':
                          FollowUpActionDialogs.showCompleteDialog(
                            context: context,
                            ref: ref,
                            followup: followup,
                          );
                          break;
                        case 'reschedule':
                          FollowUpActionDialogs.showRescheduleDialog(
                            context: context,
                            ref: ref,
                            followup: followup,
                          );
                          break;
                        case 'cancel':
                          FollowUpActionDialogs.showCancelDialog(
                            context: context,
                            ref: ref,
                            followup: followup,
                          );
                          break;
                        case 'delete':
                          FollowUpActionDialogs.showDeleteDialog(
                            context: context,
                            ref: ref,
                            followup: followup,
                          );
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (followup.leadId.isNotEmpty)
                        const PopupMenuItem(
                          value: 'lead',
                          child: Row(
                            children: [
                              Icon(Icons.person_pin_circle_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('View Lead'),
                            ],
                          ),
                        ),
                      if (followup.status == FollowUpStatus.pending) ...[
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 8),
                              Text('Mark Complete'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reschedule',
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_repeat_rounded,
                                size: 18,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 8),
                              Text('Reschedule'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text('Cancel Follow-up'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Middle row: Schedule info + Overdue warning + Assignee
              Row(
                children: [
                  Icon(
                    isOverdue
                        ? Icons.error_outline_rounded
                        : Icons.schedule_rounded,
                    size: 15,
                    color: isOverdue
                        ? AppColors.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    followup.formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '·',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    followup.formattedTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        followup.overdueDurationString,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Assignee chip
                  if (followup.assignedToName.isNotEmpty) ...[
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        followup.assignedToName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        followup.assignedToName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),

              // Bottom Actions (Only for pending follow-ups)
              if (followup.status == FollowUpStatus.pending) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.event_repeat_rounded, size: 16),
                      label: const Text('Reschedule'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () {
                        FollowUpActionDialogs.showRescheduleDialog(
                          context: context,
                          ref: ref,
                          followup: followup,
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Complete'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: AppColors.successContainer,
                        foregroundColor: AppColors.success,
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
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
