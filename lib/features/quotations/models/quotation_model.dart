// lib/features/quotations/models/quotation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';
import 'quotation_item_model.dart';

class QuotationModel extends Equatable {
  final String id;
  final String quotationNumber;
  final int revisionNumber;
  final String? parentQuotationId;

  // Client Details
  final String clientId;
  final String clientName;
  final String companyName;
  final String contactPerson;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String? sourceLeadId;

  // Quotation Meta
  final String title;
  final String description;
  final QuotationStatus status;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String currency;

  // Embedded Items Snapshot
  final List<QuotationItemModel> items;

  // Financial Breakdown
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final TaxType taxType;
  final double taxPercentage;
  final double taxAmount;
  final double shippingAmount;
  final double otherCharges;
  final double grandTotal;

  // Notes & Terms
  final String notes;
  final String termsAndConditions;

  // Staff Attribution
  final String assignedTo;
  final String assignedToName;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Workflow Milestones
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  // Project Linkage
  final bool convertedToProject;
  final String? projectId;

  // Status & PDF
  final bool isArchived;
  final String? pdfUrl;
  final String? pdfStoragePath;
  final DateTime? pdfGeneratedAt;
  final int pdfVersion;

  // Search
  final List<String> searchTokens;

  const QuotationModel({
    required this.id,
    required this.quotationNumber,
    this.revisionNumber = 1,
    this.parentQuotationId,
    required this.clientId,
    required this.clientName,
    this.companyName = '',
    this.contactPerson = '',
    this.clientEmail = '',
    this.clientPhone = '',
    this.clientAddress = '',
    this.sourceLeadId,
    required this.title,
    this.description = '',
    this.status = QuotationStatus.draft,
    required this.issueDate,
    required this.expiryDate,
    this.currency = 'INR',
    this.items = const [],
    this.subtotal = 0.0,
    this.discountType = DiscountType.percentage,
    this.discountValue = 0.0,
    this.discountAmount = 0.0,
    this.taxType = TaxType.gst,
    this.taxPercentage = 18.0,
    this.taxAmount = 0.0,
    this.shippingAmount = 0.0,
    this.otherCharges = 0.0,
    required this.grandTotal,
    this.notes = '',
    this.termsAndConditions = '',
    required this.assignedTo,
    this.assignedToName = '',
    required this.createdBy,
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.viewedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.convertedToProject = false,
    this.projectId,
    this.isArchived = false,
    this.pdfUrl,
    this.pdfStoragePath,
    this.pdfGeneratedAt,
    this.pdfVersion = 1,
    this.searchTokens = const [],
  });

  /// Dynamic Expiration Check
  bool get isExpired {
    if (status == QuotationStatus.accepted ||
        status == QuotationStatus.rejected ||
        status == QuotationStatus.cancelled ||
        status == QuotationStatus.converted) {
      return false;
    }
    return DateTime.now().isAfter(expiryDate);
  }

  QuotationStatus get effectiveStatus {
    if (status == QuotationStatus.draft) return QuotationStatus.draft;
    if (isExpired) return QuotationStatus.expired;
    return status;
  }

  // Workflow Permissions
  bool get canEdit => status == QuotationStatus.draft;
  bool get canSend =>
      status == QuotationStatus.draft ||
      status == QuotationStatus.sent ||
      status == QuotationStatus.viewed;
  bool get canAccept =>
      (status == QuotationStatus.sent || status == QuotationStatus.viewed) && !isExpired;
  bool get canReject =>
      (status == QuotationStatus.sent || status == QuotationStatus.viewed) && !isExpired;
  bool get canConvertToProject =>
      status == QuotationStatus.accepted && !convertedToProject;
  bool get canRevise => status != QuotationStatus.draft;

  // Helpers for legacy getters
  double get total => grandTotal;
  String? get projectName => null;

  factory QuotationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final itemsList = (data['items'] as List? ?? [])
        .map((item) => QuotationItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return QuotationModel(
      id: doc.id,
      quotationNumber: data['quotationNumber'] as String? ?? '',
      revisionNumber: (data['revisionNumber'] as num?)?.toInt() ?? 1,
      parentQuotationId: data['parentQuotationId'] as String?,
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      companyName: data['companyName'] as String? ?? data['clientName'] as String? ?? '',
      contactPerson: data['contactPerson'] as String? ?? '',
      clientEmail: data['clientEmail'] as String? ?? '',
      clientPhone: data['clientPhone'] as String? ?? '',
      clientAddress: data['clientAddress'] as String? ?? '',
      sourceLeadId: data['sourceLeadId'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: QuotationStatus.fromString(data['status'] as String? ?? 'draft'),
      issueDate: (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 14)),
      currency: data['currency'] as String? ?? 'INR',
      items: itemsList,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountType: DiscountType.fromString(data['discountType'] as String? ?? 'percentage'),
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxType: TaxType.fromString(data['taxType'] as String? ?? 'gst'),
      taxPercentage: (data['taxPercentage'] as num?)?.toDouble() ?? 18.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingAmount: (data['shippingAmount'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (data['otherCharges'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? (data['total'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String? ?? '',
      termsAndConditions: data['termsAndConditions'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
      convertedToProject: data['convertedToProject'] as bool? ?? false,
      projectId: data['projectId'] as String?,
      isArchived: data['isArchived'] as bool? ?? false,
      pdfUrl: data['pdfUrl'] as String?,
      pdfStoragePath: data['pdfStoragePath'] as String?,
      pdfGeneratedAt: (data['pdfGeneratedAt'] as Timestamp?)?.toDate(),
      pdfVersion: (data['pdfVersion'] as num?)?.toInt() ?? 1,
      searchTokens: List<String>.from(data['searchTokens'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quotationNumber': quotationNumber,
      'revisionNumber': revisionNumber,
      'parentQuotationId': parentQuotationId,
      'clientId': clientId,
      'clientName': clientName,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'clientAddress': clientAddress,
      'sourceLeadId': sourceLeadId,
      'title': title,
      'description': description,
      'status': status.name,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'currency': currency,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'discountAmount': discountAmount,
      'taxType': taxType.name,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'shippingAmount': shippingAmount,
      'otherCharges': otherCharges,
      'grandTotal': grandTotal,
      'total': grandTotal, // for backwards compatibility
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
      'convertedToProject': convertedToProject,
      'projectId': projectId,
      'isArchived': isArchived,
      'pdfUrl': pdfUrl,
      'pdfStoragePath': pdfStoragePath,
      'pdfGeneratedAt': pdfGeneratedAt != null ? Timestamp.fromDate(pdfGeneratedAt!) : null,
      'pdfVersion': pdfVersion,
      'searchTokens': searchTokens.isNotEmpty ? searchTokens : buildSearchTokens(),
    };
  }

  List<String> buildSearchTokens() {
    final tokens = <String>{};

    void addTokens(String text) {
      final clean = text.toLowerCase().trim();
      if (clean.isEmpty) return;
      tokens.add(clean);
      final words = clean.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length >= 2) {
          tokens.add(word);
          for (int i = 2; i <= word.length; i++) {
            tokens.add(word.substring(0, i));
          }
        }
      }
    }

    addTokens(quotationNumber);
    addTokens(companyName);
    addTokens(contactPerson);
    addTokens(clientName);
    addTokens(title);

    return tokens.toList();
  }

  QuotationModel copyWith({
    String? id,
    String? quotationNumber,
    int? revisionNumber,
    String? parentQuotationId,
    String? clientId,
    String? clientName,
    String? companyName,
    String? contactPerson,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? sourceLeadId,
    String? title,
    String? description,
    QuotationStatus? status,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? currency,
    List<QuotationItemModel>? items,
    double? subtotal,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    TaxType? taxType,
    double? taxPercentage,
    double? taxAmount,
    double? shippingAmount,
    double? otherCharges,
    double? grandTotal,
    String? notes,
    String? termsAndConditions,
    String? assignedTo,
    String? assignedToName,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? viewedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    bool? convertedToProject,
    String? projectId,
    bool? isArchived,
    String? pdfUrl,
    String? pdfStoragePath,
    DateTime? pdfGeneratedAt,
    int? pdfVersion,
    List<String>? searchTokens,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      revisionNumber: revisionNumber ?? this.revisionNumber,
      parentQuotationId: parentQuotationId ?? this.parentQuotationId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxType: taxType ?? this.taxType,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      otherCharges: otherCharges ?? this.otherCharges,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      convertedToProject: convertedToProject ?? this.convertedToProject,
      projectId: projectId ?? this.projectId,
      isArchived: isArchived ?? this.isArchived,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      pdfGeneratedAt: pdfGeneratedAt ?? this.pdfGeneratedAt,
      pdfVersion: pdfVersion ?? this.pdfVersion,
      searchTokens: searchTokens ?? this.searchTokens,
    );
  }

  @override
  List<Object?> get props => [
        id,
        quotationNumber,
        revisionNumber,
        clientId,
        status,
        grandTotal,
        updatedAt,
        convertedToProject,
        isArchived,
      ];
}
