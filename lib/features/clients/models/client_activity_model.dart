// lib/features/clients/models/client_activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClientActivityModel extends Equatable {
  final String id;
  final String type;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const ClientActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.metadata,
  });

  factory ClientActivityModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClientActivityModel(
      id: doc.id,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
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
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, type, title, createdBy, createdAt];
}
