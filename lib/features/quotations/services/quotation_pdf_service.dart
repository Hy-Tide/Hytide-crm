// lib/features/quotations/services/quotation_pdf_service.dart
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/services/storage_service.dart';
import '../../settings/models/company_settings_model.dart';
import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';

class QuotationPdfService {
  final StorageService _storageService;

  QuotationPdfService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// Generates the raw PDF bytes for a quotation
  Future<Uint8List> generatePdf({
    required QuotationModel quotation,
    CompanySettingsModel company = const CompanySettingsModel(),
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) => _buildHeader(context, quotation, company, dateFormat),
        footer: (pw.Context context) => _buildFooter(context, company),
        build: (pw.Context context) => [
          pw.SizedBox(height: 12),
          _buildClientInfoBox(quotation),
          pw.SizedBox(height: 16),
          _buildItemsTable(quotation.items, inrFormat),
          pw.SizedBox(height: 16),
          _buildTotalsSection(quotation, inrFormat),
          if (quotation.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNotesBox(quotation.notes),
          ],
          if (quotation.termsAndConditions.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildTermsBox(quotation.termsAndConditions),
          ],
          pw.SizedBox(height: 24),
          _buildSignatureBlock(company),
        ],
      ),
    );

    return await pdf.save();
  }

  /// Uploads PDF to Firebase Storage and returns download URL & path
  Future<Map<String, String>> uploadQuotationPdf({
    required String quotationId,
    required String quotationNumber,
    required int version,
    required Uint8List pdfBytes,
  }) async {
    final cleanNumber = quotationNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final storagePath = 'quotations/$quotationId/quotation_${cleanNumber}_v$version.pdf';

    final downloadUrl = await _storageService.uploadFile(
      path: storagePath,
      file: pdfBytes,
      contentType: 'application/pdf',
    );

    return {
      'pdfUrl': downloadUrl,
      'pdfStoragePath': storagePath,
    };
  }

  // ─── Private PDF Builder Helpers ──────────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Context context,
    QuotationModel q,
    CompanySettingsModel company,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company Details
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.companyName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(company.fullAddress, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  pw.Text('Phone: ${company.phone} • Email: ${company.email}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  if (company.gstNumber.isNotEmpty)
                    pw.Text('GSTIN: ${company.gstNumber}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            // Quotation Meta Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'QUOTATION',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('# ${q.quotationNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  if (q.revisionNumber > 1)
                    pw.Text('Revision ${q.revisionNumber}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: ${dateFormat.format(q.issueDate)}', style: const pw.TextStyle(fontSize: 8.5)),
                  pw.Text('Valid Until: ${dateFormat.format(q.expiryDate)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, color: PdfColors.indigo900),
      ],
    );
  }

  pw.Widget _buildClientInfoBox(QuotationModel q) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('QUOTATION FOR:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(q.companyName.isNotEmpty ? q.companyName : q.clientName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (q.contactPerson.isNotEmpty)
                  pw.Text('Attn: ${q.contactPerson}', style: const pw.TextStyle(fontSize: 9)),
                if (q.clientAddress.isNotEmpty)
                  pw.Text(q.clientAddress, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                if (q.clientPhone.isNotEmpty || q.clientEmail.isNotEmpty)
                  pw.Text('${q.clientPhone} • ${q.clientEmail}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROJECT / SUBJECT:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(q.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                if (q.description.isNotEmpty)
                  pw.Text(q.description, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<QuotationItemModel> items, NumberFormat inrFormat) {
    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Item & Description', 'Type', 'Qty', 'Unit Price', 'Disc', 'Tax', 'Total'],
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(1.4),
        6: const pw.FlexColumnWidth(1.2),
        7: const pw.FlexColumnWidth(2.0),
      },
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.centerRight,
      },
      data: List<List<dynamic>>.generate(items.length, (index) {
        final item = items[index];
        final discText = item.discountAmount > 0
            ? inrFormat.format(item.discountAmount)
            : '-';
        final taxText = item.taxPercentage > 0 ? '${item.taxPercentage.toStringAsFixed(0)}%' : '0%';

        return [
          '${index + 1}',
          item.description.isNotEmpty
              ? '${item.name}\n${item.description}'
              : item.name,
          item.itemType.displayName,
          '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
          inrFormat.format(item.unitPrice),
          discText,
          taxText,
          inrFormat.format(item.lineTotal),
        ];
      }),
    );
  }

  pw.Widget _buildTotalsSection(QuotationModel q, NumberFormat inrFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              _buildSummaryRow('Subtotal', inrFormat.format(q.subtotal)),
              if (q.discountAmount > 0)
                _buildSummaryRow('Discount', '- ${inrFormat.format(q.discountAmount)}', isDiscount: true),
              if (q.taxAmount > 0)
                _buildSummaryRow('Tax / GST', inrFormat.format(q.taxAmount)),
              if (q.shippingAmount > 0)
                _buildSummaryRow('Shipping', inrFormat.format(q.shippingAmount)),
              if (q.otherCharges > 0)
                _buildSummaryRow('Other Charges', inrFormat.format(q.otherCharges)),
              pw.Divider(color: PdfColors.grey400),
              _buildSummaryRow(
                'Grand Total',
                inrFormat.format(q.grandTotal),
                isGrandTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isGrandTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 11 : 9,
              fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isGrandTotal ? PdfColors.indigo900 : PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 11 : 9,
              fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount
                  ? PdfColors.red700
                  : isGrandTotal
                      ? PdfColors.indigo900
                      : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotesBox(String notes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 2),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildTermsBox(String terms) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 2),
          pw.Text(terms, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBlock(CompanySettingsModel company) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Bank Details
        if (company.accountNumber.isNotEmpty)
          pw.Container(
            width: 220,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bank Details for Remittance:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                pw.Text('Bank: ${company.bankName}', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('A/C No: ${company.accountNumber}', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('IFSC: ${company.ifscCode}', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          )
        else
          pw.SizedBox(),
        // Signatory
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('For ${company.companyName}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 35),
            pw.Container(width: 140, height: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 3),
            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, CompanySettingsModel company) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${company.companyName} • ${company.website}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }
}
