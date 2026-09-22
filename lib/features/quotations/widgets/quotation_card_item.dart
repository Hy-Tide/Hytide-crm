// lib/features/quotations/widgets/quotation_card_item.dart
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

class QuotationCardItem extends ConsumerWidget {
  final QuotationModel quotation;
  final void Function(QuotationModel) onPreviewPdf;
  final void Function(QuotationModel) onSend;
  final void Function(QuotationModel) onAccept;
  final void Function(QuotationModel) onReject;
  final void Function(QuotationModel) onConvertToProject;
  final void Function(QuotationModel) onDuplicate;
  final void Function(QuotationModel) onArchive;

  const QuotationCardItem({
    super.key,
    required this.quotation,
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
    final inrFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final effectiveStatus = quotation.effectiveStatus;
    final isExpired = quotation.isExpired;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.quotations}/${quotation.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Quotation Number + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        quotation.quotationNumber,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (quotation.revisionNumber > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            'Rev ${quotation.revisionNumber}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveStatus.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          effectiveStatus.icon,
                          size: 12,
                          color: effectiveStatus.color,
                        ),
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
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Client Name & Contact
              Text(
                quotation.companyName.isNotEmpty
                    ? quotation.companyName
                    : quotation.clientName,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (quotation.contactPerson.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  quotation.contactPerson,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),

              // Title
              Text(
                quotation.title,
                style: AppTypography.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Bottom Row: Dates + Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issued: ${dateFormat.format(quotation.issueDate)}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isExpired
                                ? Icons.warning_amber_rounded
                                : Icons.schedule_rounded,
                            size: 13,
                            color: isExpired
                                ? AppColors.error
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isExpired
                                ? 'Expired'
                                : 'Valid until: ${dateFormat.format(quotation.expiryDate)}',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isExpired ? AppColors.error : null,
                              fontWeight: isExpired ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    inrFormat.format(quotation.grandTotal),
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Quick Action Bar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${AppRoutes.quotations}/${quotation.id}',
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    onPressed: () => onPreviewPdf(quotation),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    tooltip: 'PDF Preview',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    tooltip: 'More',
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          context.push(
                            '${AppRoutes.quotations}/${quotation.id}/edit',
                          );
                          break;
                        case 'send':
                          onSend(quotation);
                          break;
                        case 'accept':
                          onAccept(quotation);
                          break;
                        case 'reject':
                          onReject(quotation);
                          break;
                        case 'convert':
                          onConvertToProject(quotation);
                          break;
                        case 'duplicate':
                          onDuplicate(quotation);
                          break;
                        case 'archive':
                          onArchive(quotation);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (quotation.canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined, size: 18),
                            title: Text('Edit Quotation'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      if (quotation.canSend)
                        const PopupMenuItem(
                          value: 'send',
                          child: ListTile(
                            leading: Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: AppColors.info,
                            ),
                            title: Text('Send to Client'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      if (quotation.canAccept)
                        const PopupMenuItem(
                          value: 'accept',
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppColors.success,
                            ),
                            title: Text('Mark Accepted'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      if (quotation.canReject)
                        const PopupMenuItem(
                          value: 'reject',
                          child: ListTile(
                            leading: Icon(
                              Icons.highlight_off_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            title: Text('Mark Rejected'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      if (quotation.canConvertToProject)
                        const PopupMenuItem(
                          value: 'convert',
                          child: ListTile(
                            leading: Icon(
                              Icons.rocket_launch_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
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
                            quotation.isArchived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                            size: 18,
                          ),
                          title: Text(
                            quotation.isArchived ? 'Restore' : 'Archive',
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
