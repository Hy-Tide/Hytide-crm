// lib/features/quotations/repositories/quotation_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/models/client_activity_model.dart';
import '../../clients/repositories/client_repository.dart';
import '../models/quotation_activity_model.dart';
import '../models/quotation_filter_model.dart';
import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';
import '../models/quotation_note_model.dart';
import '../services/quotation_calculation_service.dart';
import '../services/quotation_number_service.dart';

class QuotationPaginatedResult {
  final List<QuotationModel> quotations;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const QuotationPaginatedResult({
    required this.quotations,
    this.lastDocument,
    required this.hasMore,
  });
}

class QuotationKpiCounts {
  final int total;
  final int draft;
  final int sent;
  final int viewed;
  final int accepted;
  final int rejected;
  final int expired;

  const QuotationKpiCounts({
    this.total = 0,
    this.draft = 0,
    this.sent = 0,
    this.viewed = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.expired = 0,
  });

  int get pending => draft + sent + viewed;
}

class QuotationRepository {
  final FirebaseFirestore _db;
  final QuotationNumberService _numberService;
  final QuotationCalculationService _calcService;
  final ClientRepository? _clientRepo;
  final String? currentUserId;
  final String currentUserName;

  QuotationRepository({
    required FirebaseFirestore db,
    QuotationNumberService? numberService,
    QuotationCalculationService? calcService,
    ClientRepository? clientRepo,
    this.currentUserId,
    this.currentUserName = 'Admin',
  })  : _db = db,
        _numberService = numberService ?? QuotationNumberService(db: db),
        _calcService = calcService ?? const QuotationCalculationService(),
        _clientRepo = clientRepo;

  CollectionReference<Map<String, dynamic>> get _quotations =>
      _db.collection(AppCollections.quotations);

  CollectionReference<Map<String, dynamic>> _items(String quotationId) =>
      _quotations.doc(quotationId).collection(AppCollections.quotationItems);

  CollectionReference<Map<String, dynamic>> _activities(String quotationId) =>
      _quotations.doc(quotationId).collection(AppCollections.quotationActivities);

  CollectionReference<Map<String, dynamic>> _notes(String quotationId) =>
      _quotations.doc(quotationId).collection(AppCollections.quotationNotes);

  // ─── Quotation Queries & Pagination ────────────────────────────────────────

  Future<QuotationPaginatedResult> getQuotationsPaginated({
    required QuotationFilter filter,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _quotations;

    // Search or Filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = searchQuery.trim().toLowerCase();
      query = query
          .where('isArchived', isEqualTo: filter.isArchived)
          .where('searchTokens', arrayContains: term)
          .orderBy('createdAt', descending: true);
    } else {
      query = query.where('isArchived', isEqualTo: filter.isArchived);

      if (filter.status != null) {
        query = query.where('status', isEqualTo: filter.status!.name);
      }

      if (filter.clientId != null && filter.clientId!.isNotEmpty) {
        query = query.where('clientId', isEqualTo: filter.clientId);
      }

      if (filter.assignedTo != null && filter.assignedTo!.isNotEmpty) {
        query = query.where('assignedTo', isEqualTo: filter.assignedTo);
      }

      // Date Filters using strict IST midnight boundaries
      if (filter.dateFilter != QuotationDateFilter.all) {
        DateTime? start;
        DateTime? end;
        final now = TimezoneHelper.now();

        switch (filter.dateFilter) {
          case QuotationDateFilter.today:
            start = TimezoneHelper.startOfTodayUtc();
            end = TimezoneHelper.endOfTodayUtc();
            break;
          case QuotationDateFilter.thisWeek:
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            start = TimezoneHelper.startOfDayUtc(startOfWeek);
            end = TimezoneHelper.endOfDayUtc(endOfWeek);
            break;
          case QuotationDateFilter.thisMonth:
            start = TimezoneHelper.startOfMonthUtc();
            end = TimezoneHelper.endOfMonthUtc();
            break;
          case QuotationDateFilter.thisYear:
            start = TimezoneHelper.startOfDayUtc(DateTime(now.year, 1, 1));
            end = TimezoneHelper.endOfDayUtc(DateTime(now.year, 12, 31));
            break;
          case QuotationDateFilter.custom:
            if (filter.customStartDate != null) {
              start = TimezoneHelper.startOfDayUtc(filter.customStartDate!);
            }
            if (filter.customEndDate != null) {
              end = TimezoneHelper.endOfDayUtc(filter.customEndDate!);
            }
            break;
          default:
            break;
        }

        if (start != null) {
          query = query.where('issueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
        }
        if (end != null) {
          query = query.where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(end));
        }
      }

      // Sorting
      switch (filter.sortBy) {
        case QuotationSortBy.oldest:
          query = query.orderBy('createdAt', descending: false);
          break;
        case QuotationSortBy.quotationNumber:
          query = query.orderBy('quotationNumber', descending: false);
          break;
        case QuotationSortBy.amountHighToLow:
          query = query.orderBy('grandTotal', descending: true);
          break;
        case QuotationSortBy.amountLowToHigh:
          query = query.orderBy('grandTotal', descending: false);
          break;
        case QuotationSortBy.expirySoonest:
          query = query.orderBy('expiryDate', descending: false);
          break;
        case QuotationSortBy.recentlyUpdated:
          query = query.orderBy('updatedAt', descending: true);
          break;
        case QuotationSortBy.newest:
          query = query.orderBy('createdAt', descending: true);
          break;
      }
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit + 1);

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final results = (hasMore ? docs.sublist(0, limit) : docs)
        .map(QuotationModel.fromFirestore)
        .toList();

    return QuotationPaginatedResult(
      quotations: results,
      lastDocument: results.isNotEmpty && docs.isNotEmpty
          ? docs[results.length - 1]
          : null,
      hasMore: hasMore,
    );
  }

  /// Efficient Server Aggregate Counts for KPI Cards
  Future<QuotationKpiCounts> getQuotationKpiCounts() async {
    try {
      final base = _quotations.where('isArchived', isEqualTo: false);

      final totalFuture = base.count().get();
      final draftFuture = base.where('status', isEqualTo: QuotationStatus.draft.name).count().get();
      final sentFuture = base.where('status', isEqualTo: QuotationStatus.sent.name).count().get();
      final viewedFuture = base.where('status', isEqualTo: QuotationStatus.viewed.name).count().get();
      final acceptedFuture = base.where('status', isEqualTo: QuotationStatus.accepted.name).count().get();
      final rejectedFuture = base.where('status', isEqualTo: QuotationStatus.rejected.name).count().get();
      final expiredFuture = base.where('status', isEqualTo: QuotationStatus.expired.name).count().get();

      final results = await Future.wait([
        totalFuture,
        draftFuture,
        sentFuture,
        viewedFuture,
        acceptedFuture,
        rejectedFuture,
        expiredFuture,
      ]);

      return QuotationKpiCounts(
        total: results[0].count ?? 0,
        draft: results[1].count ?? 0,
        sent: results[2].count ?? 0,
        viewed: results[3].count ?? 0,
        accepted: results[4].count ?? 0,
        rejected: results[5].count ?? 0,
        expired: results[6].count ?? 0,
      );
    } catch (_) {
      return const QuotationKpiCounts();
    }
  }

  Stream<QuotationModel?> streamById(String id) {
    return _quotations.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return QuotationModel.fromFirestore(doc);
    });
  }

  Future<QuotationModel?> getQuotationById(String id) async {
    final doc = await _quotations.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return QuotationModel.fromFirestore(doc);
  }

  Stream<List<QuotationModel>> streamQuotationsByClient(String clientId) {
    return _quotations
        .where('clientId', isEqualTo: clientId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(QuotationModel.fromFirestore).toList());
  }

  // ─── Quotation Lifecycle (Create, Update, Duplicate, Revision) ──────────────

  Future<String> createQuotation({
    required QuotationModel quotation,
    required List<QuotationItemModel> items,
  }) async {
    final now = DateTime.now();

    // 1. Generate atomic sequential number if missing
    String number = quotation.quotationNumber;
    if (number.trim().isEmpty) {
      number = await _numberService.generateNextQuotationNumber();
    }

    // 2. Compute exact totals
    final totals = _calcService.calculateQuotationTotals(
      items: items,
      discountType: quotation.discountType,
      discountValue: quotation.discountValue,
      taxType: quotation.taxType,
      quotationTaxPercentage: quotation.taxPercentage,
      shippingAmount: quotation.shippingAmount,
      otherCharges: quotation.otherCharges,
    );

    final docRef = _quotations.doc();
    final newId = docRef.id;

    final preparedItems = items.asMap().entries.map((e) {
      final index = e.key;
      final item = e.value;
      final itemId = item.id.isNotEmpty ? item.id : _items(newId).doc().id;
      return item.copyWith(id: itemId, sortOrder: index);
    }).toList();

    final preparedQuotation = quotation.copyWith(
      id: newId,
      quotationNumber: number,
      items: preparedItems,
      subtotal: totals.subtotal,
      discountAmount: totals.discountAmount,
      taxAmount: totals.taxAmount,
      grandTotal: totals.grandTotal,
      createdAt: now,
      updatedAt: now,
      searchTokens: quotation.buildSearchTokens(),
    );

    // 3. Batch write Document + Items Subcollection
    final batch = _db.batch();
    batch.set(docRef, preparedQuotation.toMap());

    for (final item in preparedItems) {
      final itemRef = _items(newId).doc(item.id);
      batch.set(itemRef, item.toMap());
    }

    await batch.commit();

    // 4. Log Activities
    await addQuotationActivity(
      newId,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationCreated.name,
        title: 'Quotation created',
        description: 'Quotation $number created as Draft with total ${quotation.currency} ${totals.grandTotal.toStringAsFixed(2)}',
        createdBy: currentUserId ?? quotation.createdBy,
        createdByName: currentUserName.isNotEmpty ? currentUserName : quotation.createdByName,
        createdAt: now,
      ),
    );

    if (quotation.clientId.isNotEmpty && _clientRepo != null) {
      await _clientRepo.addClientActivity(
        quotation.clientId,
        ClientActivityModel(
          id: '',
          type: ActivityType.quotationCreated.name,
          title: 'Quotation created',
          description: 'Quotation $number created (${quotation.currency} ${totals.grandTotal.toStringAsFixed(2)})',
          createdBy: currentUserId ?? quotation.createdBy,
          createdByName: currentUserName.isNotEmpty ? currentUserName : quotation.createdByName,
          createdAt: now,
          metadata: {'quotationId': newId, 'quotationNumber': number},
        ),
      );
    }

    return newId;
  }

  Future<void> updateQuotation({
    required QuotationModel quotation,
    required List<QuotationItemModel> items,
  }) async {
    final now = DateTime.now();

    final totals = _calcService.calculateQuotationTotals(
      items: items,
      discountType: quotation.discountType,
      discountValue: quotation.discountValue,
      taxType: quotation.taxType,
      quotationTaxPercentage: quotation.taxPercentage,
      shippingAmount: quotation.shippingAmount,
      otherCharges: quotation.otherCharges,
    );

    final preparedItems = items.asMap().entries.map((e) {
      final index = e.key;
      final item = e.value;
      final itemId = item.id.isNotEmpty ? item.id : _items(quotation.id).doc().id;
      return item.copyWith(id: itemId, sortOrder: index);
    }).toList();

    final updatedQuotation = quotation.copyWith(
      items: preparedItems,
      subtotal: totals.subtotal,
      discountAmount: totals.discountAmount,
      taxAmount: totals.taxAmount,
      grandTotal: totals.grandTotal,
      updatedAt: now,
      searchTokens: quotation.buildSearchTokens(),
    );

    final batch = _db.batch();
    batch.update(_quotations.doc(quotation.id), updatedQuotation.toMap());

    // Replace items subcollection cleanly
    for (final item in preparedItems) {
      batch.set(_items(quotation.id).doc(item.id), item.toMap(), SetOptions(merge: true));
    }

    await batch.commit();

    await addQuotationActivity(
      quotation.id,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationUpdated.name,
        title: 'Quotation updated',
        description: 'Quotation details and items updated (Total: ${quotation.currency} ${totals.grandTotal.toStringAsFixed(2)})',
        createdBy: currentUserId ?? quotation.createdBy,
        createdByName: currentUserName.isNotEmpty ? currentUserName : quotation.createdByName,
        createdAt: now,
      ),
    );
  }

  Future<String> duplicateQuotation(String sourceId) async {
    final original = await getQuotationById(sourceId);
    if (original == null) throw Exception('Quotation not found');

    final newNumber = await _numberService.generateNextQuotationNumber();
    final now = DateTime.now();

    final duplicated = original.copyWith(
      id: '',
      quotationNumber: newNumber,
      revisionNumber: 1,
      parentQuotationId: null,
      status: QuotationStatus.draft,
      createdAt: now,
      updatedAt: now,
      sentAt: null,
      viewedAt: null,
      acceptedAt: null,
      rejectedAt: null,
      rejectionReason: null,
      convertedToProject: false,
      projectId: null,
      pdfUrl: null,
      pdfStoragePath: null,
      pdfGeneratedAt: null,
      pdfVersion: 1,
    );

    return await createQuotation(quotation: duplicated, items: original.items);
  }

  Future<String> createRevision(String parentId) async {
    final parent = await getQuotationById(parentId);
    if (parent == null) throw Exception('Parent quotation not found');

    final nextRevision = parent.revisionNumber + 1;
    final revisionNumber = QuotationNumberService.formatRevisionNumber(
      parent.quotationNumber,
      nextRevision,
    );
    final now = DateTime.now();

    final revised = parent.copyWith(
      id: '',
      quotationNumber: revisionNumber,
      revisionNumber: nextRevision,
      parentQuotationId: parentId,
      status: QuotationStatus.draft,
      createdAt: now,
      updatedAt: now,
      sentAt: null,
      viewedAt: null,
      acceptedAt: null,
      rejectedAt: null,
      rejectionReason: null,
      convertedToProject: false,
      projectId: null,
      pdfUrl: null,
      pdfStoragePath: null,
      pdfGeneratedAt: null,
      pdfVersion: 1,
    );

    final newId = await createQuotation(quotation: revised, items: parent.items);

    await addQuotationActivity(
      parentId,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationRevised.name,
        title: 'Revision created',
        description: 'New revision $revisionNumber initiated',
        createdBy: currentUserId ?? parent.createdBy,
        createdByName: currentUserName,
        createdAt: now,
        metadata: {'newQuotationId': newId, 'revisionNumber': revisionNumber},
      ),
    );

    return newId;
  }

  // ─── Status Transitions ───────────────────────────────────────────────────

  Future<void> markAsSent(String id) async {
    final now = DateTime.now();
    await _quotations.doc(id).update({
      'status': QuotationStatus.sent.name,
      'sentAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    final q = await getQuotationById(id);
    if (q != null) {
      await addQuotationActivity(
        id,
        QuotationActivityModel(
          id: '',
          type: ActivityType.quotationSent.name,
          title: 'Quotation sent',
          description: 'Quotation ${q.quotationNumber} sent to client',
          createdBy: currentUserId ?? q.createdBy,
          createdByName: currentUserName,
          createdAt: now,
        ),
      );

      if (q.clientId.isNotEmpty && _clientRepo != null) {
        await _clientRepo.addClientActivity(
          q.clientId,
          ClientActivityModel(
            id: '',
            type: ActivityType.quotationSent.name,
            title: 'Quotation sent',
            description: 'Quotation ${q.quotationNumber} sent (${q.currency} ${q.grandTotal.toStringAsFixed(2)})',
            createdBy: currentUserId ?? q.createdBy,
            createdByName: currentUserName,
            createdAt: now,
            metadata: {'quotationId': id, 'quotationNumber': q.quotationNumber},
          ),
        );
      }
    }
  }

  Future<void> markAsViewed(String id) async {
    final now = DateTime.now();
    await _quotations.doc(id).update({
      'status': QuotationStatus.viewed.name,
      'viewedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await addQuotationActivity(
      id,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationViewed.name,
        title: 'Quotation viewed',
        description: 'Customer opened quotation view',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );
  }

  Future<void> markAsAccepted(String id) async {
    final now = DateTime.now();
    await _quotations.doc(id).update({
      'status': QuotationStatus.accepted.name,
      'acceptedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    final q = await getQuotationById(id);
    if (q != null) {
      await addQuotationActivity(
        id,
        QuotationActivityModel(
          id: '',
          type: ActivityType.quotationAccepted.name,
          title: 'Quotation accepted',
          description: 'Quotation ${q.quotationNumber} accepted by client',
          createdBy: currentUserId ?? q.createdBy,
          createdByName: currentUserName,
          createdAt: now,
        ),
      );

      if (q.clientId.isNotEmpty && _clientRepo != null) {
        await _clientRepo.addClientActivity(
          q.clientId,
          ClientActivityModel(
            id: '',
            type: ActivityType.quotationAccepted.name,
            title: 'Quotation accepted',
            description: 'Quotation ${q.quotationNumber} was accepted (${q.currency} ${q.grandTotal.toStringAsFixed(2)})',
            createdBy: currentUserId ?? q.createdBy,
            createdByName: currentUserName,
            createdAt: now,
            metadata: {'quotationId': id, 'quotationNumber': q.quotationNumber},
          ),
        );
      }
    }
  }

  Future<void> markAsRejected(String id, {required String reason}) async {
    final now = DateTime.now();
    await _quotations.doc(id).update({
      'status': QuotationStatus.rejected.name,
      'rejectedAt': Timestamp.fromDate(now),
      'rejectionReason': reason.trim(),
      'updatedAt': Timestamp.fromDate(now),
    });

    final q = await getQuotationById(id);
    if (q != null) {
      await addQuotationActivity(
        id,
        QuotationActivityModel(
          id: '',
          type: ActivityType.quotationRejected.name,
          title: 'Quotation rejected',
          description: 'Quotation rejected. Reason: $reason',
          createdBy: currentUserId ?? q.createdBy,
          createdByName: currentUserName,
          createdAt: now,
          metadata: {'rejectionReason': reason},
        ),
      );

      if (q.clientId.isNotEmpty && _clientRepo != null) {
        await _clientRepo.addClientActivity(
          q.clientId,
          ClientActivityModel(
            id: '',
            type: ActivityType.quotationRejected.name,
            title: 'Quotation rejected',
            description: 'Quotation ${q.quotationNumber} was rejected: $reason',
            createdBy: currentUserId ?? q.createdBy,
            createdByName: currentUserName,
            createdAt: now,
            metadata: {'quotationId': id, 'reason': reason},
          ),
        );
      }
    }
  }

  Future<void> archiveQuotation(String id) async {
    final now = DateTime.now();
    await _quotations.doc(id).update({
      'isArchived': true,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addQuotationActivity(
      id,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationArchived.name,
        title: 'Quotation archived',
        description: 'Quotation archived by admin',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );
  }

  Future<void> restoreQuotation(String id) async {
    final now = DateTime.now();
    await _quotations.doc(id).update({
      'isArchived': false,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addQuotationActivity(
      id,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationRestored.name,
        title: 'Quotation restored',
        description: 'Quotation restored to active list',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );
  }

  // ─── Subcollection Operations ─────────────────────────────────────────────

  Stream<List<QuotationItemModel>> streamQuotationItems(String quotationId) {
    return _items(quotationId)
        .orderBy('sortOrder', descending: false)
        .snapshots()
        .map((s) => s.docs.map(QuotationItemModel.fromFirestore).toList());
  }

  Stream<List<QuotationActivityModel>> streamQuotationActivities(String quotationId) {
    return _activities(quotationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(QuotationActivityModel.fromFirestore).toList());
  }

  Future<void> addQuotationActivity(
    String quotationId,
    QuotationActivityModel activity,
  ) async {
    await _activities(quotationId).add(activity.toMap());
  }

  Stream<List<QuotationNoteModel>> streamQuotationNotes(String quotationId) {
    return _notes(quotationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(QuotationNoteModel.fromFirestore).toList());
  }

  Future<String> addQuotationNote(String quotationId, String noteText) async {
    final now = DateTime.now();
    final ref = await _notes(quotationId).add(
      QuotationNoteModel(
        id: '',
        note: noteText.trim(),
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    await addQuotationActivity(
      quotationId,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationNoteAdded.name,
        title: 'Internal note added',
        description: noteText.trim(),
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );

    return ref.id;
  }

  Future<void> deleteQuotationNote(String quotationId, String noteId) async {
    await _notes(quotationId).doc(noteId).delete();
  }

  Future<void> updatePdfMetadata({
    required String quotationId,
    required String pdfUrl,
    required String pdfStoragePath,
    required int pdfVersion,
  }) async {
    final now = DateTime.now();
    await _quotations.doc(quotationId).update({
      'pdfUrl': pdfUrl,
      'pdfStoragePath': pdfStoragePath,
      'pdfGeneratedAt': Timestamp.fromDate(now),
      'pdfVersion': pdfVersion,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addQuotationActivity(
      quotationId,
      QuotationActivityModel(
        id: '',
        type: ActivityType.quotationPdfGenerated.name,
        title: 'PDF generated & saved',
        description: 'Quotation PDF version $pdfVersion generated and uploaded to cloud storage',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
        metadata: {'version': pdfVersion, 'path': pdfStoragePath},
      ),
    );
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return QuotationRepository(
    db: FirebaseFirestore.instance,
    clientRepo: ref.watch(clientRepositoryProvider),
    currentUserId: auth.currentUserId,
    currentUserName: auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin',
  );
});

final quotationsStreamProvider = StreamProvider<List<QuotationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppCollections.quotations)
      .where('isArchived', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(QuotationModel.fromFirestore).toList());
});
