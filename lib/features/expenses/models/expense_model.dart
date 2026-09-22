// lib/features/expenses/models/expense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseModel extends Equatable {
  final String id;
  final String paymentName;
  final double amount;
  final String currency;

  // Project linkage
  final String? projectId;
  final String? projectName;
  final String? projectNumber;

  // Money Holder (Paid From)
  final String paidFromAccountId;
  final String paidFromAccountName;

  // Money User (Used By)
  final String usedByAccountId;
  final String usedByAccountName;

  // Categorization
  final ExpenseCategory category;
  final ExpensePaymentMethod paymentMethod;

  final DateTime expenseDate;
  final String description;

  // Financial balance after this transaction was deducted
  final double balanceAfterTransaction;

  // Attribution
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Void / Archival Status
  final bool isVoided;
  final String? voidReason;
  final DateTime? voidedAt;

  // Search indexing
  final List<String> searchTokens;

  const ExpenseModel({
    required this.id,
    required this.paymentName,
    required this.amount,
    this.currency = 'INR',
    this.projectId,
    this.projectName,
    this.projectNumber,
    required this.paidFromAccountId,
    required this.paidFromAccountName,
    required this.usedByAccountId,
    required this.usedByAccountName,
    this.category = ExpenseCategory.other,
    this.paymentMethod = ExpensePaymentMethod.upi,
    required this.expenseDate,
    this.description = '',
    this.balanceAfterTransaction = 0.0,
    required this.createdBy,
    this.createdByName = 'Admin',
    required this.createdAt,
    required this.updatedAt,
    this.isVoided = false,
    this.voidReason,
    this.voidedAt,
    this.searchTokens = const [],
  });

  bool get hasProject => projectId != null && projectId!.isNotEmpty;

  static List<String> generateSearchTokens({
    required String paymentName,
    String? projectName,
    String? projectNumber,
    String? paidFrom,
    String? usedBy,
    String? description,
    String? category,
  }) {
    final Set<String> tokens = {};

    void addWords(String? text) {
      if (text == null || text.trim().isEmpty) return;
      final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
      for (final word in cleaned.split(RegExp(r'\s+'))) {
        if (word.isNotEmpty) {
          tokens.add(word);
          // Prefixes up to 10 chars
          for (int i = 1; i <= word.length && i <= 10; i++) {
            tokens.add(word.substring(0, i));
          }
        }
      }
    }

    addWords(paymentName);
    addWords(projectName);
    addWords(projectNumber);
    addWords(paidFrom);
    addWords(usedBy);
    addWords(description);
    addWords(category);

    return tokens.toList();
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel(
      id: doc.id,
      paymentName: data['paymentName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'INR',
      projectId: data['projectId'] as String?,
      projectName: data['projectName'] as String?,
      projectNumber: data['projectNumber'] as String?,
      paidFromAccountId: data['paidFromAccountId'] as String? ?? '',
      paidFromAccountName: data['paidFromAccountName'] as String? ?? '',
      usedByAccountId: data['usedByAccountId'] as String? ?? '',
      usedByAccountName: data['usedByAccountName'] as String? ?? '',
      category: ExpenseCategory.fromString(data['category'] as String?),
      paymentMethod:
          ExpensePaymentMethod.fromString(data['paymentMethod'] as String?),
      expenseDate:
          (data['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String? ?? '',
      balanceAfterTransaction:
          (data['balanceAfterTransaction'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVoided: data['isVoided'] as bool? ?? false,
      voidReason: data['voidReason'] as String?,
      voidedAt: (data['voidedAt'] as Timestamp?)?.toDate(),
      searchTokens: List<String>.from(data['searchTokens'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentName': paymentName,
      'amount': amount,
      'currency': currency,
      if (projectId != null) 'projectId': projectId,
      if (projectName != null) 'projectName': projectName,
      if (projectNumber != null) 'projectNumber': projectNumber,
      'paidFromAccountId': paidFromAccountId,
      'paidFromAccountName': paidFromAccountName,
      'usedByAccountId': usedByAccountId,
      'usedByAccountName': usedByAccountName,
      'category': category.displayName,
      'paymentMethod': paymentMethod.displayName,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'description': description,
      'balanceAfterTransaction': balanceAfterTransaction,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVoided': isVoided,
      if (voidReason != null) 'voidReason': voidReason,
      if (voidedAt != null) 'voidedAt': Timestamp.fromDate(voidedAt!),
      'searchTokens': searchTokens.isNotEmpty
          ? searchTokens
          : generateSearchTokens(
              paymentName: paymentName,
              projectName: projectName,
              projectNumber: projectNumber,
              paidFrom: paidFromAccountName,
              usedBy: usedByAccountName,
              description: description,
              category: category.displayName,
            ),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? paymentName,
    double? amount,
    String? currency,
    String? projectId,
    String? projectName,
    String? projectNumber,
    String? paidFromAccountId,
    String? paidFromAccountName,
    String? usedByAccountId,
    String? usedByAccountName,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    DateTime? expenseDate,
    String? description,
    double? balanceAfterTransaction,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVoided,
    String? voidReason,
    DateTime? voidedAt,
    List<String>? searchTokens,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      paymentName: paymentName ?? this.paymentName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectNumber: projectNumber ?? this.projectNumber,
      paidFromAccountId: paidFromAccountId ?? this.paidFromAccountId,
      paidFromAccountName: paidFromAccountName ?? this.paidFromAccountName,
      usedByAccountId: usedByAccountId ?? this.usedByAccountId,
      usedByAccountName: usedByAccountName ?? this.usedByAccountName,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      balanceAfterTransaction:
          balanceAfterTransaction ?? this.balanceAfterTransaction,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVoided: isVoided ?? this.isVoided,
      voidReason: voidReason ?? this.voidReason,
      voidedAt: voidedAt ?? this.voidedAt,
      searchTokens: searchTokens ?? this.searchTokens,
    );
  }

  @override
  List<Object?> get props => [
        id,
        paymentName,
        amount,
        currency,
        projectId,
        projectName,
        projectNumber,
        paidFromAccountId,
        paidFromAccountName,
        usedByAccountId,
        usedByAccountName,
        category,
        paymentMethod,
        expenseDate,
        description,
        balanceAfterTransaction,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
        isVoided,
        voidReason,
        voidedAt,
      ];
}
