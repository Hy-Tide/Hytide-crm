// lib/features/expenses/models/money_transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class MoneyTransactionModel extends Equatable {
  final String id;
  final String accountId;
  final String accountName;
  final MoneyTransactionType type;
  final double amount;
  final String? expenseId;
  final String? projectId;
  final String? projectName;
  final String title;
  final String description;
  final String? category;
  final String? paymentMethod;
  final DateTime transactionDate;
  final double runningBalance;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVoided;

  const MoneyTransactionModel({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.type,
    required this.amount,
    this.expenseId,
    this.projectId,
    this.projectName,
    required this.title,
    this.description = '',
    this.category,
    this.paymentMethod,
    required this.transactionDate,
    this.runningBalance = 0.0,
    required this.createdBy,
    this.createdByName = 'Admin',
    required this.createdAt,
    required this.updatedAt,
    this.isVoided = false,
  });

  bool get isCredit => type == MoneyTransactionType.credit;
  bool get isDebit => type == MoneyTransactionType.debit;

  factory MoneyTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MoneyTransactionModel(
      id: doc.id,
      accountId: data['accountId'] as String? ?? '',
      accountName: data['accountName'] as String? ?? '',
      type: MoneyTransactionType.fromString(data['type'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      expenseId: data['expenseId'] as String?,
      projectId: data['projectId'] as String?,
      projectName: data['projectName'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      transactionDate:
          (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      runningBalance: (data['runningBalance'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVoided: data['isVoided'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'accountName': accountName,
      'type': type.name,
      'amount': amount,
      if (expenseId != null) 'expenseId': expenseId,
      if (projectId != null) 'projectId': projectId,
      if (projectName != null) 'projectName': projectName,
      'title': title,
      'description': description,
      if (category != null) 'category': category,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'runningBalance': runningBalance,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVoided': isVoided,
    };
  }

  MoneyTransactionModel copyWith({
    String? id,
    String? accountId,
    String? accountName,
    MoneyTransactionType? type,
    double? amount,
    String? expenseId,
    String? projectId,
    String? projectName,
    String? title,
    String? description,
    String? category,
    String? paymentMethod,
    DateTime? transactionDate,
    double? runningBalance,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVoided,
  }) {
    return MoneyTransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      expenseId: expenseId ?? this.expenseId,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      runningBalance: runningBalance ?? this.runningBalance,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVoided: isVoided ?? this.isVoided,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        accountName,
        type,
        amount,
        expenseId,
        projectId,
        projectName,
        title,
        description,
        category,
        paymentMethod,
        transactionDate,
        runningBalance,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
        isVoided,
      ];
}
