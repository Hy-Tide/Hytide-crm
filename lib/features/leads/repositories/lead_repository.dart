// lib/features/leads/repositories/lead_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/lead_activity_model.dart';
import '../models/lead_filter_model.dart';
import '../models/lead_model.dart';
import '../models/lead_note_model.dart';

class PaginatedLeadsResult {
  final List<LeadModel> leads;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
  final int totalCount;

  const PaginatedLeadsResult({
    required this.leads,
    this.lastDocument,
    required this.hasMore,
    required this.totalCount,
  });
}

class LeadRepository {
  final FirebaseFirestore _db;
  final String? currentUserId;
  final UserRole currentUserRole;

  LeadRepository({
    required FirebaseFirestore db,
    required this.currentUserId,
    required this.currentUserRole,
  }) : _db = db;

  CollectionReference<Map<String, dynamic>> get _leads =>
      _db.collection(AppCollections.leads);
  CollectionReference<Map<String, dynamic>> get _clients =>
      _db.collection(AppCollections.clients);
  CollectionReference<Map<String, dynamic>> get _activities =>
      _db.collection(AppCollections.activities);

  Query<Map<String, dynamic>> _baseQuery() {
    // Sales staff can only view leads assigned to them
    if (currentUserRole == UserRole.salesStaff && currentUserId != null) {
      return _leads.where('assignedTo', isEqualTo: currentUserId);
    }
    return _leads;
  }

  // ─── Total Count Query ──────────────────────────────────────────────────────

  Future<int> getTotalLeadsCount({LeadFilter? filter}) async {
    try {
      Query<Map<String, dynamic>> q = _baseQuery();

      if (filter != null) {
        q = q.where('isArchived', isEqualTo: filter.isArchived);

        if (filter.assignedTo != null) {
          q = q.where('assignedTo', isEqualTo: filter.assignedTo);
        }
        if (filter.statuses.length == 1) {
          q = q.where('status', isEqualTo: filter.statuses.first.name);
        }
        if (filter.priorities.length == 1) {
          q = q.where('priority', isEqualTo: filter.priorities.first.name);
        }
        if (filter.sources.length == 1) {
          q = q.where('source', isEqualTo: filter.sources.first.name);
        }
      } else {
        q = q.where('isArchived', isEqualTo: false);
      }

      final countSnap = await q.count().get();
      return countSnap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Scalable Cursor-Based Pagination ───────────────────────────────────────

  Future<PaginatedLeadsResult> getLeadsPaginated({
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int limit = 25,
    LeadFilter? filter,
    LeadSortOption sort = LeadSortOption.recentlyUpdated,
    String? searchQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _baseQuery();

      // Archive filter
      final isArchived = filter?.isArchived ?? false;
      q = q.where('isArchived', isEqualTo: isArchived);

      // Filtering
      if (filter != null) {
        if (filter.assignedTo != null) {
          q = q.where('assignedTo', isEqualTo: filter.assignedTo);
        }
        if (filter.statuses.length == 1) {
          q = q.where('status', isEqualTo: filter.statuses.first.name);
        } else if (filter.statuses.length > 1) {
          q = q.where('status', whereIn: filter.statuses.map((s) => s.name).toList());
        }

        if (filter.priorities.length == 1) {
          q = q.where('priority', isEqualTo: filter.priorities.first.name);
        } else if (filter.priorities.length > 1) {
          q = q.where('priority', whereIn: filter.priorities.map((p) => p.name).toList());
        }

        if (filter.sources.length == 1) {
          q = q.where('source', isEqualTo: filter.sources.first.name);
        } else if (filter.sources.length > 1) {
          q = q.where('source', whereIn: filter.sources.map((s) => s.name).toList());
        }

        if (filter.createdDateRange != null) {
          q = q
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.createdDateRange!.start))
              .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.createdDateRange!.end));
        }
      }

      // Search via tokens
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryClean = searchQuery.trim().toLowerCase();
        q = q.where('searchTokens', arrayContains: queryClean);
      }

      // Sorting
      q = q.orderBy(sort.field, descending: sort.descending);

      // Cursor pagination
      if (lastDocument != null) {
        q = q.startAfterDocument(lastDocument);
      }

      // Fetch limit + 1 to know if there's a next page
      final snap = await q.limit(limit + 1).get();
      final docs = snap.docs;
      final hasMore = docs.length > limit;
      final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

      final leads = pageDocs.map(LeadModel.fromFirestore).toList();
      final nextLastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;
      final total = await getTotalLeadsCount(filter: filter);

      return PaginatedLeadsResult(
        leads: leads,
        lastDocument: nextLastDoc,
        hasMore: hasMore,
        totalCount: total,
      );
    } catch (_) {
      // Fallback for missing compound indexes
      try {
        Query<Map<String, dynamic>> fallbackQuery = _baseQuery()
            .where('isArchived', isEqualTo: filter?.isArchived ?? false)
            .limit(limit);
        final snap = await fallbackQuery.get();
        final leads = snap.docs.map(LeadModel.fromFirestore).toList();
        return PaginatedLeadsResult(
          leads: leads,
          lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
          hasMore: false,
          totalCount: leads.length,
        );
      } catch (_) {
        return const PaginatedLeadsResult(
          leads: [],
          hasMore: false,
          totalCount: 0,
        );
      }
    }
  }

  // ─── Kanban Stream ──────────────────────────────────────────────────────────

  Stream<List<LeadModel>> streamAllLeadsForKanban({LeadFilter? filter}) {
    Query<Map<String, dynamic>> q = _baseQuery().where('isArchived', isEqualTo: false);

    if (filter != null) {
      if (filter.assignedTo != null) {
        q = q.where('assignedTo', isEqualTo: filter.assignedTo);
      }
      if (filter.priorities.length == 1) {
        q = q.where('priority', isEqualTo: filter.priorities.first.name);
      }
      if (filter.sources.length == 1) {
        q = q.where('source', isEqualTo: filter.sources.first.name);
      }
    }

    return q.limit(200).snapshots().map((snap) {
      return snap.docs.map(LeadModel.fromFirestore).toList();
    });
  }

  // ─── Lead CRUD ──────────────────────────────────────────────────────────────

  Future<LeadModel?> getLeadById(String id) async {
    final doc = await _leads.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return LeadModel.fromFirestore(doc);
  }

  Stream<LeadModel?> streamLeadById(String id) {
    return _leads.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LeadModel.fromFirestore(doc);
    });
  }

  Future<String> createLead(LeadModel lead) async {
    final data = lead.toMap();
    data['createdAt'] = Timestamp.now();
    data['updatedAt'] = Timestamp.now();

    final docRef = await _leads.add(data);
    final leadId = docRef.id;

    // Log initial activity in lead subcollection
    await addLeadActivity(
      leadId,
      LeadActivityModel(
        id: '',
        type: 'lead_created',
        title: 'Lead created',
        description: 'New lead added: ${lead.companyName}',
        createdBy: lead.createdBy,
        createdByName: lead.createdByName,
        createdAt: DateTime.now(),
      ),
    );

    // Also log in global activities for Dashboard timeline
    try {
      await _activities.add({
        'type': ActivityType.leadCreated.name,
        'description': 'Created lead for ${lead.companyName}',
        'userName': lead.createdByName,
        'timestamp': Timestamp.now(),
        'entityId': leadId,
        'entityType': 'lead',
        'createdAt': Timestamp.now(),
      });
    } catch (_) {}

    return leadId;
  }

  Future<void> updateLead(LeadModel lead, {LeadModel? oldLead}) async {
    final data = lead.toMap();
    data['updatedAt'] = Timestamp.now();
    await _leads.doc(lead.id).update(data);

    // Check specific changes for activity logging
    if (oldLead != null) {
      if (oldLead.status != lead.status) {
        await logStatusChange(
          lead.id,
          from: oldLead.status,
          to: lead.status,
          companyName: lead.companyName,
          userName: lead.createdByName,
          userUid: lead.createdBy,
          lostReason: lead.lostReason,
        );
      }
      if (oldLead.priority != lead.priority) {
        await addLeadActivity(
          lead.id,
          LeadActivityModel(
            id: '',
            type: 'priority_changed',
            title: 'Priority changed',
            description: 'Priority changed from ${oldLead.priority.displayName} to ${lead.priority.displayName}',
            createdBy: lead.createdBy,
            createdByName: lead.createdByName,
            createdAt: DateTime.now(),
          ),
        );
      }
      if (oldLead.assignedTo != lead.assignedTo) {
        await addLeadActivity(
          lead.id,
          LeadActivityModel(
            id: '',
            type: 'assignment_changed',
            title: 'Lead assigned',
            description: 'Assigned to ${lead.assignedToName.isNotEmpty ? lead.assignedToName : "Team"}',
            createdBy: lead.createdBy,
            createdByName: lead.createdByName,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> updateLeadStatus(
    String id,
    LeadStatus newStatus, {
    String? lostReason,
    LeadModel? currentLead,
    String? userUid,
    String? userName,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
    };
    if (newStatus == LeadStatus.lost && lostReason != null) {
      updates['lostReason'] = lostReason;
    }

    await _leads.doc(id).update(updates);

    final fromStatus = currentLead?.status ?? LeadStatus.newLead;
    final company = currentLead?.companyName ?? 'Lead';
    final uid = userUid ?? currentUserId ?? '';
    final name = userName ?? 'Admin';

    await logStatusChange(
      id,
      from: fromStatus,
      to: newStatus,
      companyName: company,
      userName: name,
      userUid: uid,
      lostReason: lostReason,
    );
  }

  Future<void> updateLeadPriority(
    String id,
    LeadPriority newPriority, {
    String? userUid,
    String? userName,
  }) async {
    await _leads.doc(id).update({
      'priority': newPriority.name,
      'updatedAt': Timestamp.now(),
    });

    await addLeadActivity(
      id,
      LeadActivityModel(
        id: '',
        type: 'priority_changed',
        title: 'Priority updated',
        description: 'Priority set to ${newPriority.displayName}',
        createdBy: userUid ?? currentUserId ?? '',
        createdByName: userName ?? 'Admin',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> assignLead(
    String id,
    String targetUid,
    String targetName, {
    String? userUid,
    String? userName,
  }) async {
    await _leads.doc(id).update({
      'assignedTo': targetUid,
      'assignedToName': targetName,
      'updatedAt': Timestamp.now(),
    });

    await addLeadActivity(
      id,
      LeadActivityModel(
        id: '',
        type: 'assignment_changed',
        title: 'Lead assigned',
        description: 'Assigned to $targetName',
        createdBy: userUid ?? currentUserId ?? '',
        createdByName: userName ?? 'Admin',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> archiveLead(String id, bool archive, {String? userUid, String? userName}) async {
    await _leads.doc(id).update({
      'isArchived': archive,
      'updatedAt': Timestamp.now(),
    });

    await addLeadActivity(
      id,
      LeadActivityModel(
        id: '',
        type: archive ? 'lead_archived' : 'lead_unarchived',
        title: archive ? 'Lead archived' : 'Lead unarchived',
        description: archive ? 'Lead moved to archive' : 'Lead restored from archive',
        createdBy: userUid ?? currentUserId ?? '',
        createdByName: userName ?? 'Admin',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteLead(String id) async {
    // Clean up subcollections
    try {
      final actSnap = await _leads.doc(id).collection('activities').get();
      for (final doc in actSnap.docs) {
        await doc.reference.delete();
      }
      final notesSnap = await _leads.doc(id).collection('notes').get();
      for (final doc in notesSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    await _leads.doc(id).delete();
  }

  // ─── Duplicate Lead Detection ───────────────────────────────────────────────

  Future<LeadModel?> checkForDuplicate({
    required String phone,
    String? email,
    required String companyName,
  }) async {
    try {
      final phoneClean = phone.replaceAll(RegExp(r'\s+'), '');
      if (phoneClean.isNotEmpty) {
        final snap = await _leads
            .where('phone', isEqualTo: phoneClean)
            .where('isArchived', isEqualTo: false)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return LeadModel.fromFirestore(snap.docs.first);
        }
      }

      if (email != null && email.trim().isNotEmpty) {
        final emailClean = email.trim().toLowerCase();
        final snap = await _leads
            .where('email', isEqualTo: emailClean)
            .where('isArchived', isEqualTo: false)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return LeadModel.fromFirestore(snap.docs.first);
        }
      }

      final companyClean = companyName.trim();
      if (companyClean.isNotEmpty) {
        final snap = await _leads
            .where('companyName', isEqualTo: companyClean)
            .where('isArchived', isEqualTo: false)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return LeadModel.fromFirestore(snap.docs.first);
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── Convert to Client ──────────────────────────────────────────────────────

  Future<String> convertToClient(
    LeadModel lead, {
    String? userUid,
    String? userName,
  }) async {
    // If already converted, return existing clientId
    if (lead.convertedToClient && lead.clientId != null && lead.clientId!.isNotEmpty) {
      return lead.clientId!;
    }

    // 1. Create client document
    final clientData = {
      'companyName': lead.companyName,
      'contactPerson': lead.contactPerson,
      'phone': lead.phone,
      'email': lead.email,
      'address': lead.address,
      'website': lead.website,
      'assignedTo': lead.assignedTo,
      'assignedToName': lead.assignedToName,
      'notes': lead.notes,
      'leadId': lead.id,
      'clientSince': Timestamp.now(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    final clientRef = await _clients.add(clientData);
    final clientId = clientRef.id;

    // 2. Update lead status to won and mark converted
    await _leads.doc(lead.id).update({
      'convertedToClient': true,
      'isConverted': true,
      'clientId': clientId,
      'status': LeadStatus.won.name,
      'updatedAt': Timestamp.now(),
    });

    // 3. Log activity in lead subcollection
    final authorUid = userUid ?? currentUserId ?? '';
    final authorName = userName ?? 'Admin';

    await addLeadActivity(
      lead.id,
      LeadActivityModel(
        id: '',
        type: 'converted_to_client',
        title: 'Lead converted to client',
        description: 'Successfully onboarded ${lead.companyName} as a client',
        createdBy: authorUid,
        createdByName: authorName,
        createdAt: DateTime.now(),
        metadata: {'clientId': clientId},
      ),
    );

    // 4. Log in global activities
    try {
      await _activities.add({
        'type': ActivityType.convertedToClient.name,
        'description': '${lead.companyName} converted to client',
        'userName': authorName,
        'timestamp': Timestamp.now(),
        'entityId': clientId,
        'entityType': 'client',
        'createdAt': Timestamp.now(),
      });
    } catch (_) {}

    return clientId;
  }

  // ─── Subcollection Activities ───────────────────────────────────────────────

  Stream<List<LeadActivityModel>> streamLeadActivities(String leadId) {
    return _leads
        .doc(leadId)
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(LeadActivityModel.fromFirestore).toList())
        .handleError((_) => <LeadActivityModel>[]);
  }

  Future<void> addLeadActivity(String leadId, LeadActivityModel activity) async {
    try {
      await _leads.doc(leadId).collection('activities').add(activity.toMap());
    } catch (_) {}
  }

  Future<void> logStatusChange(
    String leadId, {
    required LeadStatus from,
    required LeadStatus to,
    required String companyName,
    required String userName,
    required String userUid,
    String? lostReason,
  }) async {
    final desc = to == LeadStatus.lost && lostReason != null
        ? 'Moved to Lost: $lostReason'
        : 'Status changed from ${from.displayName} to ${to.displayName}';

    await addLeadActivity(
      leadId,
      LeadActivityModel(
        id: '',
        type: 'status_changed',
        title: 'Status changed',
        description: desc,
        createdBy: userUid,
        createdByName: userName,
        createdAt: DateTime.now(),
        metadata: {
          'from': from.name,
          'to': to.name,
          ...?lostReason != null ? {'lostReason': lostReason} : null,
        },
      ),
    );

    try {
      await _activities.add({
        'type': ActivityType.statusChanged.name,
        'description': '$companyName moved to ${to.displayName}',
        'userName': userName,
        'timestamp': Timestamp.now(),
        'entityId': leadId,
        'entityType': 'lead',
        'createdAt': Timestamp.now(),
      });
    } catch (_) {}
  }

  // ─── Subcollection Notes ────────────────────────────────────────────────────

  Stream<List<LeadNoteModel>> streamLeadNotes(String leadId) {
    return _leads
        .doc(leadId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LeadNoteModel.fromFirestore).toList())
        .handleError((_) => <LeadNoteModel>[]);
  }

  Future<String> addLeadNote(
    String leadId, {
    required String content,
    required String authorUid,
    required String authorName,
  }) async {
    final note = LeadNoteModel(
      id: '',
      content: content.trim(),
      createdBy: authorUid,
      createdByName: authorName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _leads.doc(leadId).collection('notes').add(note.toMap());

    // Also log an activity
    await addLeadActivity(
      leadId,
      LeadActivityModel(
        id: '',
        type: 'note_added',
        title: 'Note added',
        description: content.length > 80 ? '${content.substring(0, 80)}...' : content,
        createdBy: authorUid,
        createdByName: authorName,
        createdAt: DateTime.now(),
      ),
    );

    return docRef.id;
  }

  Future<void> deleteLeadNote(String leadId, String noteId) async {
    await _leads.doc(leadId).collection('notes').doc(noteId).delete();
  }

  Future<void> toggleArchiveLead(String id, bool archive, {String? userUid, String? userName}) =>
      archiveLead(id, archive, userUid: userUid, userName: userName);
}

// ─── Repository Providers ─────────────────────────────────────────────────────

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final role = ref.watch(currentUserRoleProvider);
  return LeadRepository(
    db: FirebaseFirestore.instance,
    currentUserId: authRepo.currentUserId,
    currentUserRole: role,
  );
});

final leadsStreamProvider = StreamProvider<List<LeadModel>>((ref) {
  return ref.watch(leadRepositoryProvider).streamAllLeadsForKanban();
});
