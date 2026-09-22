import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/events/app_domain_events.dart';
import '../../../../core/events/app_event_bus.dart';
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

class LeadTableView extends ConsumerWidget {
  final List<LeadModel> leads;
  final VoidCallback? onRefresh;

  const LeadTableView({
    super.key,
    required this.leads,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: AppSpacing.md,
              columnSpacing: AppSpacing.lg,
              border: TableBorder(
                horizontalInside: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Company / Lead',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Contact',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Priority',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Source',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Assigned To',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Next Follow-up',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Est. Value',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
              rows: leads.map((lead) {
                final currencyFmt = NumberFormat.currency(
                  symbol: lead.currency.toUpperCase() == 'INR' ? '₹' : '\$',
                  decimalDigits: 0,
                );
                final valueText = lead.estimatedValue > 0 ? currencyFmt.format(lead.estimatedValue) : '—';
                final isOverdue = lead.nextFollowUpDate != null && lead.nextFollowUpDate!.isBefore(DateTime.now());

                return DataRow(
                  onSelectChanged: (_) => context.go('${AppRoutes.leads}/${lead.id}'),
                  cells: [
                    // Company / Lead
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAvatar(
                            name: lead.companyName.isNotEmpty ? lead.companyName : (lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided'),
                            size: 34,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.companyName.isNotEmpty ? lead.companyName : (lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided'),
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (lead.companyName.isNotEmpty && lead.contactPerson.isNotEmpty)
                                  Text(
                                    lead.contactPerson,
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contact info (phone / email)
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (lead.phone.isNotEmpty)
                              Text(
                                lead.phone,
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (lead.email.isNotEmpty)
                              Text(
                                lead.email,
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Status
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LeadStatusBadge(status: lead.status),
                          if (lead.convertedToClient) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                'Client',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Priority
                    DataCell(PriorityBadge(priority: lead.priority)),

                    // Source
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          lead.leadSource.label,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),

                    // Assigned To
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAvatar(
                            name: lead.assignedToName.isNotEmpty ? lead.assignedToName : 'U',
                            size: 26,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              lead.assignedToName.isNotEmpty ? lead.assignedToName : 'Unassigned',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Next Follow-up
                    DataCell(
                      lead.nextFollowUpDate != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: isOverdue
                                      ? AppColors.error
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(lead.nextFollowUpDate!),
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                                    color: isOverdue
                                        ? AppColors.error
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'None',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                    ),

                    // Est Value
                    DataCell(
                      Text(
                        valueText,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: lead.estimatedValue > 0
                              ? AppColors.primaryBlue
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),

                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lead.phone.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, size: 17),
                              tooltip: 'Call: ${lead.phone}',
                              visualDensity: VisualDensity.compact,
                              color: AppColors.primaryBlue,
                              onPressed: () => LeadLauncherUtils.launchPhone(context, lead.phone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                              tooltip: 'WhatsApp: ${lead.phone}',
                              visualDensity: VisualDensity.compact,
                              color: AppColors.success,
                              onPressed: () => LeadLauncherUtils.launchWhatsApp(context, lead.phone),
                            ),
                          ],
                          if (lead.email.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.email_outlined, size: 17),
                              tooltip: 'Email: ${lead.email}',
                              visualDensity: VisualDensity.compact,
                              color: AppColors.info,
                              onPressed: () => LeadLauncherUtils.launchEmail(context, lead.email),
                            ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 150),
                            onSelected: (action) => _handleTableAction(context, ref, lead, action),
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
                              if (lead.convertedToClient && lead.clientId != null && lead.clientId!.isNotEmpty)
                                const PopupMenuItem(
                                  value: 'view_client',
                                  child: Row(
                                    children: [
                                      Icon(Icons.business_rounded, size: 16, color: AppColors.success),
                                      SizedBox(width: 8),
                                      Text('View Client', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: lead.isArchived ? 'unarchive' : 'archive',
                                child: Row(
                                  children: [
                                    Icon(lead.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 16),
                                    const SizedBox(width: 8),
                                    Text(lead.isArchived ? 'Unarchive' : 'Archive'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _handleTableAction(BuildContext context, WidgetRef ref, LeadModel lead, String action) async {
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
            SnackBar(content: Text(willArchive ? 'Lead archived' : 'Lead unarchived')),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Lead'),
            content: Text('Are you sure you want to delete "${lead.companyName}"? This action cannot be undone.'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lead deleted')),
            );
          }
        }
        break;
    }
  }
}
