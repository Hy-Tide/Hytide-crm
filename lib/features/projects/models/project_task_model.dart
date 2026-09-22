// lib/features/projects/models/project_task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProjectTaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'completed', 'blocked'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String assignedTo;
  final String assignedToName;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String createdBy;
  final DateTime createdAt;

  const ProjectTaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'todo',
    this.priority = 'medium',
    this.assignedTo = '',
    this.assignedToName = '',
    this.dueDate,
    this.completedAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  factory ProjectTaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ProjectTaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'todo',
      priority: data['priority'] as String? ?? 'medium',
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, title, status, priority, assignedTo, dueDate, completedAt];
}
