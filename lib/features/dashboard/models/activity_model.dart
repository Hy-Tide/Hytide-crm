// lib/features/dashboard/models/activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ActivityModel extends Equatable {
  final String id;
  final ActivityType type;
  final String description;
  final String userName;
  final String? userRole;
  final DateTime timestamp;
  final String? entityId;
  final String? entityType; // 'lead', 'client', 'project', 'quotation', 'followup'

  const ActivityModel({
    required this.id,
    required this.type,
    required this.description,
    required this.userName,
    this.userRole,
    required this.timestamp,
    this.entityId,
    this.entityType,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final typeStr = data['type'] as String? ?? 'leadCreated';
    final type = _parseActivityType(typeStr);

    final ts = data['timestamp'] as Timestamp? ??
        data['createdAt'] as Timestamp? ??
        Timestamp.now();

    return ActivityModel(
      id: doc.id,
      type: type,
      description: data['description'] as String? ?? '',
      userName: data['userName'] as String? ??
          data['user'] as String? ??
          data['createdByName'] as String? ??
          'Team Member',
      userRole: data['userRole'] as String?,
      timestamp: ts.toDate(),
      entityId: data['entityId'] as String?,
      entityType: data['entityType'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'userName': userName,
      if (userRole != null) 'userRole': userRole,
      'timestamp': Timestamp.fromDate(timestamp),
      if (entityId != null) 'entityId': entityId,
      if (entityType != null) 'entityType': entityType,
      'createdAt': Timestamp.fromDate(timestamp),
    };
  }

  static ActivityType _parseActivityType(String value) {
    for (final t in ActivityType.values) {
      if (t.name.toLowerCase() == value.toLowerCase()) {
        return t;
      }
    }
    return ActivityType.leadCreated;
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  IconData get icon {
    switch (type) {
      case ActivityType.leadCreated:
        return Icons.person_add_outlined;
      case ActivityType.leadUpdated:
        return Icons.edit_outlined;
      case ActivityType.statusChanged:
        return Icons.alt_route_rounded;
      case ActivityType.followUpCreated:
        return Icons.event_note_outlined;
      case ActivityType.followUpCompleted:
        return Icons.check_circle_outline_rounded;
      case ActivityType.followUpRescheduled:
        return Icons.event_repeat_rounded;
      case ActivityType.followUpCancelled:
        return Icons.cancel_outlined;
      case ActivityType.followUpReminderSent:
        return Icons.notifications_active_outlined;
      case ActivityType.noteAdded:
        return Icons.chat_bubble_outline_rounded;
      case ActivityType.documentUploaded:
        return Icons.upload_file_outlined;
      case ActivityType.quotationCreated:
        return Icons.receipt_long_outlined;
      case ActivityType.quotationUpdated:
        return Icons.edit_note_rounded;
      case ActivityType.quotationSent:
        return Icons.send_rounded;
      case ActivityType.quotationViewed:
        return Icons.visibility_outlined;
      case ActivityType.quotationAccepted:
        return Icons.check_circle_outline_rounded;
      case ActivityType.quotationRejected:
        return Icons.highlight_off_rounded;
      case ActivityType.quotationRevised:
        return Icons.history_edu_rounded;
      case ActivityType.quotationPdfGenerated:
        return Icons.picture_as_pdf_outlined;
      case ActivityType.quotationShared:
        return Icons.share_outlined;
      case ActivityType.quotationConvertedToProject:
        return Icons.rocket_launch_outlined;
      case ActivityType.quotationArchived:
        return Icons.archive_outlined;
      case ActivityType.quotationRestored:
        return Icons.unarchive_outlined;
      case ActivityType.quotationNoteAdded:
        return Icons.note_alt_outlined;
      case ActivityType.projectCreated:
        return Icons.folder_outlined;
      case ActivityType.projectUpdated:
        return Icons.edit_note_rounded;
      case ActivityType.projectStatusChanged:
        return Icons.published_with_changes_rounded;
      case ActivityType.projectPriorityChanged:
        return Icons.flag_outlined;
      case ActivityType.projectAssigned:
        return Icons.person_add_alt_1_outlined;
      case ActivityType.projectManagerChanged:
        return Icons.manage_accounts_outlined;
      case ActivityType.projectProgressUpdated:
        return Icons.trending_up_rounded;
      case ActivityType.projectMilestoneCreated:
        return Icons.flag_circle_outlined;
      case ActivityType.projectTaskCreated:
        return Icons.task_alt_rounded;
      case ActivityType.projectTaskCompleted:
        return Icons.check_circle_outline_rounded;
      case ActivityType.projectNoteAdded:
        return Icons.note_alt_outlined;
      case ActivityType.projectArchived:
        return Icons.archive_outlined;
      case ActivityType.projectRestored:
        return Icons.unarchive_outlined;
      case ActivityType.convertedToClient:
      case ActivityType.clientCreated:
      case ActivityType.clientCreatedFromLead:
        return Icons.verified_outlined;
      case ActivityType.clientUpdated:
        return Icons.business_outlined;
      case ActivityType.clientStatusChanged:
        return Icons.published_with_changes_rounded;
      case ActivityType.clientArchived:
        return Icons.archive_outlined;
      case ActivityType.clientRestored:
        return Icons.unarchive_outlined;
      case ActivityType.clientNoteAdded:
        return Icons.note_alt_outlined;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.leadCreated:
        return AppColors.primary;
      case ActivityType.leadUpdated:
        return AppColors.info;
      case ActivityType.statusChanged:
        return AppColors.secondary;
      case ActivityType.followUpCreated:
        return AppColors.warning;
      case ActivityType.followUpCompleted:
        return AppColors.success;
      case ActivityType.followUpRescheduled:
        return AppColors.info;
      case ActivityType.followUpCancelled:
        return AppColors.error;
      case ActivityType.followUpReminderSent:
        return AppColors.warning;
      case ActivityType.noteAdded:
        return AppColors.onSurfaceVariant;
      case ActivityType.documentUploaded:
        return AppColors.info;
      case ActivityType.quotationCreated:
        return AppColors.secondary;
      case ActivityType.quotationUpdated:
        return AppColors.info;
      case ActivityType.quotationSent:
        return AppColors.primary;
      case ActivityType.quotationViewed:
        return AppColors.info;
      case ActivityType.quotationAccepted:
        return AppColors.success;
      case ActivityType.quotationRejected:
        return AppColors.error;
      case ActivityType.quotationRevised:
        return AppColors.secondary;
      case ActivityType.quotationPdfGenerated:
        return AppColors.primary;
      case ActivityType.quotationShared:
        return AppColors.info;
      case ActivityType.quotationConvertedToProject:
        return AppColors.success;
      case ActivityType.quotationArchived:
        return AppColors.error;
      case ActivityType.quotationRestored:
        return AppColors.success;
      case ActivityType.quotationNoteAdded:
        return AppColors.onSurfaceVariant;
      case ActivityType.projectCreated:
        return AppColors.primary;
      case ActivityType.projectUpdated:
        return AppColors.info;
      case ActivityType.projectStatusChanged:
        return AppColors.secondary;
      case ActivityType.projectPriorityChanged:
        return AppColors.warning;
      case ActivityType.projectAssigned:
        return AppColors.primary;
      case ActivityType.projectManagerChanged:
        return AppColors.secondary;
      case ActivityType.projectProgressUpdated:
        return AppColors.success;
      case ActivityType.projectMilestoneCreated:
        return AppColors.secondary;
      case ActivityType.projectTaskCreated:
        return AppColors.info;
      case ActivityType.projectTaskCompleted:
        return AppColors.success;
      case ActivityType.projectNoteAdded:
        return AppColors.onSurfaceVariant;
      case ActivityType.projectArchived:
        return AppColors.error;
      case ActivityType.projectRestored:
        return AppColors.success;
      case ActivityType.convertedToClient:
      case ActivityType.clientCreated:
      case ActivityType.clientCreatedFromLead:
        return AppColors.success;
      case ActivityType.clientUpdated:
        return AppColors.primary;
      case ActivityType.clientStatusChanged:
        return AppColors.secondary;
      case ActivityType.clientArchived:
        return AppColors.error;
      case ActivityType.clientRestored:
        return AppColors.success;
      case ActivityType.clientNoteAdded:
        return AppColors.onSurfaceVariant;
    }
  }

  Color get backgroundColor {
    switch (type) {
      case ActivityType.leadCreated:
        return AppColors.primaryContainer;
      case ActivityType.leadUpdated:
        return AppColors.infoContainer;
      case ActivityType.statusChanged:
        return AppColors.secondaryContainer;
      case ActivityType.followUpCreated:
        return AppColors.warningContainer;
      case ActivityType.followUpCompleted:
        return AppColors.successContainer;
      case ActivityType.followUpRescheduled:
        return AppColors.infoContainer;
      case ActivityType.followUpCancelled:
        return AppColors.errorContainer;
      case ActivityType.followUpReminderSent:
        return AppColors.warningContainer;
      case ActivityType.noteAdded:
        return AppColors.surfaceVariant;
      case ActivityType.documentUploaded:
        return AppColors.infoContainer;
      case ActivityType.quotationCreated:
        return AppColors.secondaryContainer;
      case ActivityType.quotationUpdated:
        return AppColors.infoContainer;
      case ActivityType.quotationSent:
        return AppColors.primaryContainer;
      case ActivityType.quotationViewed:
        return AppColors.infoContainer;
      case ActivityType.quotationAccepted:
        return AppColors.successContainer;
      case ActivityType.quotationRejected:
        return AppColors.errorContainer;
      case ActivityType.quotationRevised:
        return AppColors.secondaryContainer;
      case ActivityType.quotationPdfGenerated:
        return AppColors.primaryContainer;
      case ActivityType.quotationShared:
        return AppColors.infoContainer;
      case ActivityType.quotationConvertedToProject:
        return AppColors.successContainer;
      case ActivityType.quotationArchived:
        return AppColors.errorContainer;
      case ActivityType.quotationRestored:
        return AppColors.successContainer;
      case ActivityType.quotationNoteAdded:
        return AppColors.surfaceVariant;
      case ActivityType.projectCreated:
        return AppColors.primaryContainer;
      case ActivityType.projectUpdated:
        return AppColors.infoContainer;
      case ActivityType.projectStatusChanged:
        return AppColors.secondaryContainer;
      case ActivityType.projectPriorityChanged:
        return AppColors.warningContainer;
      case ActivityType.projectAssigned:
        return AppColors.primaryContainer;
      case ActivityType.projectManagerChanged:
        return AppColors.secondaryContainer;
      case ActivityType.projectProgressUpdated:
        return AppColors.successContainer;
      case ActivityType.projectMilestoneCreated:
        return AppColors.secondaryContainer;
      case ActivityType.projectTaskCreated:
        return AppColors.infoContainer;
      case ActivityType.projectTaskCompleted:
        return AppColors.successContainer;
      case ActivityType.projectNoteAdded:
        return AppColors.surfaceVariant;
      case ActivityType.projectArchived:
        return AppColors.errorContainer;
      case ActivityType.projectRestored:
        return AppColors.successContainer;
      case ActivityType.convertedToClient:
      case ActivityType.clientCreated:
      case ActivityType.clientCreatedFromLead:
        return AppColors.successContainer;
      case ActivityType.clientUpdated:
        return AppColors.primaryContainer;
      case ActivityType.clientStatusChanged:
        return AppColors.secondaryContainer;
      case ActivityType.clientArchived:
        return AppColors.errorContainer;
      case ActivityType.clientRestored:
        return AppColors.successContainer;
      case ActivityType.clientNoteAdded:
        return AppColors.surfaceVariant;
    }
  }

  String get title {
    switch (type) {
      case ActivityType.leadCreated:
        return 'Lead created';
      case ActivityType.leadUpdated:
        return 'Lead updated';
      case ActivityType.statusChanged:
        return 'Lead status changed';
      case ActivityType.followUpCreated:
        return 'Follow-up scheduled';
      case ActivityType.followUpCompleted:
        return 'Follow-up completed';
      case ActivityType.followUpRescheduled:
        return 'Follow-up rescheduled';
      case ActivityType.followUpCancelled:
        return 'Follow-up cancelled';
      case ActivityType.followUpReminderSent:
        return 'Reminder sent';
      case ActivityType.noteAdded:
        return 'Note added';
      case ActivityType.documentUploaded:
        return 'Document uploaded';
      case ActivityType.quotationCreated:
        return 'Quotation created';
      case ActivityType.quotationUpdated:
        return 'Quotation updated';
      case ActivityType.quotationSent:
        return 'Quotation sent';
      case ActivityType.quotationViewed:
        return 'Quotation viewed';
      case ActivityType.quotationAccepted:
        return 'Quotation accepted';
      case ActivityType.quotationRejected:
        return 'Quotation rejected';
      case ActivityType.quotationRevised:
        return 'Quotation revised';
      case ActivityType.quotationPdfGenerated:
        return 'PDF generated';
      case ActivityType.quotationShared:
        return 'Quotation shared';
      case ActivityType.quotationConvertedToProject:
        return 'Converted to project';
      case ActivityType.quotationArchived:
        return 'Quotation archived';
      case ActivityType.quotationRestored:
        return 'Quotation restored';
      case ActivityType.quotationNoteAdded:
        return 'Quotation note added';
      case ActivityType.projectCreated:
        return 'Project created';
      case ActivityType.projectUpdated:
        return 'Project updated';
      case ActivityType.projectStatusChanged:
        return 'Project status changed';
      case ActivityType.projectPriorityChanged:
        return 'Project priority changed';
      case ActivityType.projectAssigned:
        return 'Project assigned';
      case ActivityType.projectManagerChanged:
        return 'Project manager changed';
      case ActivityType.projectProgressUpdated:
        return 'Project progress updated';
      case ActivityType.projectMilestoneCreated:
        return 'Milestone created';
      case ActivityType.projectTaskCreated:
        return 'Task created';
      case ActivityType.projectTaskCompleted:
        return 'Task completed';
      case ActivityType.projectNoteAdded:
        return 'Project note added';
      case ActivityType.projectArchived:
        return 'Project archived';
      case ActivityType.projectRestored:
        return 'Project restored';
      case ActivityType.convertedToClient:
        return 'Converted to client';
      case ActivityType.clientCreated:
        return 'Client created';
      case ActivityType.clientCreatedFromLead:
        return 'Client created from lead';
      case ActivityType.clientUpdated:
        return 'Client updated';
      case ActivityType.clientStatusChanged:
        return 'Client status changed';
      case ActivityType.clientArchived:
        return 'Client archived';
      case ActivityType.clientRestored:
        return 'Client restored';
      case ActivityType.clientNoteAdded:
        return 'Client note added';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        description,
        userName,
        userRole,
        timestamp,
        entityId,
        entityType,
      ];
}
