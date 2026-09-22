// lib/features/expenses/models/expense_activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ExpenseActivityType {
  created,
  edited,
  amountChanged,
  accountChanged,
  projectChanged,
  voided,
  restored;

  String get displayName {
    switch (this) {
      case ExpenseActivityType.created:
        return 'Created';
      case ExpenseActivityType.edited:
        return 'Edited';
      case ExpenseActivityType.amountChanged:
        return 'Amount Changed';
      case ExpenseActivityType.accountChanged:
        return 'Account Changed';
      case ExpenseActivityType.projectChanged:
        return 'Project Changed';
      case ExpenseActivityType.voided:
        return 'Voided';
      case ExpenseActivityType.restored:
        return 'Restored';
    }
  }

  static ExpenseActivityType fromString(String? value) {
    if (value == null) return ExpenseActivityType.created;
    for (final t in ExpenseActivityType.values) {
      if (t.name == value) return t;
    }
    return ExpenseActivityType.created;
  }
}

class ExpenseActivityModel extends Equatable {
  final String id;
  final String expenseId;
  final ExpenseActivityType type;
  final String description;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const ExpenseActivityModel({
    required this.id,
    required this.expenseId,
    required this.type,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.metadata,
  });

  factory ExpenseActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseActivityModel(
      id: doc.id,
      expenseId: data['expenseId'] as String? ?? '',
      type: ExpenseActivityType.fromString(data['type'] as String?),
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'type': type.name,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        expenseId,
        type,
        description,
        createdBy,
        createdByName,
        createdAt,
        metadata,
      ];
}
