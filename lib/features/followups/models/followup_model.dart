// lib/features/followups/models/followup_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';

class FollowUpModel extends Equatable {
  final String id;
  final String leadId;
  final String leadName;
  final String companyName;

  final String title;
  final String description;

  final FollowUpType type;
  final FollowUpStatus status;
  final FollowUpPriority priority;

  final DateTime scheduledAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final DateTime? reminderAt;
  final bool reminderSent;
  final DateTime? reminderSentAt;
  final String? reminderNotificationId;

  final String assignedTo;
  final String assignedToName;

  final String createdBy;
  final String createdByName;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String? completionNote;
  final String? rescheduleReason;
  final String? cancelReason;

  // Optional Client linkage
  final String? clientId;
  final String? clientName;

  const FollowUpModel({
    required this.id,
    required this.leadId,
    required this.leadName,
    required this.companyName,
    required this.title,
    this.description = '',
    required this.type,
    this.status = FollowUpStatus.pending,
    this.priority = FollowUpPriority.medium,
    required this.scheduledAt,
    this.completedAt,
    this.cancelledAt,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 30,
    this.reminderAt,
    this.reminderSent = false,
    this.reminderSentAt,
    this.reminderNotificationId,
    required this.assignedTo,
    required this.assignedToName,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.completionNote,
    this.rescheduleReason,
    this.cancelReason,
    this.clientId,
    this.clientName,
  });

  /// Legacy compatibility getters
  DateTime get date => scheduledAt;
  DateTime get fullDateTime => scheduledAt;
  TimeOfDay get time => TimeOfDay.fromDateTime(scheduledAt);
  int get timeHour => scheduledAt.hour;
  int get timeMinute => scheduledAt.minute;
  String get notes => description;
  ReminderMinutes get reminderBefore =>
      ReminderMinutes.fromMinutes(reminderMinutesBefore);

  /// Overdue means pending status and scheduled time in the past.
  bool get isOverdue =>
      status == FollowUpStatus.pending && scheduledAt.isBefore(DateTime.now());

  /// Whether scheduledAt falls on today in Asia/Kolkata (IST).
  bool get isToday => TimezoneHelper.isTodayIST(scheduledAt);

  /// Whether scheduledAt falls on tomorrow in Asia/Kolkata (IST).
  bool get isTomorrow => TimezoneHelper.isTomorrowIST(scheduledAt);

  /// Human duration text e.g. "Overdue by 2 hours"
  String get overdueDurationString => TimezoneHelper.getOverdueText(scheduledAt);

  /// Formatted date in IST
  String get formattedDate => TimezoneHelper.formatDateIST(scheduledAt);

  /// Formatted time in IST
  String get formattedTime => TimezoneHelper.formatTimeIST(scheduledAt);

  /// Formatted full date & time in IST
  String get formattedDateTime => TimezoneHelper.formatIST(scheduledAt);

  /// Calculate reminder target time given scheduled time and minutes before
  static DateTime? calculateReminderAt({
    required bool enabled,
    required int minutesBefore,
    required DateTime scheduledTime,
  }) {
    if (!enabled) return null;
    return scheduledTime.subtract(Duration(minutes: minutesBefore));
  }

  factory FollowUpModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Support backward compatibility for legacy date field if scheduledAt is missing
    DateTime scheduled;
    if (data['scheduledAt'] is Timestamp) {
      scheduled = (data['scheduledAt'] as Timestamp).toDate();
    } else if (data['date'] is Timestamp) {
      final legacyDate = (data['date'] as Timestamp).toDate();
      final hour = data['timeHour'] as int? ?? 9;
      final minute = data['timeMinute'] as int? ?? 0;
      scheduled = DateTime(
        legacyDate.year,
        legacyDate.month,
        legacyDate.day,
        hour,
        minute,
      );
    } else {
      scheduled = DateTime.now();
    }

    final reminderEnabled = data['reminderEnabled'] as bool? ??
        (data['reminderMinutes'] != null && (data['reminderMinutes'] as int) > 0);
    final reminderMinutes = data['reminderMinutesBefore'] as int? ??
        data['reminderMinutes'] as int? ??
        30;

    DateTime? reminderAt;
    if (data['reminderAt'] is Timestamp) {
      reminderAt = (data['reminderAt'] as Timestamp).toDate();
    } else if (reminderEnabled) {
      reminderAt = scheduled.subtract(Duration(minutes: reminderMinutes));
    }

    return FollowUpModel(
      id: doc.id,
      leadId: data['leadId'] as String? ?? '',
      leadName: data['leadName'] as String? ?? '',
      companyName: data['companyName'] as String? ??
          data['leadName'] as String? ??
          '',
      title: data['title'] as String? ??
          (data['notes'] != null && (data['notes'] as String).isNotEmpty
              ? (data['notes'] as String)
              : 'Follow-up with ${data['companyName'] ?? data['leadName'] ?? 'Lead'}'),
      description: data['description'] as String? ?? data['notes'] as String? ?? '',
      type: FollowUpType.fromString(data['type'] as String? ?? 'call'),
      status: FollowUpStatus.fromString(data['status'] as String? ?? 'pending'),
      priority: FollowUpPriority.fromString(data['priority'] as String? ?? 'medium'),
      scheduledAt: scheduled,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutes,
      reminderAt: reminderAt,
      reminderSent: data['reminderSent'] as bool? ?? false,
      reminderSentAt: (data['reminderSentAt'] as Timestamp?)?.toDate(),
      reminderNotificationId: data['reminderNotificationId'] as String?,
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completionNote: data['completionNote'] as String?,
      rescheduleReason: data['rescheduleReason'] as String?,
      cancelReason: data['cancelReason'] as String?,
      clientId: data['clientId'] as String?,
      clientName: data['clientName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leadId': leadId,
      'leadName': leadName,
      'companyName': companyName,
      if (clientId != null) 'clientId': clientId,
      if (clientName != null) 'clientName': clientName,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'reminderSent': reminderSent,
      'reminderSentAt': reminderSentAt != null ? Timestamp.fromDate(reminderSentAt!) : null,
      'reminderNotificationId': reminderNotificationId,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completionNote': completionNote,
      'rescheduleReason': rescheduleReason,
      'cancelReason': cancelReason,
      // Legacy compatibility keys so existing dashboard queries continue functioning
      'date': Timestamp.fromDate(scheduledAt),
      'timeHour': scheduledAt.hour,
      'timeMinute': scheduledAt.minute,
      'notes': description,
      'reminderMinutes': reminderMinutesBefore,
    };
  }

  FollowUpModel copyWith({
    String? id,
    String? leadId,
    String? leadName,
    String? companyName,
    String? title,
    String? description,
    FollowUpType? type,
    FollowUpStatus? status,
    FollowUpPriority? priority,
    DateTime? scheduledAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    DateTime? reminderAt,
    bool? reminderSent,
    DateTime? reminderSentAt,
    String? reminderNotificationId,
    String? assignedTo,
    String? assignedToName,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? completionNote,
    String? rescheduleReason,
    String? cancelReason,
    String? clientId,
    String? clientName,
  }) {
    return FollowUpModel(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      reminderNotificationId: reminderNotificationId ?? this.reminderNotificationId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completionNote: completionNote ?? this.completionNote,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      cancelReason: cancelReason ?? this.cancelReason,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        leadId,
        companyName,
        title,
        type,
        status,
        priority,
        scheduledAt,
        reminderEnabled,
        reminderMinutesBefore,
        reminderSent,
        assignedTo,
        clientId,
      ];
}
