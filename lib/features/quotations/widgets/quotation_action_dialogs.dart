// lib/features/quotations/widgets/quotation_action_dialogs.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/quotation_model.dart';

class QuotationActionDialogs {
  /// 1. Send Confirmation Dialog
  static Future<bool> showSendDialog(BuildContext context, QuotationModel q) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.send_rounded, color: AppColors.info, size: 24),
              const SizedBox(width: AppSpacing.sm),
              const Text('Send Quotation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send this quotation to ${q.companyName.isNotEmpty ? q.companyName : q.clientName}?',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quotation: ${q.quotationNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Amount: ${inrFormat.format(q.grandTotal)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('Valid Until: ${dateFormat.format(q.expiryDate)}'),
                    if (q.clientEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Recipient Email: ${q.clientEmail}', style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Quotation'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  /// 2. Mark Accepted Dialog
  static Future<bool> showAcceptDialog(BuildContext context, QuotationModel q) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
              const SizedBox(width: AppSpacing.sm),
              const Text('Mark as Accepted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark quotation ${q.quotationNumber} as accepted by the client?',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This action records acceptance and allows the quotation to be converted into a project.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mark Accepted'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  /// 3. Mark Rejected Dialog (Requires Reason)
  static Future<String?> showRejectDialog(BuildContext context, QuotationModel q) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final res = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.highlight_off_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: AppSpacing.sm),
              const Text('Mark as Rejected'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record rejection for quotation ${q.quotationNumber}. Please provide a reason:',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: controller,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason *',
                    hintText: 'e.g. Budget exceeded, competitor selected, scope cancelled...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a rejection reason';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Confirm Rejection'),
            ),
          ],
        );
      },
    );
    return res;
  }

  /// 4. Convert to Project Dialog
  static Future<String?> showConvertToProjectDialog(BuildContext context, QuotationModel q) async {
    final controller = TextEditingController(text: q.title);
    final formKey = GlobalKey<FormState>();
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final res = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.rocket_launch_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              const Text('Convert to Project'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create deliverable project from accepted quotation ${q.quotationNumber}?',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: ${q.companyName.isNotEmpty ? q.companyName : q.clientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Project Budget: ${inrFormat.format(q.grandTotal)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a project name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              icon: const Icon(Icons.rocket_launch_outlined, size: 16),
              label: const Text('Create Project'),
            ),
          ],
        );
      },
    );
    return res;
  }

  /// 5. Duplicate Confirmation Dialog
  static Future<bool> showDuplicateDialog(BuildContext context, QuotationModel q) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Text('Duplicate Quotation'),
          content: Text(
            'Create a new Draft quotation copying items and pricing from ${q.quotationNumber}?\nA new quotation number will be generated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Duplicate'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  /// 6. Revision Confirmation Dialog
  static Future<bool> showRevisionDialog(BuildContext context, QuotationModel q) async {
    final nextRev = q.revisionNumber + 1;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.history_edu_rounded, color: AppColors.secondary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              const Text('Create Revision'),
            ],
          ),
          content: Text(
            'Create Revision $nextRev for quotation ${q.quotationNumber}?\n'
            'The original quotation will be preserved in history, and a new Draft revision will be created.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Create Revision $nextRev'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }
}
