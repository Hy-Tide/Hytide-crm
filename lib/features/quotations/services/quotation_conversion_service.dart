// lib/features/quotations/services/quotation_conversion_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/models/client_activity_model.dart';
import '../../clients/repositories/client_repository.dart';
import '../models/quotation_activity_model.dart';
import '../models/quotation_model.dart';
import '../repositories/quotation_repository.dart';

import '../../projects/models/project_model.dart';
import '../../projects/services/project_number_service.dart';

class QuotationConversionEligibilityResult {
  final bool isEligible;
  final String? message;
  final String? existingProjectId;

  const QuotationConversionEligibilityResult({
    required this.isEligible,
    this.message,
    this.existingProjectId,
  });
}

class QuotationConversionService {
  final FirebaseFirestore _db;
  final QuotationRepository? _quotationRepo;
  final ClientRepository? _clientRepo;
  final ProjectNumberService _projectNumberService;
  final String? currentUserId;
  final String currentUserName;
  final AppEventBus? _eventBus;

  QuotationConversionService({
    required FirebaseFirestore db,
    QuotationRepository? quotationRepo,
    ClientRepository? clientRepo,
    ProjectNumberService? projectNumberService,
    this.currentUserId,
    this.currentUserName = 'Admin',
    AppEventBus? eventBus,
  })  : _db = db,
        _quotationRepo = quotationRepo,
        _clientRepo = clientRepo,
        _projectNumberService = projectNumberService ?? ProjectNumberService(db: db),
        _eventBus = eventBus;

  CollectionReference<Map<String, dynamic>> get _quotations =>
      _db.collection(AppCollections.quotations);

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection(AppCollections.projects);

  CollectionReference<Map<String, dynamic>> get _globalActivities =>
      _db.collection(AppCollections.activities);

  /// Pure validator: check if a quotation is eligible to be converted into a project
  QuotationConversionEligibilityResult checkEligibility(QuotationModel quotation) {
    if (quotation.convertedToProject &&
        quotation.projectId != null &&
        quotation.projectId!.isNotEmpty) {
      return QuotationConversionEligibilityResult(
        isEligible: false,
        message: 'This quotation has already been converted into a project.',
        existingProjectId: quotation.projectId,
      );
    }

    if (quotation.status != QuotationStatus.accepted) {
      return QuotationConversionEligibilityResult(
        isEligible: false,
        message: 'Only accepted quotations can be converted into projects. '
            'Current status is "${quotation.status.displayName}".',
      );
    }

    return const QuotationConversionEligibilityResult(isEligible: true);
  }

  /// Converts an accepted quotation into a project foundation record atomically
  Future<String> convertQuotationToProject({
    required QuotationModel quotation,
    String? projectName,
    String? assignedToUid,
    String? assignedToName,
  }) async {
    final validation = checkEligibility(quotation);
    if (!validation.isEligible) {
      if (validation.existingProjectId != null) {
        return validation.existingProjectId!;
      }
      throw Exception(validation.message ?? 'Quotation not eligible for conversion');
    }

    final authorUid = currentUserId ?? quotation.createdBy;
    final authorName = currentUserName.isNotEmpty ? currentUserName : quotation.createdByName;
    final now = DateTime.now();

    final quotRef = _quotations.doc(quotation.id);
    final projectRef = _projects.doc();
    final newProjectId = projectRef.id;

    final projName = (projectName != null && projectName.trim().isNotEmpty)
        ? projectName.trim()
        : quotation.title;

    final targetAssignedTo = assignedToUid ?? quotation.assignedTo;
    final targetAssignedName = assignedToName ?? quotation.assignedToName;

    // Generate atomic project number before transaction
    final projectNumber = await _projectNumberService.generateNextProjectNumber();

    final searchTokens = ProjectModel.buildSearchTokens(
      projectNumber: projectNumber,
      title: projName,
      clientName: quotation.clientName,
      companyName: quotation.companyName,
      projectManagerName: targetAssignedName,
    );

    // 1. Transaction to guarantee atomic conversion and prevent duplicate project creation
    await _db.runTransaction((tx) async {
      final quotSnap = await tx.get(quotRef);
      if (!quotSnap.exists) {
        throw Exception('Quotation not found');
      }

      final quotData = quotSnap.data()!;
      final alreadyConverted = quotData['convertedToProject'] as bool? ?? false;
      if (alreadyConverted) {
        final existingId = quotData['projectId'] as String? ?? '';
        throw Exception('Quotation already converted to project $existingId');
      }

      final currentStatus = quotData['status'] as String? ?? '';
      if (currentStatus != QuotationStatus.accepted.name) {
        throw Exception('Quotation must be in Accepted status to convert into a project');
      }

      // Create Project Document with complete schema
      tx.set(projectRef, {
        'id': newProjectId,
        'projectNumber': projectNumber,
        'name': projName,
        'title': projName,
        'clientId': quotation.clientId,
        'clientName': quotation.clientName,
        'companyName': quotation.companyName,
        'sourceQuotationId': quotation.id,
        'sourceLeadId': quotation.sourceLeadId,
        'quotationNumber': quotation.quotationNumber,
        'projectType': ProjectType.webApplication.name,
        'status': ProjectStatus.planning.name,
        'priority': ProjectPriority.medium.name,
        'startDate': Timestamp.fromDate(now),
        'expectedEndDate': null,
        'actualEndDate': null,
        'assignedTo': targetAssignedTo.isNotEmpty ? [targetAssignedTo] : <String>[],
        'assignedToNames': targetAssignedName.isNotEmpty ? [targetAssignedName] : <String>[],
        'projectManager': targetAssignedTo,
        'projectManagerName': targetAssignedName,
        'estimatedValue': quotation.grandTotal,
        'quotationValue': quotation.grandTotal,
        'budget': quotation.grandTotal,
        'progress': 0,
        'description': quotation.description,
        'notes': quotation.notes,
        'isArchived': false,
        'searchTokens': searchTokens,
        'createdBy': authorUid,
        'createdByName': authorName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update Quotation Status
      tx.update(quotRef, {
        'status': QuotationStatus.converted.name,
        'convertedToProject': true,
        'projectId': newProjectId,
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    // 2. Log Activity in Quotation
    try {
      if (_quotationRepo != null) {
        await _quotationRepo.addQuotationActivity(
          quotation.id,
          QuotationActivityModel(
            id: '',
            type: ActivityType.quotationConvertedToProject.name,
            title: 'Converted to project',
            description: 'Project "$projName" ($projectNumber) created from quotation ${quotation.quotationNumber}',
            createdBy: authorUid,
            createdByName: authorName,
            createdAt: now,
            metadata: {
              'projectId': newProjectId,
              'projectNumber': projectNumber,
            },
          ),
        );
      }
    } catch (_) {}

    // 3. Log Activity in Project
    try {
      await projectRef.collection(AppCollections.projectActivities).add({
        'type': ActivityType.projectCreated.name,
        'title': 'Project created',
        'description': 'Project initiated from quotation ${quotation.quotationNumber}',
        'createdBy': authorUid,
        'createdByName': authorName,
        'createdAt': Timestamp.fromDate(now),
        'metadata': {
          'sourceQuotationId': quotation.id,
          'quotationNumber': quotation.quotationNumber,
        },
      });
    } catch (_) {}

    // 4. Log Activity in Client
    try {
      if (_clientRepo != null && quotation.clientId.isNotEmpty) {
        await _clientRepo.addClientActivity(
          quotation.clientId,
          ClientActivityModel(
            id: '',
            type: ActivityType.projectCreated.name,
            title: 'Project created from quotation',
            description: 'Project "$projName" ($projectNumber) initiated from quotation ${quotation.quotationNumber} (${quotation.currency} ${quotation.grandTotal.toStringAsFixed(2)})',
            createdBy: authorUid,
            createdByName: authorName,
            createdAt: now,
            metadata: {
              'sourceQuotationId': quotation.id,
              'quotationNumber': quotation.quotationNumber,
              'projectId': newProjectId,
              'projectNumber': projectNumber,
            },
          ),
        );
      }
    } catch (_) {}

    // 5. Log in Global Activities
    try {
      await _globalActivities.add({
        'type': ActivityType.projectCreated.name,
        'description': 'Project "$projName" ($projectNumber) created from quotation ${quotation.quotationNumber}',
        'userName': authorName,
        'timestamp': Timestamp.fromDate(now),
        'entityId': newProjectId,
        'entityType': 'project',
      });
    } catch (_) {}

    _eventBus?.emit(
      QuotationConvertedEvent(
        quotation.copyWith(convertedToProject: true, projectId: newProjectId),
        createdProjectId: newProjectId,
      ),
    );

    return newProjectId;
  }
}

final quotationConversionServiceProvider = Provider<QuotationConversionService>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final db = FirebaseFirestore.instance;
  return QuotationConversionService(
    db: db,
    quotationRepo: ref.watch(quotationRepositoryProvider),
    clientRepo: ref.watch(clientRepositoryProvider),
    projectNumberService: ProjectNumberService(db: db),
    currentUserId: auth.currentUserId,
    currentUserName: auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin',
    eventBus: ref.watch(appEventBusProvider),
  );
});
