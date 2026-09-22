// lib/features/quotations/widgets/quotation_table_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../models/quotation_model.dart';

class QuotationTableView extends ConsumerWidget {
  final List<QuotationModel> quotations;
  final void Function(QuotationModel) onPreviewPdf;
  final void Function(QuotationModel) onSend;
  final void Function(QuotationModel) onAccept;
  final void Function(QuotationModel) onReject;
  final void Function(QuotationModel) onConvertToProject;
  final void Function(QuotationModel) onDuplicate;
  final void Function(QuotationModel) onArchive;

  const QuotationTableView({
    super.key,
    required this.quotations,
    required this.onPreviewPdf,
    required this.onSend,
    required this.onAccept,
    required this.onReject,
    required this.onConvertToProject,
    required this.onDuplicate,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1050),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.backgroundDark : AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 68,
              horizontalMargin: AppSpacing.lg,
              columnSpacing: AppSpacing.lg,
              columns: const [
                DataColumn(label: Text('Quotation #', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Subject / Title', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Issue Date', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Created By', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: quotations.map((q) {
                final effectiveStatus = q.effectiveStatus;
                final isExpired = q.isExpired;

                return DataRow(
                  onSelectChanged: (_) => context.push('${AppRoutes.quotations}/${q.id}'),
                  cells: [
                    // 1. Quotation #
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.quotationNumber,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (q.revisionNumber > 1)
                            Text(
                              'Rev ${q.revisionNumber}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 2. Client
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.companyName.isNotEmpty ? q.companyName : q.clientName,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (q.contactPerson.isNotEmpty)
                            Text(
                              q.contactPerson,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // 3. Title
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.title,
                              style: AppTypography.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${q.items.length} ${q.items.length == 1 ? "item" : "items"}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. Issue Date
                    DataCell(
                      Text(
                        dateFormat.format(q.issueDate),
                        style: AppTypography.bodySmall,
                      ),
                    ),

                    // 5. Expiry Date
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(q.expiryDate),
                            style: AppTypography.bodySmall.copyWith(
                              color: isExpired ? AppColors.error : null,
                              fontWeight: isExpired ? FontWeight.w600 : null,
                            ),
                          ),
                          if (isExpired && q.status != QuotationStatus.accepted && q.status != QuotationStatus.rejected)
                            Text(
                              'Expired',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 6. Amount
                    DataCell(
                      Text(
                        inrFormat.format(q.grandTotal),
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                        ),
                      ),
                    ),

                    // 7. Status Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: effectiveStatus.backgroundColor,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(effectiveStatus.icon, size: 12, color: effectiveStatus.color),
                            const SizedBox(width: 4),
                            Text(
                              effectiveStatus.displayName,
                              style: AppTypography.labelSmall.copyWith(
                                color: effectiveStatus.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 8. Created By
                    DataCell(
                      Text(
                        q.createdByName.isNotEmpty ? q.createdByName : 'Admin',
                        style: AppTypography.bodySmall,
                      ),
                    ),

                    // 9. Actions Menu
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        tooltip: 'Actions',
                        onSelected: (action) {
                          switch (action) {
                            case 'view':
                              context.push('${AppRoutes.quotations}/${q.id}');
                              break;
                            case 'edit':
                              context.push('${AppRoutes.quotations}/${q.id}/edit');
                              break;
                            case 'preview':
                              onPreviewPdf(q);
                              break;
                            case 'send':
                              onSend(q);
                              break;
                            case 'accept':
                              onAccept(q);
                              break;
                            case 'reject':
                              onReject(q);
                              break;
                            case 'convert':
                              onConvertToProject(q);
                              break;
                            case 'duplicate':
                              onDuplicate(q);
                              break;
                            case 'archive':
                              onArchive(q);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: ListTile(
                              leading: Icon(Icons.visibility_outlined, size: 18),
                              title: Text('View Details'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          if (q.canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined, size: 18),
                                title: Text('Edit Quotation'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'preview',
                            child: ListTile(
                              leading: Icon(Icons.picture_as_pdf_outlined, size: 18),
                              title: Text('PDF Preview & Share'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          if (q.canSend)
                            const PopupMenuItem(
                              value: 'send',
                              child: ListTile(
                                leading: Icon(Icons.send_rounded, size: 18, color: AppColors.info),
                                title: Text('Send to Client'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          if (q.canAccept)
                            const PopupMenuItem(
                              value: 'accept',
                              child: ListTile(
                                leading: Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                                title: Text('Mark Accepted'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          if (q.canReject)
                            const PopupMenuItem(
                              value: 'reject',
                              child: ListTile(
                                leading: Icon(Icons.highlight_off_rounded, size: 18, color: AppColors.error),
                                title: Text('Mark Rejected'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          if (q.canConvertToProject)
                            const PopupMenuItem(
                              value: 'convert',
                              child: ListTile(
                                leading: Icon(Icons.rocket_launch_outlined, size: 18, color: AppColors.primary),
                                title: Text('Convert to Project'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: ListTile(
                              leading: Icon(Icons.copy_rounded, size: 18),
                              title: Text('Duplicate'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: ListTile(
                              leading: Icon(
                                q.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                size: 18,
                              ),
                              title: Text(q.isArchived ? 'Restore' : 'Archive'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
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
}
