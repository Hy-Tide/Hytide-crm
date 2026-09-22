// lib/features/expenses/models/expense_dashboard_summary_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ExpenseDashboardSummaryModel extends Equatable {
  final double totalMoney;
  final double totalSpent;
  final double availableBalance;
  final double thisMonthSpent;
  final DateTime updatedAt;

  const ExpenseDashboardSummaryModel({
    this.totalMoney = 0.0,
    this.totalSpent = 0.0,
    this.availableBalance = 0.0,
    this.thisMonthSpent = 0.0,
    required this.updatedAt,
  });

  factory ExpenseDashboardSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final money = (data['totalMoney'] as num?)?.toDouble() ?? 0.0;
    final spent = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final available = (data['availableBalance'] as num?)?.toDouble() ?? (money - spent);
    final thisMonth = (data['thisMonthSpent'] as num?)?.toDouble() ?? 0.0;

    return ExpenseDashboardSummaryModel(
      totalMoney: money,
      totalSpent: spent,
      availableBalance: available,
      thisMonthSpent: thisMonth,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMoney': totalMoney,
      'totalSpent': totalSpent,
      'availableBalance': availableBalance,
      'thisMonthSpent': thisMonthSpent,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ExpenseDashboardSummaryModel copyWith({
    double? totalMoney,
    double? totalSpent,
    double? availableBalance,
    double? thisMonthSpent,
    DateTime? updatedAt,
  }) {
    return ExpenseDashboardSummaryModel(
      totalMoney: totalMoney ?? this.totalMoney,
      totalSpent: totalSpent ?? this.totalSpent,
      availableBalance: availableBalance ?? this.availableBalance,
      thisMonthSpent: thisMonthSpent ?? this.thisMonthSpent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        totalMoney,
        totalSpent,
        availableBalance,
        thisMonthSpent,
        updatedAt,
      ];
}
