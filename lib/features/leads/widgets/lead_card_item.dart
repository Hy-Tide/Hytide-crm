import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/events/app_domain_events.dart';
import '../../../../core/events/app_event_bus.dart';
import '../../../../core/platform/platform_capabilities.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_badge.dart';
import '../models/lead_model.dart';
import '../providers/lead_providers.dart';
import '../repositories/lead_repository.dart';
import '../utils/lead_launcher_utils.dart';
import 'lead_status_dialog.dart';

class LeadCardItem extends ConsumerWidget {
  final LeadModel lead;
  final VoidCallback? onRefresh;

  const LeadCardItem({super.key, required this.lead, this.onRefresh});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFmt = NumberFormat.currency(
      symbol: lead.currency.toUpperCase() == 'INR' ? '\u20B9' : '\$',
      decimalDigits: 0,
    );
    final valueText = currencyFmt.format(lead.estimatedValue);

    if (PlatformCapabilities.isAndroid) {
      return _buildAndroidCard(context, ref, isDark, valueText);
    }
    return _buildWebCard(context, ref, isDark, valueText);
  }

  // ─── Android card: accent bar + elevated card ───────────────────────────

  Widget _buildAndroidCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    String valueText,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go('${AppRoutes.leads}/${lead.id}');
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name/Company, Arrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      name: lead.companyName.isNotEmpty
                          ? lead.companyName
                          : (lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided'),
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided',
                            style: AppTypography.heading3.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (lead.companyName.isNotEmpty)
                            Text(
                              lead.companyName,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.email_rounded,
                            text: lead.email.isNotEmpty
                                ? lead.email
                                : 'No email',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.phone_rounded,
                            text: lead.phone.isNotEmpty
                                ? lead.phone
                                : 'No phone',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            text: DateFormat(
                              'MMM d, yyyy',
                            ).format(lead.createdAt),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.percent_rounded,
                            text: '${lead.probability}% Probability',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Bottom Row: Status & Value
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lead.status.displayName,
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (lead.estimatedValue > 0)
                      Text(
                        valueText,
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black45),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }



  // ─── Web card (existing layout — unchanged) ─────────────────────────────

  Widget _buildWebCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    String valueText,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => context.go('${AppRoutes.leads}/${lead.id}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Company Name + Status + More Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      name: lead.companyName.isNotEmpty
                          ? lead.companyName
                          : (lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided'),
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.companyName.isNotEmpty
                                ? lead.companyName
                                : (lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided'),
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (lead.companyName.isNotEmpty &&
                              lead.contactPerson.isNotEmpty)
                            Text(
                              lead.contactPerson,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    LeadStatusBadge(status: lead.status),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 150),
                      onSelected: (action) =>
                          _handleAction(context, ref, action),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Lead'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Change Status'),
                            ],
                          ),
                        ),
                        if (lead.convertedToClient &&
                            lead.clientId != null &&
                            lead.clientId!.isNotEmpty)
                          const PopupMenuItem(
                            value: 'view_client',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'View Client',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: lead.isArchived ? 'unarchive' : 'archive',
                          child: Row(
                            children: [
                              Icon(
                                lead.isArchived
                                    ? Icons.unarchive_outlined
                                    : Icons.archive_outlined,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(lead.isArchived ? 'Unarchive' : 'Archive'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 16,
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

                // Middle Info Row: Priority, Source, Value
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PriorityBadge(priority: lead.priority),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        lead.leadSource.label,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    if (lead.convertedToClient)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 10,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Client',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (lead.estimatedValue > 0)
                      Text(
                        valueText,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Assigned To & Follow-up Row
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lead.assignedToName.isNotEmpty
                            ? lead.assignedToName
                            : 'Unassigned',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lead.nextFollowUpDate != null) ...[
                      Icon(
                        Icons.alarm_rounded,
                        size: 14,
                        color: lead.nextFollowUpDate!.isBefore(DateTime.now())
                            ? AppColors.error
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'MMM d, h:mm a',
                        ).format(lead.nextFollowUpDate!),
                        style: AppTypography.caption.copyWith(
                          color: lead.nextFollowUpDate!.isBefore(DateTime.now())
                              ? AppColors.error
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          fontWeight:
                              lead.nextFollowUpDate!.isBefore(DateTime.now())
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),

                // Quick Launchers Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (lead.phone.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        tooltip: 'Call: ${lead.phone}',
                        visualDensity: VisualDensity.compact,
                        color: AppColors.primaryBlue,
                        onPressed: () =>
                            LeadLauncherUtils.launchPhone(context, lead.phone),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        tooltip: 'WhatsApp: ${lead.phone}',
                        visualDensity: VisualDensity.compact,
                        color: AppColors.success,
                        onPressed: () => LeadLauncherUtils.launchWhatsApp(
                          context,
                          lead.phone,
                        ),
                      ),
                    ],
                    if (lead.email.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.email_outlined, size: 18),
                        tooltip: 'Email: ${lead.email}',
                        visualDensity: VisualDensity.compact,
                        color: AppColors.info,
                        onPressed: () =>
                            LeadLauncherUtils.launchEmail(context, lead.email),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'view_client':
        if (lead.clientId != null && lead.clientId!.isNotEmpty) {
          context.go('${AppRoutes.clients}/${lead.clientId}');
        }
        break;
      case 'view':
        context.go('${AppRoutes.leads}/${lead.id}');
        break;
      case 'edit':
        context.go('${AppRoutes.leads}/${lead.id}/edit');
        break;
      case 'status':
        final res = await LeadStatusDialog.showForLead(context, lead);
        if (res != null && res.status != lead.status) {
          final repo = ref.read(leadRepositoryProvider);
          await repo.updateLeadStatus(
            lead.id,
            res.status,
            lostReason: res.lostReason,
            userName: 'Admin',
          );
          ref.read(leadPaginationProvider.notifier).refresh();
          onRefresh?.call();
        }
        break;
      case 'archive':
      case 'unarchive':
        final repo = ref.read(leadRepositoryProvider);
        final willArchive = action == 'archive';
        await repo.toggleArchiveLead(lead.id, willArchive);
        ref.read(leadPaginationProvider.notifier).refresh();
        onRefresh?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willArchive ? 'Lead archived' : 'Lead unarchived'),
            ),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Lead'),
            content: Text(
              'Are you sure you want to delete "${lead.companyName}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final repo = ref.read(leadRepositoryProvider);
          await repo.deleteLead(lead.id);
          ref.read(appEventBusProvider).emit(LeadDeletedEvent(lead.id));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Lead deleted')));
          }
        }
        break;
    }
  }
}


