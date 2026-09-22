// lib/features/clients/repositories/client_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/client_activity_model.dart';
import '../models/client_filter_model.dart';
import '../models/client_model.dart';
import '../models/client_note_model.dart';

class ClientPaginatedResult {
  final List<ClientModel> clients;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const ClientPaginatedResult({
    required this.clients,
    required this.lastDocument,
    required this.hasMore,
  });
}

class ClientKpiCounts {
  final int total;
  final int active;
  final int newClients;
  final int inactive;
  final int repeat;

  const ClientKpiCounts({
    this.total = 0,
    this.active = 0,
    this.newClients = 0,
    this.inactive = 0,
    this.repeat = 0,
  });
}

class ClientRepository {
  final FirebaseFirestore _db;
  final String? currentUserId;
  final UserRole currentUserRole;

  ClientRepository({
    required FirebaseFirestore db,
    required this.currentUserId,
    required this.currentUserRole,
  }) : _db = db;

  CollectionReference<Map<String, dynamic>> get _clients =>
      _db.collection(AppCollections.clients);

  CollectionReference<Map<String, dynamic>> get _globalActivities =>
      _db.collection(AppCollections.activities);

  CollectionReference<Map<String, dynamic>> _activities(String clientId) =>
      _clients.doc(clientId).collection(AppCollections.clientActivities);

  CollectionReference<Map<String, dynamic>> _notes(String clientId) =>
      _clients.doc(clientId).collection(AppCollections.clientNotes);

  /// Fetch paginated clients using server queries and cursors
  Future<ClientPaginatedResult> getClientsPaginated({
    required ClientFilter filter,
    String? searchQuery,
    DocumentSnapshot? startAfter,
    int limit = 25,
  }) async {
    Query<Map<String, dynamic>> q = _clients;

    // 1. Role scoping
    if (currentUserRole == UserRole.salesStaff && currentUserId != null) {
      q = q.where('assignedTo', isEqualTo: currentUserId);
    }

    // 2. Archival filter
    if (!filter.showArchived) {
      q = q.where('isArchived', isEqualTo: false);
    } else {
      q = q.where('isArchived', isEqualTo: true);
    }

    // 3. Status filter
    if (filter.status != null) {
      q = q.where('status', isEqualTo: filter.status!.name);
    }

    // 4. Priority filter
    if (filter.priority != null) {
      q = q.where('priority', isEqualTo: filter.priority!.name);
    }

    // 5. Client Type filter
    if (filter.clientType != null) {
      q = q.where('clientType', isEqualTo: filter.clientType!.name);
    }

    // 6. Assigned Staff filter
    if (filter.assignedTo != null && filter.assignedTo!.isNotEmpty) {
      q = q.where('assignedTo', isEqualTo: filter.assignedTo);
    }

    // 7. Industry filter
    if (filter.industry != null && filter.industry!.isNotEmpty) {
      q = q.where('industry', isEqualTo: filter.industry);
    }

    // 8. City filter
    if (filter.city != null && filter.city!.isNotEmpty) {
      q = q.where('city', isEqualTo: filter.city);
    }

    // 9. Search tokens filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final cleanQuery = searchQuery.trim().toLowerCase();
      q = q.where('searchTokens', arrayContains: cleanQuery);
    }

    // 10. Date filtering on createdAt using IST boundaries
    if (filter.dateFilter != ClientDateFilter.all) {
      DateTime? startDate;
      DateTime? endDate;

      switch (filter.dateFilter) {
        case ClientDateFilter.today:
          startDate = TimezoneHelper.startOfTodayUtc();
          endDate = TimezoneHelper.endOfTodayUtc();
          break;
        case ClientDateFilter.thisWeek:
          startDate = TimezoneHelper.startOfWeekUtc();
          endDate = TimezoneHelper.endOfWeekUtc();
          break;
        case ClientDateFilter.thisMonth:
          startDate = TimezoneHelper.startOfMonthUtc();
          endDate = TimezoneHelper.endOfMonthUtc();
          break;
        case ClientDateFilter.thisYear:
          final nowIST = TimezoneHelper.nowIST();
          startDate = DateTime.utc(nowIST.year, 1, 1).subtract(const Duration(hours: 5, minutes: 30));
          endDate = DateTime.utc(nowIST.year, 12, 31, 23, 59, 59, 999).subtract(const Duration(hours: 5, minutes: 30));
          break;
        case ClientDateFilter.custom:
          if (filter.customDateRange != null) {
            startDate = filter.customDateRange!.start.toUtc();
            endDate = filter.customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)).toUtc();
          }
          break;
        case ClientDateFilter.all:
          break;
      }

      if (startDate != null) {
        q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        q = q.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
    }

    // 11. Sorting
    switch (filter.sortBy) {
      case ClientSortBy.newest:
        q = q.orderBy('createdAt', descending: true);
        break;
      case ClientSortBy.oldest:
        q = q.orderBy('createdAt', descending: false);
        break;
      case ClientSortBy.nameAsc:
        q = q.orderBy('companyName', descending: false);
        break;
      case ClientSortBy.nameDesc:
        q = q.orderBy('companyName', descending: true);
        break;
      case ClientSortBy.priority:
        q = q.orderBy('priority', descending: true);
        break;
      case ClientSortBy.nextFollowUp:
        q = q.orderBy('nextFollowUpAt', descending: false);
        break;
      case ClientSortBy.recentlyUpdated:
        q = q.orderBy('updatedAt', descending: true);
        break;
    }

    // 12. Cursor pagination
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    // Fetch 1 extra to know if more exist
    final snapshot = await q.limit(limit + 1).get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final resultDocs = hasMore ? docs.sublist(0, limit) : docs;

    final clients = resultDocs.map(ClientModel.fromFirestore).toList();
    final lastDoc = resultDocs.isNotEmpty ? resultDocs.last : null;

    return ClientPaginatedResult(
      clients: clients,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  /// KPI aggregate counts
  Future<ClientKpiCounts> getClientCounts() async {
    try {
      Future<int> safeCount(Query<Map<String, dynamic>> query) async {
        try {
          final agg = await query.count().get();
          return agg.count ?? 0;
        } catch (_) {
          return 0;
        }
      }

      Query<Map<String, dynamic>> base = _clients;
      if (currentUserRole == UserRole.salesStaff && currentUserId != null) {
        base = base.where('assignedTo', isEqualTo: currentUserId);
      }

      final total = await safeCount(base.where('isArchived', isEqualTo: false));
      final active = await safeCount(base
          .where('isArchived', isEqualTo: false)
          .where('status', isEqualTo: ClientStatus.active.name));
      final newClients = await safeCount(base
          .where('isArchived', isEqualTo: false)
          .where('clientType', isEqualTo: ClientType.newClient.name));
      final inactive = await safeCount(base
          .where('isArchived', isEqualTo: false)
          .where('status', isEqualTo: ClientStatus.inactive.name));
      final repeat = await safeCount(base
          .where('isArchived', isEqualTo: false)
          .where('clientType', isEqualTo: ClientType.repeatClient.name));

      return ClientKpiCounts(
        total: total,
        active: active,
        newClients: newClients,
        inactive: inactive,
        repeat: repeat,
      );
    } catch (_) {
      return const ClientKpiCounts();
    }
  }

  /// Duplicate client check before create or conversion
  Future<ClientModel?> checkDuplicateClient({
    String? phone,
    String? email,
    String? companyName,
  }) async {
    try {
      if (phone != null && phone.trim().isNotEmpty) {
        final cleanPhone = phone.trim();
        final snap = await _clients
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return ClientModel.fromFirestore(snap.docs.first);
        }
      }

      if (email != null && email.trim().isNotEmpty) {
        final cleanEmail = email.trim().toLowerCase();
        final snap = await _clients
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return ClientModel.fromFirestore(snap.docs.first);
        }
      }

      if (companyName != null && companyName.trim().isNotEmpty) {
        final cleanName = companyName.trim().toLowerCase();
        final snap = await _clients
            .where('searchTokens', arrayContains: cleanName)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return ClientModel.fromFirestore(snap.docs.first);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get client by ID
  Future<ClientModel?> getClient(String id) async {
    final doc = await _clients.doc(id).get();
    if (!doc.exists) return null;
    return ClientModel.fromFirestore(doc);
  }

  /// Stream single client
  Stream<ClientModel?> streamClientById(String id) {
    return _clients.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClientModel.fromFirestore(doc);
    });
  }

  /// Fetch single client once
  Future<ClientModel?> getClientById(String id) async {
    final doc = await _clients.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ClientModel.fromFirestore(doc);
    }
    return null;
  }

  /// Stream clients list (backward compatibility stream)
  Stream<List<ClientModel>> streamClients({int limit = 100}) {
    Query<Map<String, dynamic>> q = _clients.where('isArchived', isEqualTo: false);
    if (currentUserRole == UserRole.salesStaff && currentUserId != null) {
      q = q.where('assignedTo', isEqualTo: currentUserId);
    }
    return q.limit(limit).snapshots().map((s) {
      final list = s.docs.map(ClientModel.fromFirestore).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  /// Find client by sourceLeadId
  Future<ClientModel?> getClientBySourceLead(String leadId) async {
    final snap = await _clients
        .where('sourceLeadId', isEqualTo: leadId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return ClientModel.fromFirestore(snap.docs.first);
    }
    return null;
  }

  /// Create client manually
  Future<String> createClient(ClientModel client) async {
    final now = DateTime.now();
    final clientToSave = client.copyWith(
      createdAt: now,
      updatedAt: now,
      clientSince: now,
    );

    final docRef = await _clients.add(clientToSave.toMap());
    final clientId = docRef.id;

    // Log in client activities
    await addClientActivity(
      clientId,
      ClientActivityModel(
        id: '',
        type: 'client_created',
        title: 'Client created',
        description: 'Client ${client.companyName} created by ${client.createdByName}',
        createdBy: client.createdBy,
        createdByName: client.createdByName,
        createdAt: now,
      ),
    );

    // Log in global activities
    try {
      await _globalActivities.add({
        'type': ActivityType.clientCreated.name,
        'description': '${client.companyName} created as a new client',
        'userName': client.createdByName,
        'timestamp': Timestamp.fromDate(now),
        'entityId': clientId,
        'entityType': 'client',
        'createdAt': Timestamp.fromDate(now),
      });
    } catch (_) {}

    return clientId;
  }

  /// Update client
  Future<void> updateClient(ClientModel client) async {
    final now = DateTime.now();
    await _clients.doc(client.id).update(client.copyWith(updatedAt: now).toMap());

    await addClientActivity(
      client.id,
      ClientActivityModel(
        id: '',
        type: 'client_updated',
        title: 'Client updated',
        description: 'Updated client profile for ${client.companyName}',
        createdBy: currentUserId ?? '',
        createdByName: 'Admin',
        createdAt: now,
      ),
    );
  }

  /// Update client status
  Future<void> updateClientStatus(
    String clientId,
    ClientStatus status, {
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    await _clients.doc(clientId).update({
      'status': status.name,
      'isArchived': status == ClientStatus.archived,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addClientActivity(
      clientId,
      ClientActivityModel(
        id: '',
        type: 'client_status_changed',
        title: 'Client status changed',
        description: 'Status changed to ${status.displayName}',
        createdBy: userId,
        createdByName: userName,
        createdAt: now,
        metadata: {'newStatus': status.name},
      ),
    );
  }

  /// Archive client
  Future<void> archiveClient(
    String clientId, {
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    await _clients.doc(clientId).update({
      'isArchived': true,
      'status': ClientStatus.archived.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addClientActivity(
      clientId,
      ClientActivityModel(
        id: '',
        type: 'client_archived',
        title: 'Client archived',
        description: 'Client moved to archive',
        createdBy: userId,
        createdByName: userName,
        createdAt: now,
      ),
    );
  }

  /// Restore client from archive
  Future<void> restoreClient(
    String clientId, {
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    await _clients.doc(clientId).update({
      'isArchived': false,
      'status': ClientStatus.active.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addClientActivity(
      clientId,
      ClientActivityModel(
        id: '',
        type: 'client_restored',
        title: 'Client restored',
        description: 'Client restored to active',
        createdBy: userId,
        createdByName: userName,
        createdAt: now,
      ),
    );
  }

  // ─── Subcollection Activities ──────────────────────────────────────────────

  Stream<List<ClientActivityModel>> streamClientActivities(String clientId) {
    return _activities(clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ClientActivityModel.fromFirestore).toList())
        .handleError((_) => <ClientActivityModel>[]);
  }

  Future<void> addClientActivity(
    String clientId,
    ClientActivityModel activity,
  ) async {
    try {
      await _activities(clientId).add(activity.toMap());
    } catch (_) {}
  }

  // ─── Subcollection Notes ───────────────────────────────────────────────────

  Stream<List<ClientNoteModel>> streamClientNotes(String clientId) {
    return _notes(clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ClientNoteModel.fromFirestore).toList())
        .handleError((_) => <ClientNoteModel>[]);
  }

  Future<void> addClientNote(
    String clientId, {
    required String note,
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    await _notes(clientId).add({
      'note': note,
      'createdBy': userId,
      'createdByName': userName,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await addClientActivity(
      clientId,
      ClientActivityModel(
        id: '',
        type: 'client_note_added',
        title: 'Note added',
        description: 'Added an internal note',
        createdBy: userId,
        createdByName: userName,
        createdAt: now,
      ),
    );
  }

  Future<void> deleteClientNote(String clientId, String noteId) async {
    await _notes(clientId).doc(noteId).delete();
  }
}

// ─── Riverpod Providers ──────────────────────────────────────────────────────

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final role = ref.watch(currentUserRoleProvider);
  return ClientRepository(
    db: FirebaseFirestore.instance,
    currentUserId: auth.currentUserId,
    currentUserRole: role,
  );
});

final clientsStreamProvider = StreamProvider<List<ClientModel>>((ref) {
  return ref.watch(clientRepositoryProvider).streamClients();
});

final clientDetailProvider =
    StreamProvider.family<ClientModel?, String>((ref, id) {
  return ref.watch(clientRepositoryProvider).streamClientById(id);
});
