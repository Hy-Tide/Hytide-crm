// lib/features/dashboard/repositories/dashboard_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/models/client_model.dart';
import '../../followups/models/followup_model.dart';
import '../../projects/models/project_model.dart';
import '../models/activity_model.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  final FirebaseFirestore _db;
  final String? currentUserId;
  final UserRole currentUserRole;

  DashboardRepository({
    required FirebaseFirestore db,
    required this.currentUserId,
    required this.currentUserRole,
  }) : _db = db;

  CollectionReference<Map<String, dynamic>> get _leads =>
      _db.collection(AppCollections.leads);
  CollectionReference<Map<String, dynamic>> get _followups =>
      _db.collection(AppCollections.followups);
  CollectionReference<Map<String, dynamic>> get _clients =>
      _db.collection(AppCollections.clients);
  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection(AppCollections.projects);
  CollectionReference<Map<String, dynamic>> get _quotations =>
      _db.collection(AppCollections.quotations);
  CollectionReference<Map<String, dynamic>> get _activities =>
      _db.collection(AppCollections.activities);

  // ─── Scalable KPI Aggregations ──────────────────────────────────────────────

  Future<DashboardKpiData> getKpiData(DateRangeValue range) async {
    try {
      // 1. Total Leads (All-time total)
      final totalLeadsCount = await _safeCount(_leads);

      // 2. New Leads in period
      final newLeadsCount = await _safeCount(
        _leads
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end)),
      );

      // 3. New Leads in previous period (for growth % comparison)
      final prevNewLeadsCount = await _safeCount(
        _leads
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.previousStart))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.previousEnd)),
      );

      // 4. Follow-ups stats (Today & Overdue in Asia/Kolkata timezone)
      final now = DateTime.now();
      final startOfToday = TimezoneHelper.startOfTodayUtc();
      final endOfToday = TimezoneHelper.endOfTodayUtc();

      final todaysFollowupsCount = await _safeCount(
        _followups
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday)),
      );

      final overdueFollowupsCount = await _safeCount(
        _followups
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isLessThan: Timestamp.fromDate(now)),
      );

      // 5. Active Clients
      final activeClientsCount = await _safeCount(
        _clients
            .where('isArchived', isEqualTo: false)
            .where('status', isEqualTo: ClientStatus.active.name),
      );

      // 6. Active Projects (planning, inProgress, onHold)
      final activeProjectsCount = await _safeCount(
        _projects.where('status', whereIn: [
          ProjectStatus.planning.name,
          ProjectStatus.active.name,
          ProjectStatus.onHold.name,
        ]),
      );

      // 7. Pending Quotations (draft, sent, viewed)
      final pendingQuotationsCount = await _safeCount(
        _quotations.where('status', whereIn: [
          QuotationStatus.draft.name,
          QuotationStatus.sent.name,
          QuotationStatus.viewed.name,
        ]),
      );

      // 8. Won Leads
      final wonLeadsCount = await _safeCount(
        _leads.where('status', isEqualTo: LeadStatus.won.name),
      );

      return DashboardKpiData(
        totalLeads: totalLeadsCount,
        newLeads: newLeadsCount,
        newLeadsPreviousPeriod: prevNewLeadsCount,
        todaysFollowups: todaysFollowupsCount,
        overdueFollowups: overdueFollowupsCount,
        activeClients: activeClientsCount,
        activeProjects: activeProjectsCount,
        pendingQuotations: pendingQuotationsCount,
        wonLeads: wonLeadsCount,
      );
    } catch (_) {
      return const DashboardKpiData();
    }
  }

  // ─── Lead Pipeline ──────────────────────────────────────────────────────────

  Future<List<LeadPipelineItem>> getLeadPipeline(DateRangeValue range) async {
    try {
      int total = 0;
      final counts = <LeadStatus, int>{};

      for (final status in LeadStatus.values) {
        final count = await _safeCount(
          _leads.where('status', isEqualTo: status.name),
        );
        counts[status] = count;
        total += count;
      }

      return LeadStatus.values.map((status) {
        final count = counts[status] ?? 0;
        final pct = total > 0 ? double.parse(((count / total) * 100).toStringAsFixed(1)) : 0.0;
        return LeadPipelineItem(
          status: status,
          count: count,
          percentage: pct,
        );
      }).toList();
    } catch (_) {
      return LeadStatus.values
          .map((s) => LeadPipelineItem(status: s, count: 0, percentage: 0.0))
          .toList();
    }
  }

  // ─── Conversion Overview ────────────────────────────────────────────────────

  Future<ConversionStats> getConversionStats(DateRangeValue range) async {
    try {
      final total = await _safeCount(_leads);
      final won = await _safeCount(_leads.where('status', isEqualTo: LeadStatus.won.name));
      final lost = await _safeCount(_leads.where('status', isEqualTo: LeadStatus.lost.name));

      return ConversionStats.compute(
        totalLeads: total,
        wonLeads: won,
        lostLeads: lost,
      );
    } catch (_) {
      return const ConversionStats();
    }
  }

  // ─── Lead Sources Analytics ─────────────────────────────────────────────────

  Future<List<LeadSourceStats>> getLeadSources(DateRangeValue range) async {
    try {
      int total = 0;
      final counts = <LeadSource, int>{};

      for (final source in LeadSource.values) {
        final count = await _safeCount(
          _leads.where('source', isEqualTo: source.name),
        );
        counts[source] = count;
        total += count;
      }

      return LeadSource.values.map((source) {
        final count = counts[source] ?? 0;
        final pct = total > 0 ? double.parse(((count / total) * 100).toStringAsFixed(1)) : 0.0;
        return LeadSourceStats(
          source: source,
          count: count,
          percentage: pct,
        );
      }).toList();
    } catch (_) {
      return LeadSource.values
          .map((s) => LeadSourceStats(source: s, count: 0, percentage: 0.0))
          .toList();
    }
  }

  // ─── Follow-up Summary ──────────────────────────────────────────────────────

  Future<FollowUpSummary> getFollowUpSummary() async {
    try {
      final now = DateTime.now();
      final startOfToday = TimezoneHelper.startOfTodayUtc();
      final endOfToday = TimezoneHelper.endOfTodayUtc();

      final today = await _safeCount(
        _followups
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday)),
      );

      final upcoming = await _safeCount(
        _followups
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isGreaterThan: Timestamp.fromDate(endOfToday)),
      );

      final overdue = await _safeCount(
        _followups
            .where('status', isEqualTo: FollowUpStatus.pending.name)
            .where('scheduledAt', isLessThan: Timestamp.fromDate(now)),
      );

      final completed = await _safeCount(
        _followups.where('status', isEqualTo: FollowUpStatus.completed.name),
      );

      return FollowUpSummary(
        todayCount: today,
        upcomingCount: upcoming,
        overdueCount: overdue,
        completedCount: completed,
      );
    } catch (_) {
      return const FollowUpSummary();
    }
  }

  // ─── Today's Follow-ups Stream ──────────────────────────────────────────────

  Stream<List<FollowUpModel>> streamTodaysFollowUps() {
    final startOfToday = TimezoneHelper.startOfTodayUtc();
    final endOfToday = TimezoneHelper.endOfTodayUtc();

    return _followups
        .where('status', isEqualTo: FollowUpStatus.pending.name)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
        .snapshots()
        .map((snap) {
          final items = snap.docs.map(FollowUpModel.fromFirestore).toList();
          items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          return items;
        })
        .handleError((_) => <FollowUpModel>[]);
  }

  // ─── Overdue Follow-ups Stream ──────────────────────────────────────────────

  Stream<List<FollowUpModel>> streamOverdueFollowUps() {
    final now = DateTime.now();

    return _followups
        .where('status', isEqualTo: FollowUpStatus.pending.name)
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduledAt', descending: false)
        .limit(10)
        .snapshots()
        .map((snap) {
          return snap.docs.map(FollowUpModel.fromFirestore).toList();
        })
        .handleError((_) => <FollowUpModel>[]);
  }

  // ─── Recent Activities Stream ───────────────────────────────────────────────

  Stream<List<ActivityModel>> streamRecentActivities({int limit = 10}) {
    return _activities
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityModel.fromFirestore).toList())
        .handleError((_) => <ActivityModel>[]);
  }

  // ─── Active Clients ─────────────────────────────────────────────────────────

  Future<List<ClientModel>> getActiveClients({int limit = 5}) async {
    try {
      final snap = await _clients
          .where('isArchived', isEqualTo: false)
          .where('status', isEqualTo: ClientStatus.active.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(ClientModel.fromFirestore).toList();
    } catch (_) {
      try {
        final snap = await _clients
            .where('isArchived', isEqualTo: false)
            .limit(limit)
            .get();
        return snap.docs.map(ClientModel.fromFirestore).toList();
      } catch (_) {
        return <ClientModel>[];
      }
    }
  }

  // ─── Active Projects ────────────────────────────────────────────────────────

  Future<List<ProjectModel>> getActiveProjects({int limit = 5}) async {
    try {
      final snap = await _projects
          .where('status', whereIn: [
            ProjectStatus.planning.name,
            ProjectStatus.active.name,
            ProjectStatus.onHold.name,
          ])
          .limit(limit)
          .get();
      return snap.docs.map(ProjectModel.fromFirestore).toList();
    } catch (_) {
      return <ProjectModel>[];
    }
  }

  // ─── Quotations Summary ─────────────────────────────────────────────────────

  Future<QuotationSummary> getQuotationSummary() async {
    try {
      final draft = await _safeCount(_quotations.where('status', isEqualTo: QuotationStatus.draft.name));
      final sent = await _safeCount(_quotations.where('status', isEqualTo: QuotationStatus.sent.name));
      final viewed = await _safeCount(_quotations.where('status', isEqualTo: QuotationStatus.viewed.name));
      final accepted = await _safeCount(_quotations.where('status', isEqualTo: QuotationStatus.accepted.name));
      final rejected = await _safeCount(_quotations.where('status', isEqualTo: QuotationStatus.rejected.name));
      final expired = await _safeCount(_quotations.where('status', isEqualTo: QuotationStatus.expired.name));

      return QuotationSummary.fromCounts(
        draft: draft,
        sent: sent,
        viewed: viewed,
        accepted: accepted,
        rejected: rejected,
        expired: expired,
      );
    } catch (_) {
      return const QuotationSummary();
    }
  }

  // ─── Dashboard Interactive Actions ──────────────────────────────────────────

  Future<void> markFollowUpComplete(String id, String leadName) async {
    await _followups.doc(id).update({
      'status': FollowUpStatus.completed.name,
      'updatedAt': Timestamp.now(),
    });

    // Record activity
    await logActivity(
      type: ActivityType.followUpCompleted,
      description: 'Completed follow-up for $leadName',
      entityId: id,
      entityType: 'followup',
    );
  }

  Future<void> rescheduleFollowUp(
    String id,
    DateTime newDate,
    TimeOfDay newTime,
    String leadName,
  ) async {
    final scheduledAt = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );

    await _followups.doc(id).update({
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'date': Timestamp.fromDate(scheduledAt),
      'timeHour': newTime.hour,
      'timeMinute': newTime.minute,
      'status': FollowUpStatus.pending.name,
      'reminderSent': false,
      'updatedAt': Timestamp.now(),
    });

    // Record activity
    await logActivity(
      type: ActivityType.followUpCreated,
      description: 'Rescheduled follow-up for $leadName',
      entityId: id,
      entityType: 'followup',
    );
  }

  Future<void> logActivity({
    required ActivityType type,
    required String description,
    String? entityId,
    String? entityType,
  }) async {
    try {
      final userDoc = currentUserId != null
          ? await _db.collection(AppCollections.users).doc(currentUserId).get()
          : null;
      final userName = userDoc?.data()?['displayName'] as String? ?? 'Admin';
      final userRole = userDoc?.data()?['role'] as String? ?? 'Admin';

      final activity = ActivityModel(
        id: '',
        type: type,
        description: description,
        userName: userName,
        userRole: userRole,
        timestamp: DateTime.now(),
        entityId: entityId,
        entityType: entityType,
      );

      await _activities.add(activity.toMap());
    } catch (_) {
      // Non-blocking activity logging
    }
  }

  // ─── Safe Aggregate Count Helper ────────────────────────────────────────────

  Future<int> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final aggregate = await query.count().get();
      return aggregate.count ?? 0;
    } catch (_) {
      // Fallback in case count() is unavailable or rule prevents aggregate
      try {
        final snap = await query.get();
        return snap.docs.length;
      } catch (_) {
        return 0;
      }
    }
  }
}

// ─── Repository Provider ──────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final role = ref.watch(currentUserRoleProvider);
  return DashboardRepository(
    db: FirebaseFirestore.instance,
    currentUserId: auth.currentUserId,
    currentUserRole: role,
  );
});
