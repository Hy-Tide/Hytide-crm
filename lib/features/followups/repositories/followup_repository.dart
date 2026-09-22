// lib/features/followups/repositories/followup_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/followup_filter_model.dart';
import '../models/followup_model.dart';
import '../models/followup_note_model.dart';

class FollowUpCounts {
  final int today;
  final int upcoming;
  final int overdue;
  final int completed;
  final int highPriority;

  const FollowUpCounts({
    this.today = 0,
    this.upcoming = 0,
    this.overdue = 0,
    this.completed = 0,
    this.highPriority = 0,
  });
}

class FollowUpRepository {
  final FirebaseFirestore _db;
  final String? currentUserId;
  final UserRole currentUserRole;

  FollowUpRepository({
    required FirebaseFirestore db,
    required this.currentUserId,
    required this.currentUserRole,
  }) : _db = db;

  CollectionReference<Map<String, dynamic>> get _followups =>
      _db.collection(AppCollections.followups);

  CollectionReference<Map<String, dynamic>> get _leads =>
      _db.collection(AppCollections.leads);

  CollectionReference<Map<String, dynamic>> get _clients =>
      _db.collection(AppCollections.clients);

  CollectionReference<Map<String, dynamic>> get _globalActivities =>
      _db.collection(AppCollections.activities);

  CollectionReference<Map<String, dynamic>> _notes(String followUpId) =>
      _followups.doc(followUpId).collection('notes');

  CollectionReference<Map<String, dynamic>> _leadActivities(String leadId) =>
      _leads.doc(leadId).collection('activities');

  Query<Map<String, dynamic>> _baseQuery() {
    if (currentUserRole == UserRole.salesStaff && currentUserId != null) {
      return _followups.where('assignedTo', isEqualTo: currentUserId);
    }
    return _followups;
  }

  // ─── Live Streams ──────────────────────────────────────────────────────────

  /// Stream today's pending follow-ups (Asia/Kolkata boundary)
  Stream<List<FollowUpModel>> streamTodaysFollowUps() {
    final start = TimezoneHelper.startOfTodayUtc();
    final end = TimezoneHelper.endOfTodayUtc();

    return _baseQuery()
        .where('status', isEqualTo: FollowUpStatus.pending.name)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(FollowUpModel.fromFirestore).toList();
      items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return items;
    }).handleError((_) => <FollowUpModel>[]);
  }

  /// Stream overdue follow-ups (scheduledAt < now AND status == pending)
  Stream<List<FollowUpModel>> streamOverdueFollowUps({int limit = 50}) {
    final now = DateTime.now();
    return _baseQuery()
        .where('status', isEqualTo: FollowUpStatus.pending.name)
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduledAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map(FollowUpModel.fromFirestore).toList();
    }).handleError((_) => <FollowUpModel>[]);
  }

  /// Stream upcoming pending follow-ups (scheduledAt > end of today IST)
  Stream<List<FollowUpModel>> streamUpcomingFollowUps({int limit = 50}) {
    final endOfToday = TimezoneHelper.endOfTodayUtc();
    return _baseQuery()
        .where('status', isEqualTo: FollowUpStatus.pending.name)
        .where('scheduledAt', isGreaterThan: Timestamp.fromDate(endOfToday))
        .orderBy('scheduledAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map(FollowUpModel.fromFirestore).toList();
    }).handleError((_) => <FollowUpModel>[]);
  }

  /// Stream all follow-ups for a specific lead
  Stream<List<FollowUpModel>> streamByLead(String leadId) {
    return _followups
        .where('leadId', isEqualTo: leadId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FollowUpModel.fromFirestore).toList())
        .handleError((_) => <FollowUpModel>[]);
  }

  /// Stream filtered follow-ups for list view
  Stream<List<FollowUpModel>> streamFollowUpsWithFilter(FollowUpFilter filter) {
    Query<Map<String, dynamic>> query = _baseQuery();

    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.name);
    }
    if (filter.priority != null) {
      query = query.where('priority', isEqualTo: filter.priority!.name);
    }
    if (filter.type != null) {
      query = query.where('type', isEqualTo: filter.type!.name);
    }
    if (filter.assignedTo != null && filter.assignedTo!.isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: filter.assignedTo);
    }
    if (filter.reminderEnabled != null) {
      query = query.where('reminderEnabled', isEqualTo: filter.reminderEnabled);
    }

    // Apply date range filters if specified
    DateTime? start;
    DateTime? end;
    switch (filter.dateFilter) {
      case FollowUpDateFilter.today:
        start = TimezoneHelper.startOfTodayUtc();
        end = TimezoneHelper.endOfTodayUtc();
        break;
      case FollowUpDateFilter.tomorrow:
        start = TimezoneHelper.startOfTomorrowUtc();
        end = TimezoneHelper.endOfTomorrowUtc();
        break;
      case FollowUpDateFilter.thisWeek:
        start = TimezoneHelper.startOfWeekUtc();
        end = TimezoneHelper.endOfWeekUtc();
        break;
      case FollowUpDateFilter.nextWeek:
        start = TimezoneHelper.startOfNextWeekUtc();
        end = TimezoneHelper.endOfNextWeekUtc();
        break;
      case FollowUpDateFilter.overdue:
        end = DateTime.now();
        break;
      case FollowUpDateFilter.custom:
        start = filter.customStartDate;
        end = filter.customEndDate;
        break;
      case FollowUpDateFilter.all:
        break;
    }

    if (start != null) {
      query = query.where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    query = query.orderBy('scheduledAt', descending: false);

    return query.limit(100).snapshots().map((snap) {
      return snap.docs.map(FollowUpModel.fromFirestore).toList();
    }).handleError((_) => <FollowUpModel>[]);
  }

  /// Get follow-ups for calendar view across a specific date range
  Future<List<FollowUpModel>> getCalendarFollowUps({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    try {
      final snap = await _baseQuery()
          .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
          .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
          .orderBy('scheduledAt', descending: false)
          .get();

      return snap.docs.map(FollowUpModel.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── KPI Counts ─────────────────────────────────────────────────────────────

  Future<FollowUpCounts> getFollowUpCounts() async {
    try {
      final now = DateTime.now();
      final startToday = TimezoneHelper.startOfTodayUtc();
      final endToday = TimezoneHelper.endOfTodayUtc();

      final todayCount = await _safeCount(
        _baseQuery()
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startToday))
            .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endToday)),
      );

      final overdueCount = await _safeCount(
        _baseQuery()
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isLessThan: Timestamp.fromDate(now)),
      );

      final upcomingCount = await _safeCount(
        _baseQuery()
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isGreaterThan: Timestamp.fromDate(endToday)),
      );

      final completedCount = await _safeCount(
        _baseQuery().where('status', isEqualTo: FollowUpStatus.completed.name),
      );

      final highPriorityCount = await _safeCount(
        _baseQuery()
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('priority', whereIn: [
              FollowUpPriority.high.name,
              FollowUpPriority.urgent.name,
            ]),
      );

      return FollowUpCounts(
        today: todayCount,
        upcoming: upcomingCount,
        overdue: overdueCount,
        completed: completedCount,
        highPriority: highPriorityCount,
      );
    } catch (_) {
      return const FollowUpCounts();
    }
  }

  // ─── CRUD Operations ────────────────────────────────────────────────────────

  Future<FollowUpModel?> getFollowUp(String id) async {
    try {
      final doc = await _followups.doc(id).get();
      if (!doc.exists) return null;
      return FollowUpModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Stream<FollowUpModel?> streamFollowUp(String id) {
    return _followups.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FollowUpModel.fromFirestore(doc);
    }).handleError((_) => null);
  }

  /// Create a new follow-up and synchronize lead nextFollowUpAt & activity timeline
  Future<String> createFollowUp(FollowUpModel followup) async {
    final reminderAt = FollowUpModel.calculateReminderAt(
      enabled: followup.reminderEnabled,
      minutesBefore: followup.reminderMinutesBefore,
      scheduledTime: followup.scheduledAt,
    );

    final modelToSave = followup.copyWith(
      reminderAt: reminderAt,
      reminderSent: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _followups.add(modelToSave.toMap());
    final createdId = docRef.id;

    // Log activity on lead
    await _logActivity(
      leadId: followup.leadId,
      type: 'followup_created',
      title: 'Follow-up scheduled',
      description: '${followup.type.displayName}: "${followup.title}" scheduled for ${followup.formattedDateTime}',
      metadata: {
        'followUpId': createdId,
        'scheduledAt': followup.scheduledAt.toIso8601String(),
        'type': followup.type.name,
        'priority': followup.priority.name,
      },
    );

    // Recalculate lead's next pending follow-up date
    await recalculateLeadNextFollowUp(followup.leadId);
    if (followup.clientId != null && followup.clientId!.isNotEmpty) {
      await recalculateClientNextFollowUp(followup.clientId!);
    }

    return createdId;
  }

  /// Update an existing follow-up
  Future<void> updateFollowUp(FollowUpModel followup) async {
    final reminderAt = FollowUpModel.calculateReminderAt(
      enabled: followup.reminderEnabled,
      minutesBefore: followup.reminderMinutesBefore,
      scheduledTime: followup.scheduledAt,
    );

    final modelToSave = followup.copyWith(
      reminderAt: reminderAt,
      reminderSent: false,
      updatedAt: DateTime.now(),
    );

    await _followups.doc(followup.id).update(modelToSave.toMap());

    await _logActivity(
      leadId: followup.leadId,
      type: 'followup_updated',
      title: 'Follow-up updated',
      description: 'Updated follow-up "${followup.title}"',
      metadata: {
        'followUpId': followup.id,
        'scheduledAt': followup.scheduledAt.toIso8601String(),
        'type': followup.type.name,
      },
    );

    await recalculateLeadNextFollowUp(followup.leadId);
    if (followup.clientId != null && followup.clientId!.isNotEmpty) {
      await recalculateClientNextFollowUp(followup.clientId!);
    }
  }

  /// Complete follow-up with optional completion note
  Future<void> completeFollowUp(
    String id, {
    String? completionNote,
  }) async {
    final followup = await getFollowUp(id);
    if (followup == null) return;

    final now = DateTime.now();
    await _followups.doc(id).update({
      'status': FollowUpStatus.completed.name,
      'completedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      if (completionNote != null && completionNote.isNotEmpty)
        'completionNote': completionNote,
    });

    await _logActivity(
      leadId: followup.leadId,
      type: 'followup_completed',
      title: 'Follow-up completed',
      description: 'Completed follow-up "${followup.title}"' +
          (completionNote != null && completionNote.isNotEmpty
              ? '. Note: $completionNote'
              : ''),
      metadata: {
        'followUpId': id,
        'completedAt': now.toIso8601String(),
      },
    );

    await recalculateLeadNextFollowUp(followup.leadId);
    if (followup.clientId != null && followup.clientId!.isNotEmpty) {
      await recalculateClientNextFollowUp(followup.clientId!);
    }
  }

  /// Reschedule follow-up to new date & time with reason
  Future<void> rescheduleFollowUp(
    String id, {
    required DateTime newScheduledAt,
    required String reason,
  }) async {
    final followup = await getFollowUp(id);
    if (followup == null) return;

    final now = DateTime.now();
    final reminderAt = FollowUpModel.calculateReminderAt(
      enabled: followup.reminderEnabled,
      minutesBefore: followup.reminderMinutesBefore,
      scheduledTime: newScheduledAt,
    );

    await _followups.doc(id).update({
      'scheduledAt': Timestamp.fromDate(newScheduledAt),
      'date': Timestamp.fromDate(newScheduledAt),
      'timeHour': newScheduledAt.hour,
      'timeMinute': newScheduledAt.minute,
      'status': FollowUpStatus.pending.name,
      'rescheduleReason': reason,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
      'reminderSent': false,
      'updatedAt': Timestamp.fromDate(now),
    });

    await _logActivity(
      leadId: followup.leadId,
      type: 'followup_rescheduled',
      title: 'Follow-up rescheduled',
      description: 'Rescheduled "${followup.title}" to ${TimezoneHelper.formatIST(newScheduledAt)}. Reason: $reason',
      metadata: {
        'followUpId': id,
        'oldScheduledAt': followup.scheduledAt.toIso8601String(),
        'newScheduledAt': newScheduledAt.toIso8601String(),
        'reason': reason,
      },
    );

    await recalculateLeadNextFollowUp(followup.leadId);
    if (followup.clientId != null && followup.clientId!.isNotEmpty) {
      await recalculateClientNextFollowUp(followup.clientId!);
    }
  }

  /// Cancel follow-up with reason
  Future<void> cancelFollowUp(
    String id, {
    required String reason,
  }) async {
    final followup = await getFollowUp(id);
    if (followup == null) return;

    final now = DateTime.now();
    await _followups.doc(id).update({
      'status': FollowUpStatus.cancelled.name,
      'cancelledAt': Timestamp.fromDate(now),
      'cancelReason': reason,
      'updatedAt': Timestamp.fromDate(now),
    });

    await _logActivity(
      leadId: followup.leadId,
      type: 'followup_cancelled',
      title: 'Follow-up cancelled',
      description: 'Cancelled follow-up "${followup.title}". Reason: $reason',
      metadata: {
        'followUpId': id,
        'cancelledAt': now.toIso8601String(),
        'reason': reason,
      },
    );

    await recalculateLeadNextFollowUp(followup.leadId);
    if (followup.clientId != null && followup.clientId!.isNotEmpty) {
      await recalculateClientNextFollowUp(followup.clientId!);
    }
  }

  /// Delete follow-up permanently with audit
  Future<void> deleteFollowUp(String id) async {
    final followup = await getFollowUp(id);
    if (followup == null) return;

    await _followups.doc(id).delete();

    await _logActivity(
      leadId: followup.leadId,
      type: 'followup_deleted',
      title: 'Follow-up deleted',
      description: 'Deleted follow-up "${followup.title}"',
      metadata: {
        'followUpId': id,
      },
    );

    await recalculateLeadNextFollowUp(followup.leadId);
    if (followup.clientId != null && followup.clientId!.isNotEmpty) {
      await recalculateClientNextFollowUp(followup.clientId!);
    }
  }

  // ─── Lead Synchronization ──────────────────────────────────────────────────

  /// Recalculates and updates the nearest pending follow-up timestamp on the lead
  Future<void> recalculateLeadNextFollowUp(String leadId) async {
    if (leadId.isEmpty) return;

    try {
      final now = DateTime.now();

      // Query future pending follow-ups first
      var snap = await _followups
          .where('leadId', isEqualTo: leadId)
          .where('status', isEqualTo: FollowUpStatus.pending.name)
          .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('scheduledAt', descending: false)
          .limit(1)
          .get();

      DateTime? nextAt;
      if (snap.docs.isNotEmpty) {
        nextAt = (snap.docs.first.data()['scheduledAt'] as Timestamp?)?.toDate();
      } else {
        // Fallback: check if any pending follow-up exists (even if overdue)
        final overdueSnap = await _followups
            .where('leadId', isEqualTo: leadId)
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .orderBy('scheduledAt', descending: false)
            .limit(1)
            .get();

        if (overdueSnap.docs.isNotEmpty) {
          nextAt = (overdueSnap.docs.first.data()['scheduledAt'] as Timestamp?)?.toDate();
        }
      }

      await _leads.doc(leadId).update({
        'nextFollowUpAt': nextAt != null ? Timestamp.fromDate(nextAt) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-blocking sync
    }
  }

  /// Recalculates and updates the nearest pending follow-up timestamp on the client
  Future<void> recalculateClientNextFollowUp(String clientId) async {
    if (clientId.isEmpty) return;

    try {
      final now = DateTime.now();

      // Query future pending follow-ups first
      var snap = await _followups
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: FollowUpStatus.pending.name)
          .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('scheduledAt', descending: false)
          .limit(1)
          .get();

      DateTime? nextAt;
      if (snap.docs.isNotEmpty) {
        nextAt = (snap.docs.first.data()['scheduledAt'] as Timestamp?)?.toDate();
      } else {
        // Fallback: check if any pending follow-up exists (even if overdue)
        final overdueSnap = await _followups
            .where('clientId', isEqualTo: clientId)
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .orderBy('scheduledAt', descending: false)
            .limit(1)
            .get();

        if (overdueSnap.docs.isNotEmpty) {
          nextAt = (overdueSnap.docs.first.data()['scheduledAt'] as Timestamp?)?.toDate();
        }
      }

      await _clients.doc(clientId).update({
        'nextFollowUpAt': nextAt != null ? Timestamp.fromDate(nextAt) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-blocking sync
    }
  }

  /// Stream follow-ups for a specific client
  Stream<List<FollowUpModel>> streamClientFollowUps(
    String clientId, {
    String? sourceLeadId,
  }) {
    return _followups.snapshots().map((snap) {
      final items = snap.docs.map(FollowUpModel.fromFirestore).where((f) {
        if (f.clientId == clientId) return true;
        if (sourceLeadId != null &&
            sourceLeadId.isNotEmpty &&
            f.leadId == sourceLeadId) {
          return true;
        }
        return false;
      }).toList();
      items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return items;
    }).handleError((_) => <FollowUpModel>[]);
  }

  // ─── Subcollection Notes ────────────────────────────────────────────────────

  Stream<List<FollowUpNoteModel>> streamNotes(String followUpId) {
    return _notes(followUpId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FollowUpNoteModel.fromFirestore).toList())
        .handleError((_) => <FollowUpNoteModel>[]);
  }

  Future<void> addNote(
    String followUpId, {
    required String note,
    required String createdBy,
    required String createdByName,
  }) async {
    await _notes(followUpId).add({
      'note': note.trim(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String followUpId, String noteId) async {
    await _notes(followUpId).doc(noteId).delete();
  }

  // ─── Search ─────────────────────────────────────────────────────────────────

  /// Client-side debounced search over fetched query
  List<FollowUpModel> filterBySearch(List<FollowUpModel> items, String query) {
    if (query.trim().isEmpty) return items;
    final q = query.toLowerCase().trim();
    return items.where((f) {
      return f.companyName.toLowerCase().contains(q) ||
          f.leadName.toLowerCase().contains(q) ||
          f.title.toLowerCase().contains(q) ||
          f.assignedToName.toLowerCase().contains(q) ||
          f.description.toLowerCase().contains(q);
    }).toList();
  }

  // ─── Internal Activity Logger ───────────────────────────────────────────────

  Future<void> _logActivity({
    required String leadId,
    required String type,
    required String title,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    if (leadId.isEmpty) return;

    try {
      final userName = await _getCurrentUserName();
      final activityData = {
        'type': type,
        'title': title,
        'description': description,
        'createdBy': currentUserId ?? '',
        'createdByName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': metadata,
      };

      // Add to lead's activities
      await _leadActivities(leadId).add(activityData);

      // Add to global activities
      await _globalActivities.add({
        'type': type,
        'description': description,
        'userName': userName,
        'userRole': currentUserRole.displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'entityId': leadId,
        'entityType': 'lead',
        'metadata': metadata,
      });
    } catch (_) {
      // Non-blocking activity logging
    }
  }

  Future<String> _getCurrentUserName() async {
    if (currentUserId == null || currentUserId!.isEmpty) return 'Admin';
    try {
      final doc = await _db.collection(AppCollections.users).doc(currentUserId).get();
      return doc.data()?['displayName'] as String? ?? 'Admin';
    } catch (_) {
      return 'Admin';
    }
  }

  Future<int> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final countSnap = await query.count().get();
      return countSnap.count ?? 0;
    } catch (_) {
      try {
        final snap = await query.get();
        return snap.docs.length;
      } catch (_) {
        return 0;
      }
    }
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final role = ref.watch(currentUserRoleProvider);
  return FollowUpRepository(
    db: FirebaseFirestore.instance,
    currentUserId: authRepo.currentUserId,
    currentUserRole: role,
  );
});

final followUpCountsProvider = FutureProvider<FollowUpCounts>((ref) async {
  return ref.watch(followUpRepositoryProvider).getFollowUpCounts();
});

final todaysFollowUpsStreamProvider =
    StreamProvider<List<FollowUpModel>>((ref) {
  return ref.watch(followUpRepositoryProvider).streamTodaysFollowUps();
});

final overdueFollowUpsStreamProvider =
    StreamProvider<List<FollowUpModel>>((ref) {
  return ref.watch(followUpRepositoryProvider).streamOverdueFollowUps();
});

final upcomingFollowUpsStreamProvider =
    StreamProvider<List<FollowUpModel>>((ref) {
  return ref.watch(followUpRepositoryProvider).streamUpcomingFollowUps();
});

final leadFollowUpsStreamProvider =
    StreamProvider.family<List<FollowUpModel>, String>((ref, leadId) {
  return ref.watch(followUpRepositoryProvider).streamByLead(leadId);
});

final followUpNotesStreamProvider =
    StreamProvider.family<List<FollowUpNoteModel>, String>((ref, followUpId) {
  return ref.watch(followUpRepositoryProvider).streamNotes(followUpId);
});

final followupsStreamProvider = StreamProvider<List<FollowUpModel>>((ref) {
  return ref
      .watch(followUpRepositoryProvider)
      .streamFollowUpsWithFilter(const FollowUpFilter());
});
