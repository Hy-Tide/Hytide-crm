// test/core/platform_capabilities_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/platform/platform_capabilities.dart';
import 'package:hytide/core/services/notification_service.dart';

void main() {
  group('PlatformCapabilities Tests', () {
    test('Platform detection returns consistent values in test environment', () {
      // In flutter test VM, kIsWeb is false
      expect(PlatformCapabilities.isWeb, isFalse);
      expect(PlatformCapabilities.supportsBrowserNotifications, isFalse);
    });

    test('CRMNotificationPayload effectiveRoute maps types correctly', () {
      final followup = CRMNotificationPayload(
        id: '1',
        title: 'Follow-up Call',
        body: 'Reminder for meeting',
        type: 'followup',
        entityId: 'fu_123',
        receivedAt: DateTime.now(),
      );
      expect(followup.effectiveRoute, '/followups/fu_123');

      final project = CRMNotificationPayload(
        id: '2',
        title: 'Project Update',
        body: 'Milestone completed',
        type: 'project',
        entityId: 'proj_456',
        receivedAt: DateTime.now(),
      );
      expect(project.effectiveRoute, '/projects/proj_456');

      final directRoute = CRMNotificationPayload(
        id: '3',
        title: 'Direct Link',
        body: 'Custom URL',
        targetRoute: '/settings',
        receivedAt: DateTime.now(),
      );
      expect(directRoute.effectiveRoute, '/settings');
    });
  });
}
