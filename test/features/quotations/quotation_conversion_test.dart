// test/features/quotations/quotation_conversion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/quotations/models/quotation_item_model.dart';
import 'package:hytide/features/quotations/models/quotation_model.dart';
import 'package:hytide/features/quotations/services/quotation_conversion_service.dart';

void main() {
  group('QuotationConversionService Eligibility Tests', () {
    final now = DateTime(2026, 9, 4, 12, 0);

    final item = QuotationItemModel(
      id: 'item-01',
      name: 'Mobile App Development',
      quantity: 1,
      unitPrice: 150000.0,
      lineSubtotal: 150000.0,
      lineTotal: 150000.0,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    final quotation = QuotationModel(
      id: 'quot-100',
      quotationNumber: 'QT-2026-0010',
      clientId: 'client-50',
      clientName: 'Apex Logistics',
      companyName: 'Apex Logistics Ltd',
      contactPerson: 'Karan Mehra',
      clientEmail: 'karan@apexlogistics.in',
      clientPhone: '+91 99999 11111',
      clientAddress: 'Andheri East, Mumbai',
      title: 'Logistics Fleet Tracking App',
      description: 'Native Flutter mobile app and admin dashboard',
      status: QuotationStatus.accepted,
      issueDate: now,
      expiryDate: now.add(const Duration(days: 30)),
      currency: 'INR',
      items: [item],
      subtotal: 150000.0,
      grandTotal: 150000.0,
      assignedTo: 'user-01',
      assignedToName: 'Neha Rao',
      createdBy: 'user-01',
      createdByName: 'Neha Rao',
      createdAt: now,
      updatedAt: now,
    );

    test('validates conversion eligibility for accepted quotation', () {
      expect(quotation.canConvertToProject, isTrue);
      expect(quotation.status, equals(QuotationStatus.accepted));
      expect(quotation.convertedToProject, isFalse);
    });

    test('rejects conversion eligibility if status is draft or sent', () {
      final draft = quotation.copyWith(status: QuotationStatus.draft);
      expect(draft.canConvertToProject, isFalse);

      final sent = quotation.copyWith(status: QuotationStatus.sent);
      expect(sent.canConvertToProject, isFalse);
    });

    test('rejects conversion eligibility if status is rejected or expired', () {
      final rejected = quotation.copyWith(status: QuotationStatus.rejected);
      expect(rejected.canConvertToProject, isFalse);

      final expired = quotation.copyWith(status: QuotationStatus.expired);
      expect(expired.canConvertToProject, isFalse);
    });

    test('rejects duplicate conversion if quotation already converted', () {
      final alreadyConverted = quotation.copyWith(
        status: QuotationStatus.accepted,
        convertedToProject: true,
        projectId: 'project-999',
      );
      expect(alreadyConverted.canConvertToProject, isFalse);
    });

    test('QuotationConversionEligibilityResult encapsulates eligibility state correctly', () {
      const eligibleResult = QuotationConversionEligibilityResult(
        isEligible: true,
      );
      expect(eligibleResult.isEligible, isTrue);
      expect(eligibleResult.message, isNull);
      expect(eligibleResult.existingProjectId, isNull);

      const ineligibleResult = QuotationConversionEligibilityResult(
        isEligible: false,
        message: 'Only accepted quotations can be converted into projects.',
        existingProjectId: 'proj-999',
      );
      expect(ineligibleResult.isEligible, isFalse);
      expect(ineligibleResult.message, contains('accepted quotations'));
      expect(ineligibleResult.existingProjectId, equals('proj-999'));
    });
  });
}
