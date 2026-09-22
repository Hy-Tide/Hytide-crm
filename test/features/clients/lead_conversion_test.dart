// test/features/clients/lead_conversion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/clients/services/lead_conversion_service.dart';
import 'package:hytide/features/leads/models/lead_model.dart';

void main() {
  group('LeadConversionService Eligibility Tests', () {
    LeadModel createTestLead({
      required LeadStatus status,
      bool convertedToClient = false,
      String? clientId,
    }) {
      return LeadModel(
        id: 'test-lead-1',
        companyName: 'Apex Innovations',
        contactPerson: 'Vikram Seth',
        phone: '+91 98765 00000',
        email: 'vikram@apex.in',
        status: status,
        convertedToClient: convertedToClient,
        clientId: clientId,
        priority: LeadPriority.high,
        leadSource: LeadSource.website,
        assignedTo: 'user-1',
        assignedToName: 'Admin',
        createdBy: 'user-1',
        createdByName: 'Admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('Non-won lead is not eligible for conversion', () {
      final lead = createTestLead(status: LeadStatus.newLead);
      final service = LeadConversionService(
        currentUserId: 'admin-1',
        currentUserName: 'Admin',
      );

      final res = service.checkEligibility(lead);
      expect(res.isEligible, isFalse);
      expect(res.message, contains('Mark the lead as Won before converting it to a client.'));
    });

    test('Already converted lead is not eligible and returns existing clientId', () {
      final lead = createTestLead(
        status: LeadStatus.won,
        convertedToClient: true,
        clientId: 'client-existing-99',
      );
      final service = LeadConversionService(
        currentUserId: 'admin-1',
        currentUserName: 'Admin',
      );

      final res = service.checkEligibility(lead);
      expect(res.isEligible, isFalse);
      expect(res.existingClientId, equals('client-existing-99'));
      expect(res.message, contains('already been converted into a client'));
    });

    test('Lead with status Won and not converted is fully eligible', () {
      final lead = createTestLead(
        status: LeadStatus.won,
        convertedToClient: false,
      );
      final service = LeadConversionService(
        currentUserId: 'admin-1',
        currentUserName: 'Admin',
      );

      final res = service.checkEligibility(lead);
      expect(res.isEligible, isTrue);
      expect(res.message, isNull);
    });
  });
}
