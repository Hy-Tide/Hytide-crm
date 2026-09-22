// lib/features/documents/widgets/document_table_view.dart
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

class DocumentTableView extends ConsumerWidget {
  final List<DocumentModel> documents;

  const DocumentTableView({super.key, required this.documents});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 860),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: AppSpacing.lg,
              columnSpacing: AppSpacing.lg,
              columns: const [
                DataColumn(label: Text('DOCUMENT NAME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('TYPE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('SIZE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('ASSOCIATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('UPLOADED BY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              ],
              rows: documents.map((doc) {
                return DataRow(
                  cells: [
                    // Document Name + Icon
                    DataCell(
                      InkWell(
                        onTap: () => _openDocument(context, doc),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: doc.iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Icon(doc.icon, color: doc.iconColor, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.name,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Click to view file',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // File Type Chip
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: doc.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: doc.iconColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          doc.fileType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: doc.iconColor,
                          ),
                        ),
                      ),
                    ),

                    // File Size
                    DataCell(
                      doc.isLink
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link_rounded, size: 14, color: AppColors.info),
                                const SizedBox(width: 4),
                                Text(
                                  'External Link',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              doc.sizeBytes.fileSizeFormatted,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                              ),
                            ),
                    ),

                    // Association Chip
                    DataCell(
                      _buildAssociationChip(doc, isDark),
                    ),

                    // Uploaded By
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              doc.uploadedByName.isNotEmpty ? doc.uploadedByName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              doc.uploadedByName.isNotEmpty ? doc.uploadedByName : 'Team Member',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Date
                    DataCell(
                      Text(
                        doc.uploadedAt.formattedDate,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            tooltip: 'Open in new tab',
                            onPressed: () => _openDocument(context, doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.link_rounded, size: 18),
                            tooltip: 'Copy link',
                            onPressed: () => _copyLink(context, doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            tooltip: 'Delete document',
                            onPressed: () => _deleteDocument(context, ref, doc),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
