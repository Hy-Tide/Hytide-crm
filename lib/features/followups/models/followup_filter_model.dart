// lib/features/followups/models/followup_filter_model.dart
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

enum FollowUpDateFilter {
  all,
  today,
  tomorrow,
  thisWeek,
  nextWeek,
  overdue,
  custom;

  String get displayName {
    switch (this) {
      case FollowUpDateFilter.all:
        return 'All Dates';
      case FollowUpDateFilter.today:
        return 'Today';
      case FollowUpDateFilter.tomorrow:
        return 'Tomorrow';
      case FollowUpDateFilter.thisWeek:
        return 'This Week';
      case FollowUpDateFilter.nextWeek:
        return 'Next Week';
      case FollowUpDateFilter.overdue:
        return 'Overdue';
      case FollowUpDateFilter.custom:
        return 'Custom Range';
    }
  }
}

enum FollowUpViewMode {
  list,
  calendar;

  String get displayName => this == list ? 'List' : 'Calendar';
}

enum CalendarViewType {
  month,
  week,
  day;

  String get displayName {
    switch (this) {
      case CalendarViewType.month:
        return 'Month';
      case CalendarViewType.week:
        return 'Week';
      case CalendarViewType.day:
        return 'Day';
    }
  }
}

class FollowUpFilter extends Equatable {
  final FollowUpStatus? status;
  final FollowUpPriority? priority;
  final FollowUpType? type;
  final String? assignedTo;
  final FollowUpDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool? reminderEnabled;

  const FollowUpFilter({
    this.status,
    this.priority,
    this.type,
    this.assignedTo,
    this.dateFilter = FollowUpDateFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.reminderEnabled,
  });

  bool get isEmpty =>
      status == null &&
      priority == null &&
      type == null &&
      (assignedTo == null || assignedTo!.isEmpty) &&
      dateFilter == FollowUpDateFilter.all &&
      customStartDate == null &&
      customEndDate == null &&
      reminderEnabled == null;

  int get activeFiltersCount {
    int count = 0;
    if (status != null) count++;
    if (priority != null) count++;
    if (type != null) count++;
    if (assignedTo != null && assignedTo!.isNotEmpty) count++;
    if (dateFilter != FollowUpDateFilter.all) count++;
    if (reminderEnabled != null) count++;
    return count;
  }

  FollowUpFilter copyWith({
    FollowUpStatus? status,
    bool clearStatus = false,
    FollowUpPriority? priority,
    bool clearPriority = false,
    FollowUpType? type,
    bool clearType = false,
    String? assignedTo,
    bool clearAssignedTo = false,
    FollowUpDateFilter? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool clearCustomDates = false,
    bool? reminderEnabled,
    bool clearReminderEnabled = false,
  }) {
    return FollowUpFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      type: clearType ? null : (type ?? this.type),
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      reminderEnabled: clearReminderEnabled ? null : (reminderEnabled ?? this.reminderEnabled),
    );
  }

  FollowUpFilter clear() => const FollowUpFilter();

  @override
  List<Object?> get props => [
        status,
        priority,
        type,
        assignedTo,
        dateFilter,
        customStartDate,
        customEndDate,
        reminderEnabled,
      ];
}
