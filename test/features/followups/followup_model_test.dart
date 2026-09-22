// test/features/followups/followup_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/followups/models/followup_model.dart';
import 'package:hytide/core/services/timezone_helper.dart';

void main() {
  group('FollowUpModel Tests', () {
    test('calculateReminderAt returns correct target time when enabled', () {
      final scheduled = DateTime(2026, 9, 10, 15, 30);
      final reminderAt = FollowUpModel.calculateReminderAt(
        enabled: true,
        minutesBefore: 30,
        scheduledTime: scheduled,
      );

      expect(reminderAt, equals(DateTime(2026, 9, 10, 15, 0)));
    });

    test('calculateReminderAt returns null when disabled', () {
      final scheduled = DateTime(2026, 9, 10, 15, 30);
      final reminderAt = FollowUpModel.calculateReminderAt(
        enabled: false,
        minutesBefore: 30,
        scheduledTime: scheduled,
      );

      expect(reminderAt, isNull);
    });

    test('isOverdue is true only when status is pending and time is in past', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 2));
      final futureDate = DateTime.now().add(const Duration(hours: 2));

      final overdueFollowup = FollowUpModel(
        id: 'f1',
        leadId: 'l1',
        leadName: 'Acme Corp',
        companyName: 'Acme Corp',
        title: 'Quote follow-up',
        type: FollowUpType.call,
        status: FollowUpStatus.pending,
        scheduledAt: pastDate,
        assignedTo: 'u1',
        assignedToName: 'Admin',
        createdBy: 'u1',
        createdByName: 'Admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(overdueFollowup.isOverdue, isTrue);

      final completedPast = overdueFollowup.copyWith(status: FollowUpStatus.completed);
      expect(completedPast.isOverdue, isFalse);

      final futurePending = overdueFollowup.copyWith(scheduledAt: futureDate);
      expect(futurePending.isOverdue, isFalse);
    });

    test('overdueDurationString formats human friendly duration', () {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2, minutes: 5));
      final text = TimezoneHelper.getOverdueText(twoHoursAgo);
      expect(text, equals('Overdue by 2 hours'));

      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3, hours: 1));
      final textDays = TimezoneHelper.getOverdueText(threeDaysAgo);
      expect(textDays, equals('Overdue by 3 days'));
    });

    test('toMap and copyWith preserve all core fields', () {
      final now = DateTime(2026, 9, 10, 10, 0);
      final followup = FollowUpModel(
        id: 'f123',
        leadId: 'lead_abc',
        leadName: 'John Doe',
        companyName: 'Apex Logistics',
        title: 'Discuss proposal terms',
        description: 'Review SLA and payment schedule',
        type: FollowUpType.meeting,
        status: FollowUpStatus.pending,
        priority: FollowUpPriority.high,
        scheduledAt: now,
        reminderEnabled: true,
        reminderMinutesBefore: 15,
        assignedTo: 'user_xyz',
        assignedToName: 'Sarah Jenkins',
        createdBy: 'user_admin',
        createdByName: 'Admin',
        createdAt: now,
        updatedAt: now,
      );

      final map = followup.toMap();
      expect(map['leadId'], equals('lead_abc'));
      expect(map['companyName'], equals('Apex Logistics'));
      expect(map['title'], equals('Discuss proposal terms'));
      expect(map['type'], equals('meeting'));
      expect(map['priority'], equals('high'));
      expect(map['reminderEnabled'], isTrue);
      expect(map['reminderMinutesBefore'], equals(15));
      expect(map['assignedTo'], equals('user_xyz'));

      final updated = followup.copyWith(
        status: FollowUpStatus.completed,
        completionNote: 'Client signed NDA',
      );
      expect(updated.status, equals(FollowUpStatus.completed));
      expect(updated.completionNote, equals('Client signed NDA'));
    });
  });
}
