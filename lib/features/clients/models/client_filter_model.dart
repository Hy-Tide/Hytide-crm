// lib/features/clients/models/client_filter_model.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

enum ClientDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom;

  String get displayName {
    switch (this) {
      case ClientDateFilter.all:
        return 'All Time';
      case ClientDateFilter.today:
        return 'Today';
      case ClientDateFilter.thisWeek:
        return 'This Week';
      case ClientDateFilter.thisMonth:
        return 'This Month';
      case ClientDateFilter.thisYear:
        return 'This Year';
      case ClientDateFilter.custom:
        return 'Custom Range';
    }
  }
}

enum ClientSortBy {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  priority,
  nextFollowUp,
  recentlyUpdated;

  String get displayName {
    switch (this) {
      case ClientSortBy.newest:
        return 'Newest First';
      case ClientSortBy.oldest:
        return 'Oldest First';
      case ClientSortBy.nameAsc:
        return 'Company Name (A–Z)';
      case ClientSortBy.nameDesc:
        return 'Company Name (Z–A)';
      case ClientSortBy.priority:
        return 'Priority (Urgent First)';
      case ClientSortBy.nextFollowUp:
        return 'Next Follow-up';
      case ClientSortBy.recentlyUpdated:
        return 'Recently Updated';
    }
  }
}

class ClientFilter extends Equatable {
  final ClientStatus? status;
  final ClientPriority? priority;
  final ClientType? clientType;
  final String? industry;
  final String? assignedTo;
  final String? city;
  final ClientDateFilter dateFilter;
  final DateTimeRange? customDateRange;
  final bool showArchived;
  final ClientSortBy sortBy;

  const ClientFilter({
    this.status,
    this.priority,
    this.clientType,
    this.industry,
    this.assignedTo,
    this.city,
    this.dateFilter = ClientDateFilter.all,
    this.customDateRange,
    this.showArchived = false,
    this.sortBy = ClientSortBy.newest,
  });

  bool get hasActiveFilters =>
      status != null ||
      priority != null ||
      clientType != null ||
      (industry != null && industry!.isNotEmpty) ||
      (assignedTo != null && assignedTo!.isNotEmpty) ||
      (city != null && city!.isNotEmpty) ||
      dateFilter != ClientDateFilter.all ||
      showArchived;

  int get activeFilterCount {
    int count = 0;
    if (status != null) count++;
    if (priority != null) count++;
    if (clientType != null) count++;
    if (industry != null && industry!.isNotEmpty) count++;
    if (assignedTo != null && assignedTo!.isNotEmpty) count++;
    if (city != null && city!.isNotEmpty) count++;
    if (dateFilter != ClientDateFilter.all) count++;
    if (showArchived) count++;
    return count;
  }

  ClientFilter copyWith({
    ClientStatus? Function()? status,
    ClientPriority? Function()? priority,
    ClientType? Function()? clientType,
    String? Function()? industry,
    String? Function()? assignedTo,
    String? Function()? city,
    ClientDateFilter? dateFilter,
    DateTimeRange? Function()? customDateRange,
    bool? showArchived,
    ClientSortBy? sortBy,
  }) {
    return ClientFilter(
      status: status != null ? status() : this.status,
      priority: priority != null ? priority() : this.priority,
      clientType: clientType != null ? clientType() : this.clientType,
      industry: industry != null ? industry() : this.industry,
      assignedTo: assignedTo != null ? assignedTo() : this.assignedTo,
      city: city != null ? city() : this.city,
      dateFilter: dateFilter ?? this.dateFilter,
      customDateRange:
          customDateRange != null ? customDateRange() : this.customDateRange,
      showArchived: showArchived ?? this.showArchived,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  ClientFilter clear() {
    return const ClientFilter();
  }

  @override
  List<Object?> get props => [
        status,
        priority,
        clientType,
        industry,
        assignedTo,
        city,
        dateFilter,
        customDateRange,
        showArchived,
        sortBy,
      ];
}
