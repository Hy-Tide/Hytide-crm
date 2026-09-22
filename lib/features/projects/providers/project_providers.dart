import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../models/project_activity_model.dart';
import '../models/project_filter_model.dart';
import '../models/project_milestone_model.dart';
import '../models/project_model.dart';
import '../models/project_note_model.dart';
import '../models/project_requirement_model.dart';
import '../models/project_task_model.dart';
import '../repositories/project_repository.dart';

final projectFilterProvider = StateProvider<ProjectFilter>((ref) {
  return const ProjectFilter();
});

final projectSearchQueryProvider = StateProvider<String>((ref) => '');

final projectKpiCountsProvider = FutureProvider<ProjectKpiCounts>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return await repo.getProjectKpiCounts();
});

final paginatedProjectsProvider =
    FutureProvider.family<ProjectPaginatedResult, DocumentSnapshot?>((ref, startAfter) async {
  final repo = ref.watch(projectRepositoryProvider);
  final filter = ref.watch(projectFilterProvider);
  final searchQuery = ref.watch(projectSearchQueryProvider);

  return await repo.getProjectsPaginated(
    filter: filter,
    searchQuery: searchQuery,
    limit: 20,
    startAfter: startAfter,
  );
});

final projectDetailStreamProvider = StreamProvider.family<ProjectModel?, String>((ref, id) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectById(id);
});

final projectActivitiesProvider =
    StreamProvider.family<List<ProjectActivityModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectActivities(projectId);
});

final projectNotesProvider =
    StreamProvider.family<List<ProjectNoteModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectNotes(projectId);
});

final projectRequirementsProvider =
    StreamProvider.family<List<ProjectRequirementModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectRequirements(projectId);
});

final projectTasksProvider =
    StreamProvider.family<List<ProjectTaskModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectTasks(projectId);
});

final projectMilestonesProvider =
    StreamProvider.family<List<ProjectMilestoneModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectMilestones(projectId);
});

final clientProjectsProvider =
    StreamProvider.family<List<ProjectModel>, String>((ref, clientId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamProjectsByClient(clientId);
});

/// Sync coordinator for project events and conversions
final projectSyncCoordinatorProvider = Provider<void>((ref) {
  final bus = ref.watch(appEventBusProvider);

  final sub = bus.stream.listen((event) {
    if (event is ProjectCreatedEvent ||
        event is ProjectUpdatedEvent ||
        event is ProjectStatusChangedEvent ||
        event is ProjectCompletedEvent ||
        event is ProjectArchivedEvent ||
        event is ProjectRestoredEvent ||
        event is ProjectDeletedEvent ||
        event is QuotationConvertedEvent) {
      ref.invalidate(projectKpiCountsProvider);
      ref.invalidate(paginatedProjectsProvider);
    }
  });

  ref.onDispose(sub.cancel);
});

