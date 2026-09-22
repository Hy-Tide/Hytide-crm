import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/leads/models/lead_activity_model.dart';
import 'package:hytide/features/leads/models/lead_filter_model.dart';
import 'package:hytide/features/leads/models/lead_model.dart';
import 'package:hytide/features/leads/models/lead_note_model.dart';

void main() {
  group('LeadModel Tests', () {
    final testLead = LeadModel(
      id: 'lead-123',
      companyName: 'Acme Solutions',
      contactPerson: 'Alex Rivera',
      phone: '+919876543210',
      email: 'alex@acme.com',
      alternatePhone: '+919876543211',
      website: 'https://acme.com',
      address: '123 Main Street',
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
      industry: 'Software',
      leadSource: LeadSource.website,
      status: LeadStatus.newLead,
      priority: LeadPriority.high,
      assignedTo: 'user-1',
      assignedToName: 'Sarah Connor',
      estimatedValue: 75000,
      expectedClosingDate: DateTime(2026, 9, 30),
      description: 'Interested in CRM enterprise tier',
      notes: 'Initial outreach made via website',
      createdBy: 'admin-1',
      createdByName: 'Admin',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 2),
      convertedToClient: false,
    );

    test('LeadModel properties and getters', () {
      expect(testLead.id, 'lead-123');
      expect(testLead.companyName, 'Acme Solutions');
      expect(testLead.contactPerson, 'Alex Rivera');
      expect(testLead.source, LeadSource.website);
      expect(testLead.isConverted, false);
      expect(testLead.currency, 'INR');
      expect(testLead.estimatedValue, 75000);
      expect(testLead.expectedCloseDate, DateTime(2026, 9, 30));
      expect(testLead.assignedToUserId, 'user-1');
      expect(testLead.requirements, 'Interested in CRM enterprise tier');
    });

    test('LeadModel toMap serialization contains searchTokens', () {
      final map = testLead.toMap();
      expect(map['companyName'], 'Acme Solutions');
      expect(map['contactPerson'], 'Alex Rivera');
      expect(map['phone'], '+919876543210');
      expect(map['email'], 'alex@acme.com');
      expect(map['status'], LeadStatus.newLead.name);
      expect(map['priority'], LeadPriority.high.name);
      expect(map['source'], LeadSource.website.name);
      expect(map['estimatedValue'], 75000.0);
      expect(map['searchTokens'], isA<List>());
      final tokens = map['searchTokens'] as List;
      expect(tokens.contains('acme'), true);
      expect(tokens.contains('solutions'), true);
      expect(tokens.contains('alex'), true);
      expect(tokens.contains('rivera'), true);
    });

    test('LeadModel copyWith preserves and updates fields correctly', () {
      final updated = testLead.copyWith(
        status: LeadStatus.won,
        convertedToClient: true,
        clientId: 'client-999',
      );
      expect(updated.id, testLead.id);
      expect(updated.status, LeadStatus.won);
      expect(updated.convertedToClient, true);
      expect(updated.isConverted, true);
      expect(updated.clientId, 'client-999');
      expect(updated.companyName, 'Acme Solutions');
    });
  });

  group('LeadActivityModel Tests', () {
    test('LeadActivityModel relativeTime formatting', () {
      final now = DateTime.now();
      final justNowActivity = LeadActivityModel(
        id: 'act-1',
        type: 'lead_created',
        title: 'Lead created',
        description: 'New lead added',
        createdBy: 'user-1',
        createdByName: 'John Doe',
        createdAt: now.subtract(const Duration(seconds: 10)),
      );
      expect(justNowActivity.relativeTime, 'Just now');
      expect(justNowActivity.timeAgo, 'Just now');
      expect(justNowActivity.actorName, 'John Doe');

      final pastActivity = LeadActivityModel(
        id: 'act-2',
        type: 'status_changed',
        title: 'Status changed',
        description: 'Moved to Contacted',
        createdBy: 'user-1',
        createdByName: 'John Doe',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(pastActivity.relativeTime, '5 mins ago');
    });
  });

  group('LeadNoteModel Tests', () {
    test('LeadNoteModel serialization and getters', () {
      final noteDate = DateTime(2026, 9, 4, 14, 30);
      final note = LeadNoteModel(
        id: 'note-1',
        content: 'Client requested a demo on Tuesday.',
        createdBy: 'user-1',
        createdByName: 'Alice',
        createdAt: noteDate,
        updatedAt: noteDate,
      );

      expect(note.id, 'note-1');
      expect(note.content, 'Client requested a demo on Tuesday.');
      expect(note.authorId, 'user-1');
      expect(note.authorName, 'Alice');
      expect(note.formattedDate.contains('Sep 4, 2026'), true);

      final map = note.toMap();
      expect(map['content'], 'Client requested a demo on Tuesday.');
      expect(map['createdBy'], 'user-1');
      expect(map['createdByName'], 'Alice');
    });
  });

  group('LeadFilter Tests', () {
    test('LeadFilter active count and hasFilters calculation', () {
      const emptyFilter = LeadFilter();
      expect(emptyFilter.hasFilters, false);
      expect(emptyFilter.activeFilterCount, 0);

      final filtered = const LeadFilter().copyWith(
        statuses: {LeadStatus.newLead, LeadStatus.contacted},
        priorities: {LeadPriority.high},
        isArchived: true,
      );

      expect(filtered.hasFilters, true);
      // 2 statuses + 1 priority + 1 archived = 4
      expect(filtered.activeFilterCount, 4);
    });

    test('LeadFilter single status and priority helpers', () {
      final filter = const LeadFilter().copyWith(
        statuses: {LeadStatus.won},
        priorities: {LeadPriority.urgent},
      );

      expect(filter.status, LeadStatus.won);
      expect(filter.priority, LeadPriority.urgent);
    });
  });
}
