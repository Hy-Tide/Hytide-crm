import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../auth/models/user_model.dart';
import '../models/lead_activity_model.dart';
import '../models/lead_filter_model.dart';
import '../models/lead_model.dart';
import '../models/lead_note_model.dart';
import '../repositories/lead_repository.dart';

// ─── Filter & View State Providers ────────────────────────────────────────────

final leadFilterProvider = StateProvider<LeadFilter>((ref) => const LeadFilter());
final leadSortProvider = StateProvider<LeadSortOption>((ref) => LeadSortOption.recentlyUpdated);
final leadSearchProvider = StateProvider<String>((ref) => '');
final leadSearchQueryProvider = leadSearchProvider;
final leadViewModeProvider = StateProvider<LeadViewMode>((ref) => LeadViewMode.table);

// ─── Active Staff Provider ────────────────────────────────────────────────────

final activeUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(AppCollections.users)
      .where('isActive', isEqualTo: true)
      .get();
  return snap.docs.map(UserModel.fromFirestore).toList();
});

// ─── Pagination State & Notifier ──────────────────────────────────────────────

class LeadPaginationState {
  final List<LeadModel> leads;
  final int pageIndex; // 0-indexed
  final int pageSize;
  final int totalCount;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final List<DocumentSnapshot<Map<String, dynamic>>?> pageCursors;

  const LeadPaginationState({
    this.leads = const [],
    this.pageIndex = 0,
    this.pageSize = 25,
    this.totalCount = 0,
    this.isLoading = false,
    this.hasMore = false,
    this.errorMessage,
    this.pageCursors = const [null],
  });

  int get startIndex => totalCount == 0 ? 0 : pageIndex * pageSize + 1;
  int get endIndex {
    final computed = (pageIndex + 1) * pageSize;
    return computed > totalCount ? totalCount : computed;
  }
  bool get hasPreviousPage => pageIndex > 0;
  bool get hasNextPage => hasMore;
  String? get error => errorMessage;
  int get currentPage => pageIndex;

  LeadPaginationState copyWith({
    List<LeadModel>? leads,
    int? pageIndex,
    int? pageSize,
    int? totalCount,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    List<DocumentSnapshot<Map<String, dynamic>>?>? pageCursors,
  }) {
    return LeadPaginationState(
      leads: leads ?? this.leads,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      pageCursors: pageCursors ?? this.pageCursors,
    );
  }
}

class LeadPaginationNotifier extends StateNotifier<LeadPaginationState> {
  final Ref _ref;
  StreamSubscription? _eventSub;

  LeadPaginationNotifier(this._ref) : super(const LeadPaginationState()) {
    _initEventListener();
    loadFirstPage();
  }

  void _initEventListener() {
    final bus = _ref.read(appEventBusProvider);
    _eventSub = bus.stream.listen((event) {
      switch (event) {
        case LeadCreatedEvent(:final lead):
          addLeadLocally(lead);
          break;
        case LeadUpdatedEvent(:final lead):
          updateLeadLocally(lead);
          break;
        case LeadStatusChangedEvent(:final lead):
          updateLeadLocally(lead);
          break;
        case LeadDeletedEvent(:final leadId):
          removeLeadLocally(leadId);
          break;
        default:
          break;
      }
    });
  }

  void addLeadLocally(LeadModel lead) {
    final index = state.leads.indexWhere((l) => l.id == lead.id);
    if (index != -1) {
      updateLeadLocally(lead);
      return;
    }
    state = state.copyWith(
      leads: [lead, ...state.leads],
      totalCount: state.totalCount + 1,
    );
  }

  void updateLeadLocally(LeadModel lead) {
    final index = state.leads.indexWhere((l) => l.id == lead.id);
    if (index != -1) {
      final updatedList = List<LeadModel>.from(state.leads);
      updatedList[index] = lead;
      state = state.copyWith(leads: updatedList);
    }
  }

  void removeLeadLocally(String leadId) {
    final updatedList = state.leads.where((l) => l.id != leadId).toList();
    if (updatedList.length != state.leads.length) {
      state = state.copyWith(
        leads: updatedList,
        totalCount: (state.totalCount - 1).clamp(0, 999999),
      );
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  LeadRepository get _repo => _ref.read(leadRepositoryProvider);
  LeadFilter get _filter => _ref.read(leadFilterProvider);
  LeadSortOption get _sort => _ref.read(leadSortProvider);
  String get _search => _ref.read(leadSearchProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, pageIndex: 0, pageCursors: [null]);
    try {
      final res = await _repo.getLeadsPaginated(
        lastDocument: null,
        limit: state.pageSize,
        filter: _filter,
        sort: _sort,
        searchQuery: _search,
      );

      final nextCursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
      if (res.lastDocument != null) {
        nextCursors.add(res.lastDocument);
      }

      state = state.copyWith(
        leads: res.leads,
        totalCount: res.totalCount,
        hasMore: res.hasMore,
        isLoading: false,
        pageIndex: 0,
        pageCursors: nextCursors,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> nextPage() async {
    if (!state.hasMore || state.isLoading) return;
    final nextIndex = state.pageIndex + 1;
    final cursor = nextIndex < state.pageCursors.length ? state.pageCursors[nextIndex] : null;
    if (cursor == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final res = await _repo.getLeadsPaginated(
        lastDocument: cursor,
        limit: state.pageSize,
        filter: _filter,
        sort: _sort,
        searchQuery: _search,
      );

      final cursors = List<DocumentSnapshot<Map<String, dynamic>>?>.from(state.pageCursors);
      if (res.lastDocument != null && nextIndex + 1 >= cursors.length) {
        cursors.add(res.lastDocument);
      }

      state = state.copyWith(
        leads: res.leads,
        pageIndex: nextIndex,
        hasMore: res.hasMore,
        isLoading: false,
        pageCursors: cursors,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> previousPage() async {
    if (state.pageIndex <= 0 || state.isLoading) return;
    final prevIndex = state.pageIndex - 1;
    final cursor = state.pageCursors[prevIndex];

    state = state.copyWith(isLoading: true);
    try {
      final res = await _repo.getLeadsPaginated(
        lastDocument: cursor,
        limit: state.pageSize,
        filter: _filter,
        sort: _sort,
        searchQuery: _search,
      );

      state = state.copyWith(
        leads: res.leads,
        pageIndex: prevIndex,
        hasMore: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() => loadFirstPage();
  Future<void> loadNextPage() => nextPage();
  Future<void> loadPreviousPage() => previousPage();
}

final leadPaginationProvider =
    StateNotifierProvider<LeadPaginationNotifier, LeadPaginationState>((ref) {
  // Watch filter, sort, search triggers to reload first page
  ref.watch(leadFilterProvider);
  ref.watch(leadSortProvider);
  ref.watch(leadSearchProvider);
  return LeadPaginationNotifier(ref);
});

// ─── Kanban Stream Provider ───────────────────────────────────────────────────

final kanbanLeadsStreamProvider = StreamProvider<List<LeadModel>>((ref) {
  final repo = ref.watch(leadRepositoryProvider);
  final filter = ref.watch(leadFilterProvider);
  return repo.streamAllLeadsForKanban(filter: filter);
});

// ─── Lead Details & Subcollection Family Providers ────────────────────────────

final leadDetailProvider = StreamProvider.family<LeadModel?, String>((ref, id) {
  return ref.watch(leadRepositoryProvider).streamLeadById(id);
});
final leadDetailStreamProvider = leadDetailProvider;

final leadActivitiesStreamProvider =
    StreamProvider.family<List<LeadActivityModel>, String>((ref, leadId) {
  return ref.watch(leadRepositoryProvider).streamLeadActivities(leadId);
});

final leadNotesStreamProvider =
    StreamProvider.family<List<LeadNoteModel>, String>((ref, leadId) {
  return ref.watch(leadRepositoryProvider).streamLeadNotes(leadId);
});
