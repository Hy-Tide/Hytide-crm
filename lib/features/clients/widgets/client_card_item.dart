// lib/features/clients/widgets/client_card_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class ClientCardItem extends ConsumerWidget {
  final ClientModel client;
  final VoidCallback? onRefresh;

  const ClientCardItem({super.key, required this.client, this.onRefresh});

  Future<void> _launchCall(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    if (email.trim().isEmpty) return;
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasFollowUp = client.nextFollowUpAt != null;
    final isOverdue =
        hasFollowUp && client.nextFollowUpAt!.isBefore(DateTime.now());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.clients}/${client.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Status, and Context Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(name: client.companyName, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.companyName,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.onSurfaceDark
                                : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client.contactPerson.isNotEmpty
                              ? client.contactPerson
                              : 'No Contact Person',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.onSurfaceVariantDark
                                : AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    onSelected: (action) => _handleAction(context, ref, action),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Client'),
                          ],
                        ),
                      ),
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
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: client.isArchived ? 'restore' : 'archive',
                        child: Row(
                          children: [
                            Icon(
                              client.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              size: 16,
                              color: client.isArchived
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              client.isArchived ? 'Restore' : 'Archive',
                              style: TextStyle(
                                color: client.isArchived
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Chips Row: Priority, Client Type, Lead Origin
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: client.priority.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      client.priority.displayName,
                      style: AppTypography.caption.copyWith(
                        color: client.priority.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
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
                      client.clientType.displayName,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (client.sourceLeadId != null &&
                      client.sourceLeadId!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Lead Converted',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Follow-up status
              if (hasFollowUp) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isOverdue ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(
                      color: (isOverdue ? AppColors.error : AppColors.primary)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: isOverdue ? AppColors.error : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Follow-up: ${TimezoneHelper.formatIST(client.nextFollowUpAt!)}',
                        style: AppTypography.caption.copyWith(
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Touch-friendly Action Bar
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (client.phone.isNotEmpty) ...[
                    IconButton(
                      tooltip: 'Call',
                      icon: const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      onPressed: () => _launchCall(context, client.phone),
                    ),
                    IconButton(
                      tooltip: 'WhatsApp',
                      icon: const Icon(
                        Icons.chat_rounded,
                        size: 18,
                        color: Color(0xFF25D366),
                      ),
                      onPressed: () => _launchWhatsApp(context, client.phone),
                    ),
                  ],
                  if (client.email.isNotEmpty)
                    IconButton(
                      tooltip: 'Email',
                      icon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: AppColors.info,
                      ),
                      onPressed: () => _launchEmail(context, client.email),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('${AppRoutes.clients}/${client.id}'),
                    icon: const Icon(Icons.chevron_right_rounded, size: 16),
                    label: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'view':
        context.push('${AppRoutes.clients}/${client.id}');
        break;
      case 'edit':
        context.push('${AppRoutes.clients}/${client.id}/edit');
        break;
      case 'followup':
        context.push(
          '${AppRoutes.followups}/create?clientId=${client.id}&clientName=${Uri.encodeComponent(client.companyName)}',
        );
        break;
      case 'archive':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Archive Client'),
            content: Text(
              'Are you sure you want to archive "${client.companyName}"?',
            ),
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
        }
        break;
      case 'restore':
        final repo = ref.read(clientRepositoryProvider);
        await repo.restoreClient(client.id, userId: '', userName: 'Admin');
        ref.read(paginatedClientsProvider.notifier).refresh();
        onRefresh?.call();
        break;
    }
  }
}
