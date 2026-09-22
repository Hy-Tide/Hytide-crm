// lib/features/followups/models/followup_note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/timezone_helper.dart';

class FollowUpNoteModel extends Equatable {
  final String id;
  final String note;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  const FollowUpNoteModel({
    required this.id,
    required this.note,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  String get formattedCreatedAt => TimezoneHelper.formatIST(createdAt);

  factory FollowUpNoteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return FollowUpNoteModel(
      id: doc.id,
      note: data['note'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note': note,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, note, createdBy, createdAt];
}
