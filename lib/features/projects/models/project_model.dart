// lib/features/projects/models/project_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';
export 'project_link_model.dart';

class ProjectModel extends Equatable {
  final String id;
  final String projectNumber;

  // Client Details
  final String clientId;
  final String clientName;
  final String companyName;

  // Pipeline Traceability
  final String? sourceQuotationId;
  final String? quotationNumber;
  final String? sourceLeadId;

  // Meta
  final String title;
  final String description;
  final String notes;
  final ProjectType projectType;
  final ProjectStatus status;
  final ProjectPriority priority;

  // Dates
  final DateTime? startDate;
  final DateTime? expectedEndDate;
  final DateTime? actualEndDate;

  // Team Assignment
  final String assignedTo;
  final String assignedToName;
  final List<String> assignedToNames;
  final String projectManager;
  final String projectManagerName;

  // Financials
  final double quotationValue;
  final double estimatedValue;
  final double budget;

  // Progress (0 - 100)
  final int progress;

  // Staff Attribution
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Flags & Search
  final bool isArchived;
  final List<String> searchTokens;

  const ProjectModel({
    required this.id,
    required this.projectNumber,
    required this.clientId,
    required this.clientName,
    this.companyName = '',
    this.sourceQuotationId,
    this.quotationNumber,
    this.sourceLeadId,
    required this.title,
    String? name,
    this.description = '',
    this.notes = '',
    this.projectType = ProjectType.webApplication,
    this.status = ProjectStatus.planning,
    this.priority = ProjectPriority.medium,
    this.startDate,
    this.expectedEndDate,
    this.actualEndDate,
    this.assignedTo = '',
    this.assignedToName = '',
    this.assignedToNames = const [],
    this.projectManager = '',
    this.projectManagerName = '',
    this.quotationValue = 0.0,
    this.estimatedValue = 0.0,
    this.budget = 0.0,
    this.progress = 0,
    required this.createdBy,
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.searchTokens = const [],
  });

  /// Backward compatibility for existing code using `name`
  String get name => title;

  /// Dynamic Overdue check: past expectedEndDate and not completed, cancelled, or archived
  bool get isOverdue {
    if (expectedEndDate == null) return false;
    if (status == ProjectStatus.completed ||
        status == ProjectStatus.cancelled ||
        status == ProjectStatus.archived) {
      return false;
    }
    return DateTime.now().isAfter(expectedEndDate!);
  }

  bool get isCompleted => status == ProjectStatus.completed;

  /// Static helper to build searchable tokens
  static List<String> buildSearchTokens({
    required String projectNumber,
    required String title,
    String? clientName,
    String? companyName,
    String? quotationNumber,
    String? projectManagerName,
    String? assignedToName,
  }) {
    final tokens = <String>{};

    void addWords(String? text) {
      if (text == null || text.trim().isEmpty) return;
      final clean = text.toLowerCase().trim();
      tokens.add(clean);
      for (final word in clean.split(RegExp(r'[\s\-_\/,\.]+'))) {
        if (word.length >= 2) {
          tokens.add(word);
        }
      }
    }

    addWords(projectNumber);
    addWords(title);
    addWords(clientName);
    addWords(companyName);
    addWords(quotationNumber);
    addWords(projectManagerName);
    addWords(assignedToName);

    return tokens.toList();
  }

  /// Instance method to generate searchable lowercase prefix tokens
  List<String> toSearchTokens() {
    return buildSearchTokens(
      projectNumber: projectNumber,
      title: title,
      clientName: clientName,
      companyName: companyName,
      quotationNumber: quotationNumber,
      projectManagerName: projectManagerName,
      assignedToName: assignedToName,
    );
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProjectModel.fromMap(data, id: doc.id);
  }

  factory ProjectModel.fromMap(Map<String, dynamic> data, {String? id}) {
    // Handle both 'title' and legacy 'name'
    final projectTitle = data['title'] as String? ?? data['name'] as String? ?? '';

    // Handle assignedTo which may be single string or legacy List<String>
    String assignedUid = '';
    if (data['assignedTo'] is String) {
      assignedUid = data['assignedTo'] as String;
    } else if (data['assignedTo'] is List && (data['assignedTo'] as List).isNotEmpty) {
      assignedUid = (data['assignedTo'] as List).first.toString();
    }

    List<String> assignedNames = [];
    if (data['assignedToNames'] is List) {
      assignedNames = List<String>.from(data['assignedToNames'] as List);
    }

    String assignedName = data['assignedToName'] as String? ?? '';
    if (assignedName.isEmpty && assignedNames.isNotEmpty) {
      assignedName = assignedNames.first;
    }

    return ProjectModel(
      id: id ?? data['id'] as String? ?? '',
      projectNumber: data['projectNumber'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      companyName: data['companyName'] as String? ?? data['clientName'] as String? ?? '',
      sourceQuotationId: data['sourceQuotationId'] as String?,
      quotationNumber: data['quotationNumber'] as String?,
      sourceLeadId: data['sourceLeadId'] as String?,
      title: projectTitle,
      description: data['description'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      projectType: ProjectType.fromString(data['projectType'] as String? ?? 'webApplication'),
      status: ProjectStatus.fromString(data['status'] as String? ?? 'planning'),
      priority: ProjectPriority.fromString(data['priority'] as String? ?? 'medium'),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      expectedEndDate: (data['expectedEndDate'] as Timestamp?)?.toDate(),
      actualEndDate: (data['actualEndDate'] as Timestamp?)?.toDate(),
      assignedTo: assignedUid,
      assignedToName: assignedName,
      assignedToNames: assignedNames,
      projectManager: data['projectManager'] as String? ?? '',
      projectManagerName: data['projectManagerName'] as String? ?? '',
      quotationValue: (data['quotationValue'] as num?)?.toDouble() ?? 0.0,
      estimatedValue: (data['estimatedValue'] as num?)?.toDouble() ?? 0.0,
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      progress: (data['progress'] as num?)?.toInt().clamp(0, 100) ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] as bool? ?? false,
      searchTokens: List<String>.from(data['searchTokens'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectNumber': projectNumber,
      'clientId': clientId,
      'clientName': clientName,
      'companyName': companyName.isNotEmpty ? companyName : clientName,
      if (sourceQuotationId != null) 'sourceQuotationId': sourceQuotationId,
      if (quotationNumber != null) 'quotationNumber': quotationNumber,
      if (sourceLeadId != null) 'sourceLeadId': sourceLeadId,
      'title': title,
      'name': title, // Backward compatibility
      'description': description,
      'notes': notes,
      'projectType': projectType.name,
      'status': status.name,
      'priority': priority.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expectedEndDate': expectedEndDate != null ? Timestamp.fromDate(expectedEndDate!) : null,
      'actualEndDate': actualEndDate != null ? Timestamp.fromDate(actualEndDate!) : null,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedToNames': assignedToNames.isNotEmpty
          ? assignedToNames
          : (assignedToName.isNotEmpty ? [assignedToName] : <String>[]),
      'projectManager': projectManager,
      'projectManagerName': projectManagerName,
      'quotationValue': quotationValue,
      'estimatedValue': estimatedValue,
      'budget': budget,
      'progress': progress.clamp(0, 100),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'searchTokens': searchTokens.isNotEmpty ? searchTokens : toSearchTokens(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? projectNumber,
    String? clientId,
    String? clientName,
    String? companyName,
    String? sourceQuotationId,
    String? quotationNumber,
    String? sourceLeadId,
    String? title,
    String? name,
    String? description,
    String? notes,
    ProjectType? projectType,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? startDate,
    DateTime? expectedEndDate,
    DateTime? actualEndDate,
    String? assignedTo,
    String? assignedToName,
    List<String>? assignedToNames,
    String? projectManager,
    String? projectManagerName,
    double? quotationValue,
    double? estimatedValue,
    double? budget,
    int? progress,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    List<String>? searchTokens,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      projectNumber: projectNumber ?? this.projectNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      companyName: companyName ?? this.companyName,
      sourceQuotationId: sourceQuotationId ?? this.sourceQuotationId,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
      title: title ?? name ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      projectType: projectType ?? this.projectType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToNames: assignedToNames ?? this.assignedToNames,
      projectManager: projectManager ?? this.projectManager,
      projectManagerName: projectManagerName ?? this.projectManagerName,
      quotationValue: quotationValue ?? this.quotationValue,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      budget: budget ?? this.budget,
      progress: progress ?? this.progress,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      searchTokens: searchTokens ?? this.searchTokens,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectNumber,
        clientId,
        title,
        status,
        priority,
        budget,
        progress,
        updatedAt,
        isArchived,
      ];
}
