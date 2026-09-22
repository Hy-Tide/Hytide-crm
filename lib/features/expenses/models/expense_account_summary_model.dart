// lib/features/expenses/models/expense_account_summary_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ExpenseAccountSummaryModel extends Equatable {
  final String accountId;
  final String accountName;
  final double totalCredits;
  final double totalDebits;
  final double currentBalance;
  final DateTime updatedAt;

  const ExpenseAccountSummaryModel({
    required this.accountId,
    required this.accountName,
    this.totalCredits = 0.0,
    this.totalDebits = 0.0,
    this.currentBalance = 0.0,
    required this.updatedAt,
  });

  factory ExpenseAccountSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final credits = (data['totalCredits'] as num?)?.toDouble() ?? 0.0;
    final debits = (data['totalDebits'] as num?)?.toDouble() ?? 0.0;
    final balance = (data['currentBalance'] as num?)?.toDouble() ?? (credits - debits);

    return ExpenseAccountSummaryModel(
      accountId: doc.id,
      accountName: data['accountName'] as String? ?? '',
      totalCredits: credits,
      totalDebits: debits,
      currentBalance: balance,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'currentBalance': currentBalance,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ExpenseAccountSummaryModel copyWith({
    String? accountId,
    String? accountName,
    double? totalCredits,
    double? totalDebits,
    double? currentBalance,
    DateTime? updatedAt,
  }) {
    return ExpenseAccountSummaryModel(
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      totalCredits: totalCredits ?? this.totalCredits,
      totalDebits: totalDebits ?? this.totalDebits,
      currentBalance: currentBalance ?? this.currentBalance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        accountId,
        accountName,
        totalCredits,
        totalDebits,
        currentBalance,
        updatedAt,
      ];
}
