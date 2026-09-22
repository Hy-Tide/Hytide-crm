// lib/features/leads/models/lead_filter_model.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

enum LeadViewMode {
  table,
  kanban;

  String get displayName => this == LeadViewMode.table ? 'Table View' : 'Kanban View';
}

enum LeadSortOption {
  recentlyUpdated,
  newestFirst,
  oldestFirst,
  highestValue,
  lowestValue,
  followupSoonest,
  followupLatest,
  companyAsc,
  companyDesc;

  String get displayName {
    switch (this) {
      case LeadSortOption.recentlyUpdated:
        return 'Recently Updated';
      case LeadSortOption.newestFirst:
        return 'Newest First';
      case LeadSortOption.oldestFirst:
        return 'Oldest First';
      case LeadSortOption.highestValue:
        return 'Highest Value';
      case LeadSortOption.lowestValue:
        return 'Lowest Value';
      case LeadSortOption.followupSoonest:
        return 'Follow-up Soonest';
      case LeadSortOption.followupLatest:
        return 'Follow-up Latest';
      case LeadSortOption.companyAsc:
        return 'Company A–Z';
      case LeadSortOption.companyDesc:
        return 'Company Z–A';
    }
  }

  String get label => displayName;

  String get field {
    switch (this) {
      case LeadSortOption.recentlyUpdated:
        return 'updatedAt';
      case LeadSortOption.newestFirst:
      case LeadSortOption.oldestFirst:
        return 'createdAt';
      case LeadSortOption.highestValue:
      case LeadSortOption.lowestValue:
        return 'estimatedValue';
      case LeadSortOption.followupSoonest:
      case LeadSortOption.followupLatest:
        return 'nextFollowUpAt';
      case LeadSortOption.companyAsc:
      case LeadSortOption.companyDesc:
        return 'companyName';
    }
  }

  bool get descending {
    switch (this) {
      case LeadSortOption.recentlyUpdated:
      case LeadSortOption.newestFirst:
      case LeadSortOption.highestValue:
      case LeadSortOption.followupLatest:
      case LeadSortOption.companyDesc:
        return true;
      case LeadSortOption.oldestFirst:
      case LeadSortOption.lowestValue:
      case LeadSortOption.followupSoonest:
      case LeadSortOption.companyAsc:
        return false;
    }
  }
}

class LeadFilter extends Equatable {
  final Set<LeadStatus> statuses;
  final Set<LeadPriority> priorities;
  final Set<LeadSource> sources;
  final String? assignedTo;
  final String? assignedToName;
  final DateTimeRange? createdDateRange;
  final double? minValue;
  final double? maxValue;
  final bool isArchived;

  const LeadFilter({
    this.statuses = const {},
    this.priorities = const {},
    this.sources = const {},
    this.assignedTo,
    this.assignedToName,
    this.createdDateRange,
    this.minValue,
    this.maxValue,
    this.isArchived = false,
  });

  bool get hasFilters =>
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      sources.isNotEmpty ||
      assignedTo != null ||
      createdDateRange != null ||
      minValue != null ||
      maxValue != null ||
      isArchived;

  int get activeFilterCount {
    int count = 0;
    if (statuses.isNotEmpty) count += statuses.length;
    if (priorities.isNotEmpty) count += priorities.length;
    if (sources.isNotEmpty) count += sources.length;
    if (assignedTo != null) count++;
    if (createdDateRange != null) count++;
    if (minValue != null || maxValue != null) count++;
    if (isArchived) count++;
    return count;
  }

  LeadStatus? get status => statuses.length == 1 ? statuses.first : null;
  LeadPriority? get priority => priorities.length == 1 ? priorities.first : null;
  LeadSource? get leadSource => sources.length == 1 ? sources.first : null;
  String? get assignedToUserId => assignedTo;

  LeadFilter copyWith({
    Set<LeadStatus>? statuses,
    Set<LeadPriority>? priorities,
    Set<LeadSource>? sources,
    String? assignedTo,
    String? assignedToName,
    DateTimeRange? createdDateRange,
    double? minValue,
    double? maxValue,
    bool? isArchived,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearLeadSource = false,
    bool clearAssignedTo = false,
    bool clearDateRange = false,
    bool clearValues = false,
  }) {
    return LeadFilter(
      statuses: clearStatus ? const {} : (statuses ?? this.statuses),
      priorities: clearPriority ? const {} : (priorities ?? this.priorities),
      sources: clearLeadSource ? const {} : (sources ?? this.sources),
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      assignedToName: clearAssignedTo ? null : (assignedToName ?? this.assignedToName),
      createdDateRange: clearDateRange ? null : (createdDateRange ?? this.createdDateRange),
      minValue: clearValues ? null : (minValue ?? this.minValue),
      maxValue: clearValues ? null : (maxValue ?? this.maxValue),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
        statuses,
        priorities,
        sources,
        assignedTo,
        assignedToName,
        createdDateRange,
        minValue,
        maxValue,
        isArchived,
      ];
}
