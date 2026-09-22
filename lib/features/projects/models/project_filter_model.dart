// lib/features/projects/models/project_filter_model.dart
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

enum ProjectDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom;

  String get displayName {
    switch (this) {
      case ProjectDateFilter.all:
        return 'All Time';
      case ProjectDateFilter.today:
        return 'Today';
      case ProjectDateFilter.thisWeek:
        return 'This Week';
      case ProjectDateFilter.thisMonth:
        return 'This Month';
      case ProjectDateFilter.thisYear:
        return 'This Year';
      case ProjectDateFilter.custom:
        return 'Custom Range';
    }
  }
}

enum ProjectSortBy {
  newest,
  oldest,
  projectNumber,
  deadlineSoonest,
  progressHighToLow,
  progressLowToHigh,
  budgetHighToLow,
  budgetLowToHigh,
  recentlyUpdated;

  String get displayName {
    switch (this) {
      case ProjectSortBy.newest:
        return 'Newest First';
      case ProjectSortBy.oldest:
        return 'Oldest First';
      case ProjectSortBy.projectNumber:
        return 'Project #';
      case ProjectSortBy.deadlineSoonest:
        return 'Deadline Soonest';
      case ProjectSortBy.progressHighToLow:
        return 'Progress: High → Low';
      case ProjectSortBy.progressLowToHigh:
        return 'Progress: Low → High';
      case ProjectSortBy.budgetHighToLow:
        return 'Budget: High → Low';
      case ProjectSortBy.budgetLowToHigh:
        return 'Budget: Low → High';
      case ProjectSortBy.recentlyUpdated:
        return 'Recently Updated';
    }
  }
}

class ProjectFilter extends Equatable {
  final ProjectStatus? status;
  final ProjectType? projectType;
  final ProjectPriority? priority;
  final String? clientId;
  final String? assignedTo;
  final ProjectDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isOverdueOnly;
  final bool isArchived;
  final ProjectSortBy sortBy;

  const ProjectFilter({
    this.status,
    this.projectType,
    this.priority,
    this.clientId,
    this.assignedTo,
    this.dateFilter = ProjectDateFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.isOverdueOnly = false,
    this.isArchived = false,
    this.sortBy = ProjectSortBy.newest,
  });

  bool get hasActiveFilters =>
      status != null ||
      projectType != null ||
      priority != null ||
      clientId != null ||
      assignedTo != null ||
      dateFilter != ProjectDateFilter.all ||
      isOverdueOnly ||
      isArchived;

  int get activeFilterCount {
    int count = 0;
    if (status != null) count++;
    if (projectType != null) count++;
    if (priority != null) count++;
    if (clientId != null) count++;
    if (assignedTo != null) count++;
    if (dateFilter != ProjectDateFilter.all) count++;
    if (isOverdueOnly) count++;
    if (isArchived) count++;
    return count;
  }

  ProjectFilter copyWith({
    ProjectStatus? Function()? status,
    ProjectType? Function()? projectType,
    ProjectPriority? Function()? priority,
    String? Function()? clientId,
    String? Function()? assignedTo,
    ProjectDateFilter? dateFilter,
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
    bool? isOverdueOnly,
    bool? isArchived,
    ProjectSortBy? sortBy,
  }) {
    return ProjectFilter(
      status: status != null ? status() : this.status,
      projectType: projectType != null ? projectType() : this.projectType,
      priority: priority != null ? priority() : this.priority,
      clientId: clientId != null ? clientId() : this.clientId,
      assignedTo: assignedTo != null ? assignedTo() : this.assignedTo,
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate != null ? customStartDate() : this.customStartDate,
      customEndDate: customEndDate != null ? customEndDate() : this.customEndDate,
      isOverdueOnly: isOverdueOnly ?? this.isOverdueOnly,
      isArchived: isArchived ?? this.isArchived,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        status,
        projectType,
        priority,
        clientId,
        assignedTo,
        dateFilter,
        customStartDate,
        customEndDate,
        isOverdueOnly,
        isArchived,
        sortBy,
      ];
}
