// lib/features/projects/services/project_status_service.dart
import '../../../core/constants/app_constants.dart';

class ProjectStatusService {
  /// Allowed status transitions map
  static const Map<ProjectStatus, List<ProjectStatus>> _allowedTransitions = {
    ProjectStatus.planning: [
      ProjectStatus.active,
      ProjectStatus.cancelled,
    ],
    ProjectStatus.active: [
      ProjectStatus.onHold,
      ProjectStatus.completed,
      ProjectStatus.cancelled,
    ],
    ProjectStatus.onHold: [
      ProjectStatus.active,
      ProjectStatus.cancelled,
    ],
    ProjectStatus.completed: [
      ProjectStatus.active, // Reopen if needed
      ProjectStatus.archived,
    ],
    ProjectStatus.cancelled: [
      ProjectStatus.archived,
    ],
    ProjectStatus.archived: [
      ProjectStatus.active, // Restore
      ProjectStatus.planning,
    ],
  };

  /// Returns list of valid next statuses from current status
  static List<ProjectStatus> getAllowedTransitions(ProjectStatus current) {
    return _allowedTransitions[current] ?? [];
  }

  /// Checks if a transition is valid
  static bool canTransition(ProjectStatus current, ProjectStatus target) {
    if (current == target) return true;
    final allowed = _allowedTransitions[current];
    return allowed != null && allowed.contains(target);
  }

  /// Validates transition and returns null if valid, or error message
  static String? validateTransition(ProjectStatus current, ProjectStatus target) {
    if (current == target) return null;
    if (!canTransition(current, target)) {
      return 'Cannot transition project from ${current.name} to ${target.name}.';
    }
    return null;
  }

  /// Validates start and expected end dates
  static String? validateDates(DateTime startDate, DateTime? expectedEndDate) {
    if (expectedEndDate != null && expectedEndDate.isBefore(startDate)) {
      return 'Expected completion date cannot be earlier than start date.';
    }
    return null;
  }
}
