// lib/features/documents/widgets/document_grid_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';

class DocumentGridView extends ConsumerWidget {
  final List<DocumentModel> documents;

  const DocumentGridView({super.key, required this.documents});

  Future<void> _openDocument(BuildContext context, DocumentModel doc) async {
    final uri = Uri.tryParse(doc.fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppToast.error(context, 'Could not open document URL');
      }
    }
  }

  void _copyLink(BuildContext context, DocumentModel doc) {
    Clipboard.setData(ClipboardData(text: doc.fileUrl));
    AppToast.info(context, 'Document link copied to clipboard');
  }

  Future<void> _deleteDocument(BuildContext context, WidgetRef ref, DocumentModel doc) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Document',
      message: 'Are you sure you want to delete "${doc.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref.read(documentRepositoryProvider).deleteDocument(doc.id);
      if (doc.fileUrl.isNotEmpty) {
        try {
          await StorageService().deleteFile(doc.fileUrl);
        } catch (_) {}
      }
      if (context.mounted) {
        AppToast.success(context, 'Document deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 850) {
          crossAxisCount = 3;
        } else if (width >= 550) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final doc = documents[index];
            return _buildCard(context, ref, doc);
          },
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, DocumentModel doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Association Badge + 3-dot Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: doc.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(doc.icon, color: doc.iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _buildAssociationChip(doc, isDark),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                padding: EdgeInsets.zero,
                tooltip: 'Document options',
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      _openDocument(context, doc);
                      break;
                    case 'copy':
                      _copyLink(context, doc);
                      break;
                    case 'delete':
                      _deleteDocument(context, ref, doc);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Open in new tab'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Copy URL'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // File Name
          Expanded(
            child: InkWell(
              onTap: () => _openDocument(context, doc),
              child: Text(
                doc.name,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Footer: Size, Date, and Quick View
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doc.isLink
                    ? 'External Link · ${doc.uploadedAt.formattedDate}'
                    : '${doc.sizeBytes.fileSizeFormatted} · ${doc.uploadedAt.formattedDate}',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                tooltip: 'Open document',
                onPressed: () => _openDocument(context, doc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssociationChip(DocumentModel doc, bool isDark) {
    String label = 'General';
    IconData icon = Icons.business_center_outlined;
    Color color = AppColors.secondary;

    if (doc.leadId != null && doc.leadId!.isNotEmpty) {
      label = 'Lead';
      icon = Icons.person_outline_rounded;
      color = AppColors.info;
    } else if (doc.clientId != null && doc.clientId!.isNotEmpty) {
      label = 'Client';
      icon = Icons.business_rounded;
      color = AppColors.success;
    } else if (doc.projectId != null && doc.projectId!.isNotEmpty) {
      label = 'Project';
      icon = Icons.folder_outlined;
      color = AppColors.primary;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
