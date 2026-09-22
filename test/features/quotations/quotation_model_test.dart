// test/features/quotations/quotation_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/quotations/models/quotation_item_model.dart';
import 'package:hytide/features/quotations/models/quotation_model.dart';

void main() {
  group('QuotationModel Unit Tests', () {
    final now = DateTime(2026, 9, 4, 12, 0);
    final pastDate = now.subtract(const Duration(days: 5));
    final futureDate = now.add(const Duration(days: 10));

    final sampleItem = QuotationItemModel(
      id: 'item-001',
      itemType: QuotationItemType.service,
      name: 'Enterprise ERP Implementation',
      description: 'Full software deployment and setup',
      quantity: 1,
      unit: 'Package',
      unitPrice: 250000.0,
      lineSubtotal: 250000.0,
      discountType: DiscountType.percentage,
      discountValue: 10.0,
      discountAmount: 25000.0,
      taxPercentage: 18.0,
      taxAmount: 40500.0,
      lineTotal: 265500.0,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    final baseQuotation = QuotationModel(
      id: 'quot-001',
      quotationNumber: 'QT-2026-0001',
      revisionNumber: 1,
      clientId: 'client-001',
      clientName: 'TechNova Solutions',
      companyName: 'TechNova Solutions Pvt Ltd',
      contactPerson: 'Suresh Raina',
      clientEmail: 'suresh@technova.com',
      clientPhone: '+91 98888 77777',
      clientAddress: 'HSR Layout, Bengaluru',
      title: 'ERP Automation Platform Proposal',
      description: 'Comprehensive software license and implementation plan',
      status: QuotationStatus.draft,
      issueDate: now,
      expiryDate: futureDate,
      currency: 'INR',
      items: [sampleItem],
      subtotal: 250000.0,
      discountType: DiscountType.percentage,
      discountValue: 10.0,
      discountAmount: 25000.0,
      taxType: TaxType.gst,
      taxPercentage: 18.0,
      taxAmount: 40500.0,
      shippingAmount: 0.0,
      otherCharges: 0.0,
      grandTotal: 265500.0,
      notes: 'Payment schedule: 50% advance, 50% on milestone signoff',
      termsAndConditions: 'Valid for 15 days from issuance',
      assignedTo: 'user-001',
      assignedToName: 'Vikram Mehta',
      createdBy: 'user-001',
      createdByName: 'Vikram Mehta',
      createdAt: now,
      updatedAt: now,
    );

    test('buildSearchTokens creates lowercase tokens for searching', () {
      final tokens = baseQuotation.buildSearchTokens();
      expect(tokens.contains('qt-2026-0001'), isTrue);
      expect(tokens.contains('technova'), isTrue);
      expect(tokens.contains('solutions'), isTrue);
      expect(tokens.contains('suresh'), isTrue);
      expect(tokens.contains('erp'), isTrue);
      expect(tokens.contains('automation'), isTrue);
    });

    test('toMap and serialization retains essential fields', () {
      final map = baseQuotation.toMap();
      expect(map['quotationNumber'], equals('QT-2026-0001'));
      expect(map['status'], equals('draft'));
      expect(map['grandTotal'], equals(265500.0));
      expect(map['items'], isA<List>());
      expect((map['items'] as List).length, equals(1));
    });

    test('workflow permission flags for draft quotation', () {
      expect(baseQuotation.canEdit, isTrue);
      expect(baseQuotation.canSend, isTrue);
      expect(baseQuotation.canAccept, isFalse);
      expect(baseQuotation.canReject, isFalse);
      expect(baseQuotation.canConvertToProject, isFalse);
      expect(baseQuotation.canRevise, isFalse);
    });

    test('workflow permission flags for sent quotation', () {
      final sentQuotation = baseQuotation.copyWith(status: QuotationStatus.sent);
      expect(sentQuotation.canEdit, isFalse);
      expect(sentQuotation.canSend, isTrue); // can resend
      expect(sentQuotation.canAccept, isTrue);
      expect(sentQuotation.canReject, isTrue);
      expect(sentQuotation.canConvertToProject, isFalse);
      expect(sentQuotation.canRevise, isTrue);
    });

    test('workflow permission flags for accepted quotation', () {
      final acceptedQuotation = baseQuotation.copyWith(status: QuotationStatus.accepted);
      expect(acceptedQuotation.canEdit, isFalse);
      expect(acceptedQuotation.canConvertToProject, isTrue);
      expect(acceptedQuotation.canRevise, isTrue);

      final convertedQuotation = acceptedQuotation.copyWith(
        convertedToProject: true,
        projectId: 'proj-001',
      );
      expect(convertedQuotation.canConvertToProject, isFalse);
    });

    test('isExpired detects overdue validity date for pending quotations', () {
      final activeQuote = baseQuotation.copyWith(
        status: QuotationStatus.sent,
        expiryDate: futureDate,
      );
      expect(activeQuote.isExpired, isFalse);
      expect(activeQuote.effectiveStatus, equals(QuotationStatus.sent));

      final expiredQuote = baseQuotation.copyWith(
        status: QuotationStatus.sent,
        expiryDate: pastDate,
      );
      expect(expiredQuote.isExpired, isTrue);
      expect(expiredQuote.effectiveStatus, equals(QuotationStatus.expired));
    });

    test('accepted and converted quotations never marked as expired even if past date', () {
      final acceptedPast = baseQuotation.copyWith(
        status: QuotationStatus.accepted,
        expiryDate: pastDate,
      );
      expect(acceptedPast.isExpired, isFalse);
      expect(acceptedPast.effectiveStatus, equals(QuotationStatus.accepted));
    });
  });
}
