// lib/features/projects/models/project_milestone_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProjectMilestoneModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final DateTime? completedDate;
  final String status; // 'pending', 'in_progress', 'completed', 'delayed'
  final int progressPercentage;
  final double amount;
  final String createdBy;
  final DateTime createdAt;

  const ProjectMilestoneModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.targetDate,
    this.completedDate,
    this.status = 'pending',
    this.progressPercentage = 0,
    this.amount = 0.0,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  factory ProjectMilestoneModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ProjectMilestoneModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      status: data['status'] as String? ?? 'pending',
      progressPercentage: (data['progressPercentage'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'targetDate': Timestamp.fromDate(targetDate),
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'status': status,
      'progressPercentage': progressPercentage,
      'amount': amount,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, title, targetDate, status, progressPercentage, amount];
}
