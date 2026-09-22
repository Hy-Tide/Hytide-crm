// lib/features/expenses/models/expense_filter_model.dart
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseFilter extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? projectId;
  final String? paidFromAccountId;
  final String? usedByAccountId;
  final ExpenseCategory? category;
  final ExpensePaymentMethod? paymentMethod;
  final double? minAmount;
  final double? maxAmount;
  final bool includeVoided;

  const ExpenseFilter({
    this.startDate,
    this.endDate,
    this.projectId,
    this.paidFromAccountId,
    this.usedByAccountId,
    this.category,
    this.paymentMethod,
    this.minAmount,
    this.maxAmount,
    this.includeVoided = false,
  });

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      (projectId != null && projectId!.isNotEmpty) ||
      (paidFromAccountId != null && paidFromAccountId!.isNotEmpty) ||
      (usedByAccountId != null && usedByAccountId!.isNotEmpty) ||
      category != null ||
      paymentMethod != null ||
      minAmount != null ||
      maxAmount != null ||
      includeVoided;

  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (projectId != null && projectId!.isNotEmpty) count++;
    if (paidFromAccountId != null && paidFromAccountId!.isNotEmpty) count++;
    if (usedByAccountId != null && usedByAccountId!.isNotEmpty) count++;
    if (category != null) count++;
    if (paymentMethod != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (includeVoided) count++;
    return count;
  }

  ExpenseFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? projectId,
    String? paidFromAccountId,
    String? usedByAccountId,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    double? minAmount,
    double? maxAmount,
    bool? includeVoided,
    bool clearDates = false,
    bool clearProject = false,
    bool clearPaidFrom = false,
    bool clearUsedBy = false,
    bool clearCategory = false,
    bool clearPaymentMethod = false,
    bool clearAmountRange = false,
  }) {
    return ExpenseFilter(
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      paidFromAccountId:
          clearPaidFrom ? null : (paidFromAccountId ?? this.paidFromAccountId),
      usedByAccountId:
          clearUsedBy ? null : (usedByAccountId ?? this.usedByAccountId),
      category: clearCategory ? null : (category ?? this.category),
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      minAmount: clearAmountRange ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmountRange ? null : (maxAmount ?? this.maxAmount),
      includeVoided: includeVoided ?? this.includeVoided,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        projectId,
        paidFromAccountId,
        usedByAccountId,
        category,
        paymentMethod,
        minAmount,
        maxAmount,
        includeVoided,
      ];
}
