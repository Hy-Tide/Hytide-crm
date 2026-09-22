// lib/features/projects/repositories/project_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/models/client_activity_model.dart';
import '../../clients/repositories/client_repository.dart';
import '../models/project_activity_model.dart';
import '../models/project_filter_model.dart';
import '../models/project_milestone_model.dart';
import '../models/project_model.dart';
import '../models/project_note_model.dart';
import '../models/project_requirement_model.dart';
import '../models/project_task_model.dart';
import '../services/project_number_service.dart';
import '../services/project_status_service.dart';

class ProjectPaginatedResult {
  final List<ProjectModel> projects;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const ProjectPaginatedResult({
    required this.projects,
    this.lastDocument,
    required this.hasMore,
  });
}

class ProjectKpiCounts {
  final int total;
  final int active;
  final int planning;
  final int onHold;
  final int completed;
  final int overdue;

  const ProjectKpiCounts({
    this.total = 0,
    this.active = 0,
    this.planning = 0,
    this.onHold = 0,
    this.completed = 0,
    this.overdue = 0,
  });
}

class ProjectRepository {
  final FirebaseFirestore _db;
  final ProjectNumberService _numberService;
  final ClientRepository? _clientRepo;
  final String? currentUserId;
  final String currentUserName;
  final UserRole currentUserRole;

  ProjectRepository({
    required FirebaseFirestore db,
    ProjectNumberService? numberService,
    ClientRepository? clientRepo,
    this.currentUserId,
    this.currentUserName = 'Admin',
    this.currentUserRole = UserRole.admin,
  })  : _db = db,
        _numberService = numberService ?? ProjectNumberService(db: db),
        _clientRepo = clientRepo;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection(AppCollections.projects);

  CollectionReference<Map<String, dynamic>> _activities(String projectId) =>
      _projects.doc(projectId).collection(AppCollections.projectActivities);

  CollectionReference<Map<String, dynamic>> _notes(String projectId) =>
      _projects.doc(projectId).collection(AppCollections.projectNotes);

  CollectionReference<Map<String, dynamic>> _requirements(String projectId) =>
      _projects.doc(projectId).collection(AppCollections.projectRequirements);

  CollectionReference<Map<String, dynamic>> _tasks(String projectId) =>
      _projects.doc(projectId).collection(AppCollections.projectTasks);

  CollectionReference<Map<String, dynamic>> _milestones(String projectId) =>
      _projects.doc(projectId).collection(AppCollections.projectMilestones);

  CollectionReference<Map<String, dynamic>> _links(String projectId) =>
      _projects.doc(projectId).collection('links');

  // ─── Queries & Pagination ──────────────────────────────────────────────────

  Future<ProjectPaginatedResult> getProjectsPaginated({
    required ProjectFilter filter,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _projects;

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

      if (filter.projectType != null) {
        query = query.where('projectType', isEqualTo: filter.projectType!.name);
      }

      if (filter.priority != null) {
        query = query.where('priority', isEqualTo: filter.priority!.name);
      }

      if (filter.clientId != null && filter.clientId!.isNotEmpty) {
        query = query.where('clientId', isEqualTo: filter.clientId);
      }

      if (filter.assignedTo != null && filter.assignedTo!.isNotEmpty) {
        query = query.where('assignedTo', arrayContains: filter.assignedTo);
      }

      // Date Filters
      if (filter.dateFilter != ProjectDateFilter.all) {
        DateTime? start;
        DateTime? end;
        final now = TimezoneHelper.now();

        switch (filter.dateFilter) {
          case ProjectDateFilter.today:
            start = TimezoneHelper.startOfTodayUtc();
            end = TimezoneHelper.endOfTodayUtc();
            break;
          case ProjectDateFilter.thisWeek:
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            start = TimezoneHelper.startOfDayUtc(startOfWeek);
            end = TimezoneHelper.endOfDayUtc(endOfWeek);
            break;
          case ProjectDateFilter.thisMonth:
            start = TimezoneHelper.startOfMonthUtc();
            end = TimezoneHelper.endOfMonthUtc();
            break;
          case ProjectDateFilter.thisYear:
            start = TimezoneHelper.startOfDayUtc(DateTime(now.year, 1, 1));
            end = TimezoneHelper.endOfDayUtc(DateTime(now.year, 12, 31));
            break;
          case ProjectDateFilter.custom:
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
          query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
        }
        if (end != null) {
          query = query.where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(end));
        }
      }

      // Sorting
      switch (filter.sortBy) {
        case ProjectSortBy.oldest:
          query = query.orderBy('createdAt', descending: false);
          break;
        case ProjectSortBy.projectNumber:
          query = query.orderBy('projectNumber', descending: false);
          break;
        case ProjectSortBy.deadlineSoonest:
          query = query.orderBy('expectedEndDate', descending: false);
          break;
        case ProjectSortBy.progressHighToLow:
          query = query.orderBy('progress', descending: true);
          break;
        case ProjectSortBy.progressLowToHigh:
          query = query.orderBy('progress', descending: false);
          break;
        case ProjectSortBy.budgetHighToLow:
          query = query.orderBy('budget', descending: true);
          break;
        case ProjectSortBy.budgetLowToHigh:
          query = query.orderBy('budget', descending: false);
          break;
        case ProjectSortBy.recentlyUpdated:
          query = query.orderBy('updatedAt', descending: true);
          break;
        case ProjectSortBy.newest:
          query = query.orderBy('createdAt', descending: true);
          break;
      }
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit + 1);

    final snapshot = await query.get();
    var docs = snapshot.docs;
    final hasMore = docs.length > limit;
    var results = (hasMore ? docs.sublist(0, limit) : docs)
        .map(ProjectModel.fromFirestore)
        .toList();

    // Client-side overdue filter if requested
    if (filter.isOverdueOnly) {
      results = results.where((p) => p.isOverdue).toList();
    }

    return ProjectPaginatedResult(
      projects: results,
      lastDocument: results.isNotEmpty && docs.isNotEmpty
          ? docs[results.length - 1]
          : null,
      hasMore: hasMore,
    );
  }

  /// Efficient Server Aggregate Counts for KPI Cards
  Future<ProjectKpiCounts> getProjectKpiCounts() async {
    try {
      final base = _projects.where('isArchived', isEqualTo: false);

      final totalFuture = base.count().get();
      final activeFuture = base.where('status', isEqualTo: ProjectStatus.active.name).count().get();
      final planningFuture = base.where('status', isEqualTo: ProjectStatus.planning.name).count().get();
      final onHoldFuture = base.where('status', isEqualTo: ProjectStatus.onHold.name).count().get();
      final completedFuture = base.where('status', isEqualTo: ProjectStatus.completed.name).count().get();

      // For overdue count, calculate over uncompleted projects with expectedEndDate before now
      final now = DateTime.now();
      final overdueFuture = base
          .where('status', whereIn: [
            ProjectStatus.planning.name,
            ProjectStatus.active.name,
            ProjectStatus.onHold.name,
          ])
          .where('expectedEndDate', isLessThan: Timestamp.fromDate(now))
          .count()
          .get();

      final results = await Future.wait([
        totalFuture,
        activeFuture,
        planningFuture,
        onHoldFuture,
        completedFuture,
        overdueFuture,
      ]);

      return ProjectKpiCounts(
        total: results[0].count ?? 0,
        active: results[1].count ?? 0,
        planning: results[2].count ?? 0,
        onHold: results[3].count ?? 0,
        completed: results[4].count ?? 0,
        overdue: results[5].count ?? 0,
      );
    } catch (_) {
      return const ProjectKpiCounts();
    }
  }

  Stream<List<ProjectModel>> streamProjects() {
    return _projects
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ProjectModel.fromFirestore).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Stream<ProjectModel?> streamProjectById(String id) {
    return _projects.doc(id).snapshots().map((d) => d.exists && d.data() != null ? ProjectModel.fromFirestore(d) : null);
  }

  Future<ProjectModel?> getProjectById(String id) async {
    final doc = await _projects.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProjectModel.fromFirestore(doc);
  }

  Stream<List<ProjectModel>> streamProjectsByClient(String clientId) {
    return _projects
        .where('clientId', isEqualTo: clientId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ProjectModel.fromFirestore).toList());
  }

  // ─── Lifecycle & Mutations ────────────────────────────────────────────────

  Future<String> createProject(ProjectModel project) async {
    final now = DateTime.now();
    String number = project.projectNumber;
    if (number.trim().isEmpty) {
      number = await _numberService.generateNextProjectNumber();
    }

    final searchTokens = ProjectModel.buildSearchTokens(
      projectNumber: number,
      title: project.title,
      clientName: project.clientName,
      companyName: project.companyName,
      projectManagerName: project.projectManagerName,
    );

    final docRef = _projects.doc();
    final newId = docRef.id;

    final preparedProject = project.copyWith(
      id: newId,
      projectNumber: number,
      searchTokens: searchTokens,
      createdBy: currentUserId ?? project.createdBy,
      createdByName: currentUserName.isNotEmpty ? currentUserName : project.createdByName,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(preparedProject.toMap());

    // Log Activity
    await addProjectActivity(
      newId,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectCreated.name,
        title: 'Project created',
        description: 'Project "$number - ${project.title}" created with status ${project.status.name}',
        createdBy: currentUserId ?? project.createdBy,
        createdByName: currentUserName,
        createdAt: now,
      ),
    );

    if (project.clientId.isNotEmpty && _clientRepo != null) {
      await _clientRepo.addClientActivity(
        project.clientId,
        ClientActivityModel(
          id: '',
          type: ActivityType.projectCreated.name,
          title: 'Project created',
          description: 'Project "$number - ${project.title}" created for client',
          createdBy: currentUserId ?? project.createdBy,
          createdByName: currentUserName,
          createdAt: now,
          metadata: {'projectId': newId, 'projectNumber': number},
        ),
      );
    }

    return newId;
  }

  Future<void> updateProject(ProjectModel project) async {
    final now = DateTime.now();
    final searchTokens = ProjectModel.buildSearchTokens(
      projectNumber: project.projectNumber,
      title: project.title,
      clientName: project.clientName,
      companyName: project.companyName,
      projectManagerName: project.projectManagerName,
    );

    final updated = project.copyWith(
      searchTokens: searchTokens,
      updatedAt: now,
    );

    await _projects.doc(project.id).update(updated.toMap());

    await addProjectActivity(
      project.id,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectUpdated.name,
        title: 'Project updated',
        description: 'Project details and configuration updated',
        createdBy: currentUserId ?? project.createdBy,
        createdByName: currentUserName,
        createdAt: now,
      ),
    );
  }

  Future<void> updateProjectStatus(String id, ProjectStatus newStatus, {String? reason}) async {
    final project = await getProjectById(id);
    if (project == null) throw Exception('Project not found');

    final validationError = ProjectStatusService.validateTransition(project.status, newStatus);
    if (validationError != null) throw Exception(validationError);

    final now = DateTime.now();
    final Map<String, dynamic> updates = {
      'status': newStatus.name,
      'updatedAt': Timestamp.fromDate(now),
    };

    // Auto-update progress and actualEndDate on completion
    if (newStatus == ProjectStatus.completed) {
      updates['progress'] = 100;
      updates['actualEndDate'] = Timestamp.fromDate(now);
    }

    await _projects.doc(id).update(updates);

    await addProjectActivity(
      id,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectStatusChanged.name,
        title: 'Status changed to ${newStatus.name}',
        description: reason != null && reason.trim().isNotEmpty
            ? 'Status changed from ${project.status.name} to ${newStatus.name}. Reason: ${reason.trim()}'
            : 'Status changed from ${project.status.name} to ${newStatus.name}',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
        metadata: {'oldStatus': project.status.name, 'newStatus': newStatus.name},
      ),
    );
  }

  Future<void> updateProjectProgress(String id, int progress) async {
    final clamped = progress.clamp(0, 100);
    final now = DateTime.now();

    final Map<String, dynamic> updates = {
      'progress': clamped,
      'updatedAt': Timestamp.fromDate(now),
    };

    if (clamped == 100) {
      updates['actualEndDate'] = Timestamp.fromDate(now);
    }

    await _projects.doc(id).update(updates);

    await addProjectActivity(
      id,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectProgressUpdated.name,
        title: 'Progress updated',
        description: 'Project progress updated to $clamped%',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
        metadata: {'progress': clamped},
      ),
    );
  }

  Future<void> archiveProject(String id) async {
    final now = DateTime.now();
    await _projects.doc(id).update({
      'isArchived': true,
      'status': ProjectStatus.archived.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addProjectActivity(
      id,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectArchived.name,
        title: 'Project archived',
        description: 'Project moved to archive',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );
  }

  Future<void> restoreProject(String id) async {
    final now = DateTime.now();
    await _projects.doc(id).update({
      'isArchived': false,
      'status': ProjectStatus.active.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await addProjectActivity(
      id,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectRestored.name,
        title: 'Project restored',
        description: 'Project restored from archive to active',
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );
  }

  Future<void> deleteProject(String id) async => await _projects.doc(id).delete();

  // ─── Subcollections ───────────────────────────────────────────────────────

  Stream<List<ProjectActivityModel>> streamProjectActivities(String projectId) {
    return _activities(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ProjectActivityModel.fromFirestore).toList());
  }

  Future<void> addProjectActivity(String projectId, ProjectActivityModel activity) async {
    await _activities(projectId).add(activity.toMap());
  }

  Stream<List<ProjectNoteModel>> streamProjectNotes(String projectId) {
    return _notes(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ProjectNoteModel.fromFirestore).toList());
  }

  Future<String> addProjectNote(String projectId, String noteText) async {
    final now = DateTime.now();
    final ref = await _notes(projectId).add(
      ProjectNoteModel(
        id: '',
        note: noteText.trim(),
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    await addProjectActivity(
      projectId,
      ProjectActivityModel(
        id: '',
        type: ActivityType.projectNoteAdded.name,
        title: 'Internal note added',
        description: noteText.trim(),
        createdBy: currentUserId ?? '',
        createdByName: currentUserName,
        createdAt: now,
      ),
    );

    return ref.id;
  }

  Future<void> deleteProjectNote(String projectId, String noteId) async {
    await _notes(projectId).doc(noteId).delete();
  }

  Stream<List<ProjectRequirementModel>> streamProjectRequirements(String projectId) {
    return _requirements(projectId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ProjectRequirementModel.fromFirestore).toList());
  }

  Future<String> addProjectRequirement(String projectId, ProjectRequirementModel req) async {
    final ref = await _requirements(projectId).add(req.toMap());
    return ref.id;
  }

  Future<void> updateProjectRequirement(String projectId, ProjectRequirementModel req) async {
    await _requirements(projectId).doc(req.id).update(req.toMap());
  }

  Future<void> deleteProjectRequirement(String projectId, String reqId) async {
    await _requirements(projectId).doc(reqId).delete();
  }

  Stream<List<ProjectTaskModel>> streamProjectTasks(String projectId) {
    return _tasks(projectId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ProjectTaskModel.fromFirestore).toList());
  }

  Future<String> addProjectTask(String projectId, ProjectTaskModel task) async {
    final ref = await _tasks(projectId).add(task.toMap());
    return ref.id;
  }

  Future<void> updateProjectTask(String projectId, ProjectTaskModel task) async {
    await _tasks(projectId).doc(task.id).update(task.toMap());
  }

  Future<void> deleteProjectTask(String projectId, String taskId) async {
    await _tasks(projectId).doc(taskId).delete();
  }

  Stream<List<ProjectMilestoneModel>> streamProjectMilestones(String projectId) {
    return _milestones(projectId)
        .orderBy('targetDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ProjectMilestoneModel.fromFirestore).toList());
  }

  Future<String> addProjectMilestone(String projectId, ProjectMilestoneModel milestone) async {
    final ref = await _milestones(projectId).add(milestone.toMap());
    return ref.id;
  }

  Future<void> updateProjectMilestone(String projectId, ProjectMilestoneModel milestone) async {
    await _milestones(projectId).doc(milestone.id).update(milestone.toMap());
  }

  Future<void> deleteProjectMilestone(String projectId, String milestoneId) async {
    await _milestones(projectId).doc(milestoneId).delete();
  }

  // Preserve legacy ProjectLink methods
  Stream<List<ProjectLink>> streamProjectLinks(String projectId) {
    return _links(projectId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ProjectLink.fromFirestore).toList());
  }

  Future<String> addProjectLink(String projectId, ProjectLink link) async {
    final ref = await _links(projectId).add(link.toMap());
    return ref.id;
  }

  Future<void> deleteProjectLink(String projectId, String linkId) async {
    await _links(projectId).doc(linkId).delete();
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────────────────

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final role = ref.watch(currentUserRoleProvider);
  final db = FirebaseFirestore.instance;
  return ProjectRepository(
    db: db,
    clientRepo: ref.watch(clientRepositoryProvider),
    currentUserId: auth.currentUserId,
    currentUserName: auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin',
    currentUserRole: role,
  );
});

final projectsStreamProvider = StreamProvider<List<ProjectModel>>((ref) {
  return ref.watch(projectRepositoryProvider).streamProjects();
});

final projectDetailProvider = StreamProvider.family<ProjectModel?, String>((ref, id) {
  return ref.watch(projectRepositoryProvider).streamProjectById(id);
});

final projectLinksProvider = StreamProvider.family<List<ProjectLink>, String>((ref, id) {
  return ref.watch(projectRepositoryProvider).streamProjectLinks(id);
});
