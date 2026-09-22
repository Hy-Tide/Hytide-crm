// lib/features/quotations/widgets/quotation_pdf_dialog.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/quotation_model.dart';
import '../providers/quotation_providers.dart';
import '../repositories/quotation_repository.dart';
import '../services/quotation_pdf_service.dart';

class QuotationPdfDialog extends ConsumerStatefulWidget {
  final QuotationModel quotation;

  const QuotationPdfDialog({super.key, required this.quotation});

  static Future<void> show(BuildContext context, QuotationModel quotation) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => QuotationPdfDialog(quotation: quotation),
    );
  }

  @override
  ConsumerState<QuotationPdfDialog> createState() => _QuotationPdfDialogState();
}

class _QuotationPdfDialogState extends ConsumerState<QuotationPdfDialog> {
  final _pdfService = QuotationPdfService();
  bool _isUploading = false;
  Uint8List? _cachedPdfBytes;

  Future<Uint8List> _buildPdf() async {
    if (_cachedPdfBytes != null) return _cachedPdfBytes!;
    final company = await ref.read(companySettingsProvider.future);
    final bytes = await _pdfService.generatePdf(
      quotation: widget.quotation,
      company: company,
    );
    _cachedPdfBytes = bytes;
    return bytes;
  }

  Future<void> _uploadToCloudStorage() async {
    setState(() => _isUploading = true);
    try {
      final bytes = await _buildPdf();
      final uploadRes = await _pdfService.uploadQuotationPdf(
        quotationId: widget.quotation.id,
        quotationNumber: widget.quotation.quotationNumber,
        version: widget.quotation.pdfVersion + 1,
        pdfBytes: bytes,
      );

      await ref.read(quotationRepositoryProvider).updatePdfMetadata(
            quotationId: widget.quotation.id,
            pdfUrl: uploadRes['pdfUrl']!,
            pdfStoragePath: uploadRes['pdfStoragePath']!,
            pdfVersion: widget.quotation.pdfVersion + 1,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quotation PDF successfully uploaded to Cloud Storage'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF to storage: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 950),
        child: Column(
          children: [
            // Modal Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Quotation PDF — ${widget.quotation.quotationNumber}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _isUploading ? null : _uploadToCloudStorage,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload_outlined, size: 16),
                        label: Text(_isUploading ? 'Uploading...' : 'Save to Cloud'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Live PDF Preview widget
            Expanded(
              child: PdfPreview(
                build: (_) => _buildPdf(),
                canChangeOrientation: false,
                canChangePageFormat: false,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName: '${widget.quotation.quotationNumber}.pdf',
                previewPageMargin: const EdgeInsets.all(12),
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: (context, buildFn, pageFormat) async {
                      final bytes = await buildFn(pageFormat);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: '${widget.quotation.quotationNumber}.pdf',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
