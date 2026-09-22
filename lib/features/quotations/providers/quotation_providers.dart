import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../settings/models/company_settings_model.dart';
import '../models/quotation_activity_model.dart';
import '../models/quotation_filter_model.dart';
import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';
import '../models/quotation_note_model.dart';
import '../repositories/quotation_repository.dart';

final quotationFilterProvider = StateProvider<QuotationFilter>((ref) {
  return const QuotationFilter();
});

final quotationSearchQueryProvider = StateProvider<String>((ref) => '');

final quotationKpiCountsProvider = FutureProvider<QuotationKpiCounts>((ref) async {
  final repo = ref.watch(quotationRepositoryProvider);
  return await repo.getQuotationKpiCounts();
});

final paginatedQuotationsProvider =
    FutureProvider.family<QuotationPaginatedResult, DocumentSnapshot?>((ref, startAfter) async {
  final repo = ref.watch(quotationRepositoryProvider);
  final filter = ref.watch(quotationFilterProvider);
  final searchQuery = ref.watch(quotationSearchQueryProvider);

  return await repo.getQuotationsPaginated(
    filter: filter,
    searchQuery: searchQuery,
    limit: 20,
    startAfter: startAfter,
  );
});

final quotationDetailProvider = StreamProvider.family<QuotationModel?, String>((ref, id) {
  final repo = ref.watch(quotationRepositoryProvider);
  return repo.streamById(id);
});

final quotationItemsProvider =
    StreamProvider.family<List<QuotationItemModel>, String>((ref, quotationId) {
  final repo = ref.watch(quotationRepositoryProvider);
  return repo.streamQuotationItems(quotationId);
});

final quotationActivitiesProvider =
    StreamProvider.family<List<QuotationActivityModel>, String>((ref, quotationId) {
  final repo = ref.watch(quotationRepositoryProvider);
  return repo.streamQuotationActivities(quotationId);
});

final quotationNotesProvider =
    StreamProvider.family<List<QuotationNoteModel>, String>((ref, quotationId) {
  final repo = ref.watch(quotationRepositoryProvider);
  return repo.streamQuotationNotes(quotationId);
});

final clientQuotationsProvider =
    StreamProvider.family<List<QuotationModel>, String>((ref, clientId) {
  final repo = ref.watch(quotationRepositoryProvider);
  return repo.streamQuotationsByClient(clientId);
});

final companySettingsProvider = FutureProvider<CompanySettingsModel>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection(AppCollections.settings)
        .doc('company')
        .get();
    if (doc.exists && doc.data() != null) {
      return CompanySettingsModel.fromFirestore(doc);
    }
  } catch (_) {}
  return const CompanySettingsModel();
});

/// Sync coordinator for quotation events
final quotationSyncCoordinatorProvider = Provider<void>((ref) {
  final bus = ref.watch(appEventBusProvider);

  final sub = bus.stream.listen((event) {
    if (event is QuotationCreatedEvent ||
        event is QuotationUpdatedEvent ||
        event is QuotationStatusChangedEvent ||
        event is QuotationConvertedEvent ||
        event is QuotationDeletedEvent) {
      ref.invalidate(quotationKpiCountsProvider);
      ref.invalidate(paginatedQuotationsProvider);
    }
  });

  ref.onDispose(sub.cancel);
});

