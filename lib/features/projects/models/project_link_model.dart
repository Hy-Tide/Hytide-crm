// lib/features/projects/models/project_link_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ProjectLink extends Equatable {
  final String id;
  final String name;
  final String type;
  final String url;
  final String description;
  final String addedBy;
  final String addedByName;
  final DateTime addedAt;

  const ProjectLink({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.description = '',
    required this.addedBy,
    this.addedByName = 'Admin',
    required this.addedAt,
  });

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'figma':
        return Icons.design_services_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'google drive':
        return Icons.add_to_drive_rounded;
      case 'notion':
        return Icons.description_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'contract':
        return Icons.history_edu_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  factory ProjectLink.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProjectLink(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'Link',
      url: data['url'] as String? ?? '',
      description: data['description'] as String? ?? '',
      addedBy: data['addedBy'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? 'Admin',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'url': url,
      'description': description,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  @override
  List<Object?> get props => [id, name, type, url, description, addedBy, addedAt];
}
