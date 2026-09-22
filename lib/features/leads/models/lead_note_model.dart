// lib/features/leads/models/lead_note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class LeadNoteModel extends Equatable {
  final String id;
  final String content;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get authorName => createdByName;
  String get authorId => createdBy;
  String get timeAgo => formattedDate;

  const LeadNoteModel({
    required this.id,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeadNoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdTs = data['createdAt'] as Timestamp? ?? Timestamp.now();
    final updatedTs = data['updatedAt'] as Timestamp? ?? createdTs;

    return LeadNoteModel(
      id: doc.id,
      content: data['content'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Team Member',
      createdAt: createdTs.toDate(),
      updatedAt: updatedTs.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy • hh:mm a').format(createdAt);
  }

  @override
  List<Object?> get props => [id, content, createdBy, createdAt, updatedAt];
}
