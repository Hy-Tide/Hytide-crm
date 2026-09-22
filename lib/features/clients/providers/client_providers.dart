import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../followups/models/followup_model.dart';
import '../../followups/repositories/followup_repository.dart';
import '../models/client_activity_model.dart';
import '../models/client_filter_model.dart';
import '../models/client_model.dart';
import '../models/client_note_model.dart';
import '../repositories/client_repository.dart';

final clientFilterProvider = StateProvider<ClientFilter>((ref) {
  return const ClientFilter();
});

final clientSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final clientKpiCountsProvider = FutureProvider<ClientKpiCounts>((ref) async {
  final repo = ref.watch(clientRepositoryProvider);
  return repo.getClientCounts();
});

class ClientListState {
  final List<ClientModel> clients;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  final bool isLoadingMore;

  const ClientListState({
    this.clients = const [],
    this.lastDoc,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  ClientListState copyWith({
    List<ClientModel>? clients,
    DocumentSnapshot? Function()? lastDoc,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ClientListState(
      clients: clients ?? this.clients,
      lastDoc: lastDoc != null ? lastDoc() : this.lastDoc,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PaginatedClientsNotifier extends AsyncNotifier<ClientListState> {
  @override
  Future<ClientListState> build() async {
    final repo = ref.watch(clientRepositoryProvider);
    final filter = ref.watch(clientFilterProvider);
    final search = ref.watch(clientSearchQueryProvider);

    // Subscribe to domain events
    final bus = ref.watch(appEventBusProvider);
    final sub = bus.stream.listen((event) {
      switch (event) {
        case ClientCreatedEvent(:final client):
        case ClientConvertedEvent(:final client):
          addClientLocally(client);
          ref.invalidate(clientKpiCountsProvider);
          break;
        case ClientUpdatedEvent(:final client):
          updateClientLocally(client);
          ref.invalidate(clientKpiCountsProvider);
          break;
        case ClientRestoredEvent():
          ref.invalidate(clientKpiCountsProvider);
          break;
        case ClientArchivedEvent(:final clientId):
          removeClientLocally(clientId);
          ref.invalidate(clientKpiCountsProvider);
          break;
        default:
          break;
      }
    });
    ref.onDispose(sub.cancel);

    final res = await repo.getClientsPaginated(
      filter: filter,
      searchQuery: search,
      limit: 25,
    );

    return ClientListState(
      clients: res.clients,
      lastDoc: res.lastDocument,
      hasMore: res.hasMore,
    );
  }

  void addClientLocally(ClientModel client) {
    final current = state.value;
    if (current == null) return;
    final index = current.clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      updateClientLocally(client);
      return;
    }
    state = AsyncData(current.copyWith(
      clients: [client, ...current.clients],
    ));
  }

  void updateClientLocally(ClientModel client) {
    final current = state.value;
    if (current == null) return;
    final index = current.clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      final updated = List<ClientModel>.from(current.clients);
      updated[index] = client;
      state = AsyncData(current.copyWith(clients: updated));
    }
  }

  void removeClientLocally(String clientId) {
    final current = state.value;
    if (current == null) return;
    final updated = current.clients.where((c) => c.id != clientId).toList();
    if (updated.length != current.clients.length) {
      state = AsyncData(current.copyWith(clients: updated));
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(clientRepositoryProvider);
      final filter = ref.read(clientFilterProvider);
      final search = ref.read(clientSearchQueryProvider);

      final res = await repo.getClientsPaginated(
        filter: filter,
        searchQuery: search,
        startAfter: current.lastDoc,
        limit: 25,
      );

      state = AsyncData(ClientListState(
        clients: [...current.clients, ...res.clients],
        lastDoc: res.lastDocument ?? current.lastDoc,
        hasMore: res.hasMore,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    ref.invalidate(clientKpiCountsProvider);
  }
}

final paginatedClientsProvider =
    AsyncNotifierProvider<PaginatedClientsNotifier, ClientListState>(() {
  return PaginatedClientsNotifier();
});

final clientActivitiesProvider =
    StreamProvider.family<List<ClientActivityModel>, String>((ref, clientId) {
  return ref.watch(clientRepositoryProvider).streamClientActivities(clientId);
});

final clientNotesProvider =
    StreamProvider.family<List<ClientNoteModel>, String>((ref, clientId) {
  return ref.watch(clientRepositoryProvider).streamClientNotes(clientId);
});

final clientFollowUpsProvider =
    StreamProvider.family<List<FollowUpModel>, (String, String?)>((ref, arg) {
  final (clientId, sourceLeadId) = arg;
  return ref
      .watch(followUpRepositoryProvider)
      .streamClientFollowUps(clientId, sourceLeadId: sourceLeadId);
});
