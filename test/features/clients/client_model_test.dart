// test/features/clients/client_model_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/clients/models/client_filter_model.dart';
import 'package:hytide/features/clients/models/client_model.dart';

void main() {
  group('ClientModel Unit Tests', () {
    final now = DateTime(2026, 9, 4, 15, 30);

    final testClient = ClientModel(
      id: 'client-123',
      companyName: 'Acme Robotics Pvt Ltd',
      contactPerson: 'Aditi Sharma',
      phone: '+91 98765 43210',
      alternatePhone: '+91 91234 56789',
      email: 'aditi@acmerobotics.com',
      website: 'https://acmerobotics.com',
      address: 'Plot 42, Electronics City',
      city: 'Bengaluru',
      state: 'Karnataka',
      country: 'India',
      pincode: '560100',
      industry: 'Technology',
      clientType: ClientType.newClient,
      status: ClientStatus.active,
      priority: ClientPriority.high,
      sourceLeadId: 'lead-999',
      assignedTo: 'user-001',
      assignedToName: 'Rajesh Kumar',
      createdBy: 'user-001',
      createdByName: 'Rajesh Kumar',
      clientSince: now,
      createdAt: now,
      updatedAt: now,
      lastContactedAt: now.subtract(const Duration(days: 2)),
      nextFollowUpAt: now.add(const Duration(days: 3)),
      totalQuotationValue: 150000.0,
      totalProjectValue: 200000.0,
      totalPaidAmount: 50000.0,
      notes: 'Premier enterprise account',
      isArchived: false,
    );

    test('buildSearchTokens creates lowercase indexed tokens', () {
      final tokens = testClient.buildSearchTokens();
      expect(tokens.contains('acme robotics pvt ltd'), isTrue);
      expect(tokens.contains('acme'), isTrue);
      expect(tokens.contains('robotics'), isTrue);
      expect(tokens.contains('aditi'), isTrue);
      expect(tokens.contains('bengaluru'), isTrue);
      expect(tokens.contains('technology'), isTrue);
      expect(tokens.contains('aditi@acmerobotics.com'), isTrue);
    });

    test('formattedAddress concatenates non-empty parts with comma', () {
      expect(
        testClient.formattedAddress,
        equals('Plot 42, Electronics City, Bengaluru, Karnataka, India, 560100'),
      );
    });

    test('toMap serializes all required Firestore fields and timestamps', () {
      final map = testClient.toMap();
      expect(map['companyName'], equals('Acme Robotics Pvt Ltd'));
      expect(map['contactPerson'], equals('Aditi Sharma'));
      expect(map['phone'], equals('+91 98765 43210'));
      expect(map['email'], equals('aditi@acmerobotics.com'));
      expect(map['clientType'], equals('newClient'));
      expect(map['status'], equals('active'));
      expect(map['priority'], equals('high'));
      expect(map['sourceLeadId'], equals('lead-999'));
      expect(map['leadId'], equals('lead-999')); // backward compatibility
      expect(map['clientSince'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['lastContactedAt'], isA<Timestamp>());
      expect(map['nextFollowUpAt'], isA<Timestamp>());
      expect(map['searchTokens'], isA<List<String>>());
      expect(map['isArchived'], isFalse);
    });

    test('fromLead factory properly maps lead fields to client model', () {
      final client = ClientModel.fromLead(
        id: 'new-client-777',
        companyName: 'Quantum Dynamics',
        contactPerson: 'Suresh Menon',
        phone: '+91 99887 76655',
        alternatePhone: '+91 88776 65544',
        email: 'suresh@quantum.in',
        website: 'https://quantum.in',
        address: 'Sector 62',
        city: 'Noida',
        state: 'Uttar Pradesh',
        pincode: '201309',
        industry: 'Healthcare',
        clientType: ClientType.corporate,
        priority: ClientPriority.urgent,
        assignedTo: 'staff-42',
        assignedToName: 'Neha Verma',
        createdBy: 'admin-1',
        createdByName: 'Admin',
        notes: 'Converted from high-value healthcare lead',
        leadId: 'lead-555',
      );

      expect(client.id, equals('new-client-777'));
      expect(client.companyName, equals('Quantum Dynamics'));
      expect(client.contactPerson, equals('Suresh Menon'));
      expect(client.sourceLeadId, equals('lead-555'));
      expect(client.leadId, equals('lead-555'));
      expect(client.status, equals(ClientStatus.active));
      expect(client.priority, equals(ClientPriority.urgent));
      expect(client.clientType, equals(ClientType.corporate));
      expect(client.isArchived, isFalse);
    });

    test('copyWith properly updates selective fields', () {
      final updated = testClient.copyWith(
        status: ClientStatus.completed,
        priority: ClientPriority.low,
        isArchived: true,
      );

      expect(updated.status, equals(ClientStatus.completed));
      expect(updated.priority, equals(ClientPriority.low));
      expect(updated.isArchived, isTrue);
      expect(updated.companyName, equals(testClient.companyName));
      expect(updated.sourceLeadId, equals(testClient.sourceLeadId));
    });

    test('ClientFilter active filter count calculations', () {
      const defaultFilter = ClientFilter();
      expect(defaultFilter.hasActiveFilters, isFalse);
      expect(defaultFilter.activeFilterCount, equals(0));

      final activeFilter = defaultFilter.copyWith(
        status: () => ClientStatus.active,
        priority: () => ClientPriority.urgent,
        clientType: () => ClientType.corporate,
        city: () => 'Bengaluru',
      );

      expect(activeFilter.hasActiveFilters, isTrue);
      expect(activeFilter.activeFilterCount, equals(4));

      final cleared = activeFilter.clear();
      expect(cleared.hasActiveFilters, isFalse);
      expect(cleared.activeFilterCount, equals(0));
    });
  });
}
