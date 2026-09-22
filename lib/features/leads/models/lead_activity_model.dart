// lib/features/leads/models/lead_activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class LeadActivityModel extends Equatable {
  final String id;
  final String type;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const LeadActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.metadata = const {},
  });

  factory LeadActivityModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp? ??
        data['timestamp'] as Timestamp? ??
        Timestamp.now();

    return LeadActivityModel(
      id: doc.id,
      type: data['type'] as String? ?? 'lead_created',
      title: data['title'] as String? ?? 'Activity',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Team Member',
      createdAt: ts.toDate(),
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

  String get timeAgo => relativeTime;
  String get actorName => createdByName;
  String get iconName => type;
  String get colorHex => '#2563EB';

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(createdAt);
    }
  }

  IconData get icon {
    switch (type) {
      case 'lead_created':
        return Icons.person_add_rounded;
      case 'lead_updated':
        return Icons.edit_rounded;
      case 'status_changed':
        return Icons.alt_route_rounded;
      case 'priority_changed':
        return Icons.flag_rounded;
      case 'assignment_changed':
        return Icons.badge_rounded;
      case 'note_added':
        return Icons.chat_bubble_outline_rounded;
      case 'followup_created':
        return Icons.event_note_rounded;
      case 'followup_completed':
        return Icons.check_circle_rounded;
      case 'document_added':
        return Icons.upload_file_rounded;
      case 'document_removed':
        return Icons.delete_outline_rounded;
      case 'quotation_created':
        return Icons.receipt_long_rounded;
      case 'converted_to_client':
        return Icons.verified_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'lead_created':
      case 'converted_to_client':
      case 'followup_completed':
        return AppColors.success;
      case 'status_changed':
      case 'assignment_changed':
        return AppColors.primary;
      case 'priority_changed':
      case 'followup_created':
        return AppColors.warning;
      case 'document_removed':
        return AppColors.error;
      case 'note_added':
      case 'document_added':
      case 'quotation_created':
        return AppColors.info;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color get backgroundColor {
    switch (type) {
      case 'lead_created':
      case 'converted_to_client':
      case 'followup_completed':
        return AppColors.successContainer;
      case 'status_changed':
      case 'assignment_changed':
        return AppColors.primaryContainer;
      case 'priority_changed':
      case 'followup_created':
        return AppColors.warningContainer;
      case 'document_removed':
        return AppColors.errorContainer;
      case 'note_added':
      case 'document_added':
      case 'quotation_created':
        return AppColors.infoContainer;
      default:
        return AppColors.surfaceVariant;
    }
  }

  @override
  List<Object?> get props => [id, type, title, description, createdBy, createdAt];
}
