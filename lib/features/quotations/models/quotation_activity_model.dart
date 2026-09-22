// lib/features/quotations/models/quotation_activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class QuotationActivityModel extends Equatable {
  final String id;
  final String type;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const QuotationActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.metadata = const {},
  });

  factory QuotationActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return QuotationActivityModel(
      id: doc.id,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, type, title, description, createdBy, createdAt];
}
