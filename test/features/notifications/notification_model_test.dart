// test/features/notifications/notification_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/features/notifications/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    test('toMap and copyWith preserve all core attributes', () {
      final now = DateTime(2026, 9, 10, 14, 0);
      final notif = NotificationModel(
        id: 'notif_1',
        userId: 'user_admin',
        type: 'follow_up_reminder',
        title: 'Follow-up Reminder',
        body: 'Call Acme Corp regarding quotation at 2:30 PM',
        followUpId: 'f_123',
        leadId: 'l_456',
        isRead: false,
        createdAt: now,
      );

      final map = notif.toMap();
      expect(map['userId'], equals('user_admin'));
      expect(map['type'], equals('follow_up_reminder'));
      expect(map['followUpId'], equals('f_123'));
      expect(map['isRead'], isFalse);

      final readNotif = notif.copyWith(isRead: true, readAt: now);
      expect(readNotif.isRead, isTrue);
      expect(readNotif.readAt, equals(now));
    });
  });
}
