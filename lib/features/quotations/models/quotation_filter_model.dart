// lib/features/quotations/models/quotation_filter_model.dart
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

enum QuotationDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom;

  String get displayName {
    switch (this) {
      case QuotationDateFilter.all:
        return 'All Time';
      case QuotationDateFilter.today:
        return 'Today';
      case QuotationDateFilter.thisWeek:
        return 'This Week';
      case QuotationDateFilter.thisMonth:
        return 'This Month';
      case QuotationDateFilter.thisYear:
        return 'This Year';
      case QuotationDateFilter.custom:
        return 'Custom Range';
    }
  }
}

enum QuotationSortBy {
  newest,
  oldest,
  quotationNumber,
  amountHighToLow,
  amountLowToHigh,
  expirySoonest,
  recentlyUpdated;

  String get displayName {
    switch (this) {
      case QuotationSortBy.newest:
        return 'Newest First';
      case QuotationSortBy.oldest:
        return 'Oldest First';
      case QuotationSortBy.quotationNumber:
        return 'Quotation #';
      case QuotationSortBy.amountHighToLow:
        return 'Amount: High → Low';
      case QuotationSortBy.amountLowToHigh:
        return 'Amount: Low → High';
      case QuotationSortBy.expirySoonest:
        return 'Expiry Soonest';
      case QuotationSortBy.recentlyUpdated:
        return 'Recently Updated';
    }
  }
}

class QuotationFilter extends Equatable {
  final QuotationStatus? status;
  final String? clientId;
  final String? assignedTo;
  final QuotationDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double? minAmount;
  final double? maxAmount;
  final bool isArchived;
  final QuotationSortBy sortBy;

  const QuotationFilter({
    this.status,
    this.clientId,
    this.assignedTo,
    this.dateFilter = QuotationDateFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.minAmount,
    this.maxAmount,
    this.isArchived = false,
    this.sortBy = QuotationSortBy.newest,
  });

  bool get hasActiveFilters =>
      status != null ||
      clientId != null ||
      assignedTo != null ||
      dateFilter != QuotationDateFilter.all ||
      minAmount != null ||
      maxAmount != null ||
      isArchived;

  int get activeFilterCount {
    int count = 0;
    if (status != null) count++;
    if (clientId != null) count++;
    if (assignedTo != null) count++;
    if (dateFilter != QuotationDateFilter.all) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (isArchived) count++;
    return count;
  }

  QuotationFilter copyWith({
    QuotationStatus? Function()? status,
    String? Function()? clientId,
    String? Function()? assignedTo,
    QuotationDateFilter? dateFilter,
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
    double? Function()? minAmount,
    double? Function()? maxAmount,
    bool? isArchived,
    QuotationSortBy? sortBy,
  }) {
    return QuotationFilter(
      status: status != null ? status() : this.status,
      clientId: clientId != null ? clientId() : this.clientId,
      assignedTo: assignedTo != null ? assignedTo() : this.assignedTo,
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate != null ? customStartDate() : this.customStartDate,
      customEndDate: customEndDate != null ? customEndDate() : this.customEndDate,
      minAmount: minAmount != null ? minAmount() : this.minAmount,
      maxAmount: maxAmount != null ? maxAmount() : this.maxAmount,
      isArchived: isArchived ?? this.isArchived,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        status,
        clientId,
        assignedTo,
        dateFilter,
        customStartDate,
        customEndDate,
        minAmount,
        maxAmount,
        isArchived,
        sortBy,
      ];
}
