// lib/features/clients/widgets/client_table_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_avatar.dart';
import '../models/client_model.dart';
import '../providers/client_providers.dart';
import '../repositories/client_repository.dart';

class ClientTableView extends ConsumerWidget {
  final List<ClientModel> clients;
  final VoidCallback? onRefresh;

  const ClientTableView({
    super.key,
    required this.clients,
    this.onRefresh,
  });

  Future<void> _launchCall(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    if (email.trim().isEmpty) return;
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          horizontalMargin: AppSpacing.lg,
          columnSpacing: AppSpacing.xl,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          headingRowColor: WidgetStateProperty.all(
            isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          ),
          columns: const [
            DataColumn(label: Text('CLIENT')),
            DataColumn(label: Text('CONTACT')),
            DataColumn(label: Text('EMAIL')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('PRIORITY')),
            DataColumn(label: Text('ASSIGNED TO')),
            DataColumn(label: Text('NEXT FOLLOW-UP')),
            DataColumn(label: Text('CREATED')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: clients.map((client) {
            final hasFollowUp = client.nextFollowUpAt != null;
            final isOverdue = hasFollowUp && client.nextFollowUpAt!.isBefore(DateTime.now());

            return DataRow(
              onSelectChanged: (_) {
                context.push('${AppRoutes.clients}/${client.id}');
              },
              cells: [
                // 1. Client (Avatar + Company Name + Contact Person)
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppAvatar(name: client.companyName, size: 36),
                      const SizedBox(width: AppSpacing.md),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.companyName,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (client.sourceLeadId != null && client.sourceLeadId!.isNotEmpty)
                              Text(
                                'From Lead',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Contact & Phone
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.contactPerson.isNotEmpty ? client.contactPerson : '—',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (client.phone.isNotEmpty)
                        InkWell(
                          onTap: () => _launchCall(context, client.phone),
                          child: Text(
                            client.phone,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // 3. Email
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: client.email.isNotEmpty
                        ? InkWell(
                            onTap: () => _launchEmail(context, client.email),
                            child: Text(
                              client.email,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : const Text('—', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),

                // 4. Status
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: client.status.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      client.status.displayName,
                      style: AppTypography.caption.copyWith(
                        color: client.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // 5. Priority
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: client.priority.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      client.priority.displayName,
                      style: AppTypography.caption.copyWith(
                        color: client.priority.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // 6. Assigned To
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      client.assignedToName.isNotEmpty ? client.assignedToName : 'Unassigned',
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 7. Next Follow-up
                DataCell(
                  hasFollowUp
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: isOverdue ? AppColors.error : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TimezoneHelper.formatIST(client.nextFollowUpAt!),
                              style: AppTypography.caption.copyWith(
                                color: isOverdue ? AppColors.error : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                                fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : const Text('—', style: TextStyle(color: AppColors.textMuted)),
                ),

                // 8. Created Date
                DataCell(
                  Text(
                    DateFormat('MMM d, yyyy').format(client.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

                // 9. Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'View Profile',
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        onPressed: () => context.push('${AppRoutes.clients}/${client.id}'),
                      ),
                      IconButton(
                        tooltip: 'Edit Client',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => context.push('${AppRoutes.clients}/${client.id}/edit'),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        onSelected: (action) => _handleAction(context, ref, client, action),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'followup',
                            child: Row(
                              children: [
                                Icon(Icons.add_alert_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Schedule Follow-up'),
                              ],
                            ),
                          ),
                          if (client.phone.isNotEmpty) ...[
                            const PopupMenuItem(
                              value: 'call',
                              child: Row(
                                children: [
                                  Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Text('Call'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'whatsapp',
                              child: Row(
                                children: [
                                  Icon(Icons.chat_rounded, size: 16, color: Color(0xFF25D366)),
                                  SizedBox(width: 8),
                                  Text('WhatsApp'),
                                ],
                              ),
                            ),
                          ],
                          if (client.email.isNotEmpty)
                            const PopupMenuItem(
                              value: 'email',
                              child: Row(
                                children: [
                                  Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.info),
                                  SizedBox(width: 8),
                                  Text('Email'),
                                ],
                              ),
                            ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: client.isArchived ? 'restore' : 'archive',
                            child: Row(
                              children: [
                                Icon(
                                  client.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                  size: 16,
                                  color: client.isArchived ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  client.isArchived ? 'Restore Client' : 'Archive Client',
                                  style: TextStyle(
                                    color: client.isArchived ? AppColors.success : AppColors.error,
                                  ),
                                ),
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
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    ClientModel client,
    String action,
  ) async {
    switch (action) {
      case 'followup':
        context.push('${AppRoutes.followups}/create?clientId=${client.id}&clientName=${Uri.encodeComponent(client.companyName)}');
        break;
      case 'call':
        _launchCall(context, client.phone);
        break;
      case 'whatsapp':
        _launchWhatsApp(context, client.phone);
        break;
      case 'email':
        _launchEmail(context, client.email);
        break;
      case 'archive':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Archive Client'),
            content: Text('Are you sure you want to archive "${client.companyName}"? The record and all history will be preserved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Archive'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final repo = ref.read(clientRepositoryProvider);
          await repo.archiveClient(client.id, userId: '', userName: 'Admin');
          ref.read(paginatedClientsProvider.notifier).refresh();
          onRefresh?.call();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client archived')),
            );
          }
        }
        break;
      case 'restore':
        final repo = ref.read(clientRepositoryProvider);
        await repo.restoreClient(client.id, userId: '', userName: 'Admin');
        ref.read(paginatedClientsProvider.notifier).refresh();
        onRefresh?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client restored')),
          );
        }
        break;
    }
  }
}
