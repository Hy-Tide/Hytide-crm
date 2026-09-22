// test/features/projects/project_status_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/projects/services/project_status_service.dart';

void main() {
  group('ProjectStatusService State Transition & Validation Tests', () {
    test('planning allows transition to active and cancelled', () {
      expect(ProjectStatusService.canTransition(ProjectStatus.planning, ProjectStatus.active), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.planning, ProjectStatus.cancelled), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.planning, ProjectStatus.completed), isFalse);
    });

    test('active allows transition to onHold, completed, and cancelled', () {
      expect(ProjectStatusService.canTransition(ProjectStatus.active, ProjectStatus.onHold), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.active, ProjectStatus.completed), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.active, ProjectStatus.cancelled), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.active, ProjectStatus.planning), isFalse);
    });

    test('onHold allows transition back to active or cancelled', () {
      expect(ProjectStatusService.canTransition(ProjectStatus.onHold, ProjectStatus.active), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.onHold, ProjectStatus.cancelled), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.onHold, ProjectStatus.completed), isFalse);
    });

    test('completed allows transition to archived or reopen to active', () {
      expect(ProjectStatusService.canTransition(ProjectStatus.completed, ProjectStatus.archived), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.completed, ProjectStatus.active), isTrue);
      expect(ProjectStatusService.canTransition(ProjectStatus.completed, ProjectStatus.planning), isFalse);
    });

    test('validateTransition returns null for valid and error message for invalid', () {
      expect(ProjectStatusService.validateTransition(ProjectStatus.planning, ProjectStatus.active), isNull);
      expect(
        ProjectStatusService.validateTransition(ProjectStatus.planning, ProjectStatus.completed),
        isNotNull,
      );
    });

    test('validateDates ensures expectedEndDate is after or equal to startDate', () {
      final start = DateTime(2026, 9, 1);
      final validEnd = DateTime(2026, 9, 15);
      final invalidEnd = DateTime(2026, 8, 20);

      expect(ProjectStatusService.validateDates(start, validEnd), isNull);
      expect(ProjectStatusService.validateDates(start, start), isNull);
      expect(ProjectStatusService.validateDates(start, null), isNull);

      final error = ProjectStatusService.validateDates(start, invalidEnd);
      expect(error, isNotNull);
      expect(error, contains('earlier than start date'));
    });
  });
}
