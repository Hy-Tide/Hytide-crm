// lib/features/clients/models/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class ClientModel extends Equatable {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String alternatePhone;
  final String email;
  final String website;

  // Address
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  // Classification
  final String industry;
  final ClientType clientType;
  final ClientStatus status;
  final ClientPriority priority;

  // Relationship to Lead
  final String? sourceLeadId;

  // Assignment & Ownership
  final String assignedTo;
  final String assignedToName;
  final String createdBy;
  final String createdByName;

  // Timestamps
  final DateTime clientSince;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastContactedAt;
  final DateTime? nextFollowUpAt;

  // Financial aggregates
  final double totalQuotationValue;
  final double totalProjectValue;
  final double totalPaidAmount;

  // Notes & Archival
  final String notes;
  final bool isArchived;

  // Search tokens
  final List<String> searchTokens;

  const ClientModel({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    this.alternatePhone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = 'India',
    this.pincode = '',
    this.industry = '',
    this.clientType = ClientType.newClient,
    this.status = ClientStatus.active,
    this.priority = ClientPriority.medium,
    this.sourceLeadId,
    required this.assignedTo,
    required this.assignedToName,
    this.createdBy = '',
    this.createdByName = '',
    required this.clientSince,
    required this.createdAt,
    required this.updatedAt,
    this.lastContactedAt,
    this.nextFollowUpAt,
    this.totalQuotationValue = 0.0,
    this.totalProjectValue = 0.0,
    this.totalPaidAmount = 0.0,
    this.notes = '',
    this.isArchived = false,
    this.searchTokens = const [],
  });

  /// Backward compatibility getter for `leadId`
  String? get leadId => sourceLeadId;

  /// Helper getter for formatted address
  String get formattedAddress {
    final parts = [address, city, state, country, pincode]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Check if follow-up is pending
  bool get hasFollowUp => nextFollowUpAt != null;

  factory ClientModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseTimestamp(dynamic field, [DateTime? fallback]) {
      if (field is Timestamp) return field.toDate();
      if (field is String) {
        final parsed = DateTime.tryParse(field);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableTimestamp(dynamic field) {
      if (field == null) return null;
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field);
      return null;
    }

    return ClientModel(
      id: doc.id,
      companyName: data['companyName'] as String? ?? '',
      contactPerson: data['contactPerson'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      alternatePhone: data['alternatePhone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      website: data['website'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      country: data['country'] as String? ?? 'India',
      pincode: data['pincode'] as String? ?? '',
      industry: data['industry'] as String? ?? '',
      clientType: ClientType.fromString(data['clientType'] as String? ?? 'newClient'),
      status: ClientStatus.fromString(data['status'] as String? ?? 'active'),
      priority: ClientPriority.fromString(data['priority'] as String? ?? 'medium'),
      sourceLeadId: data['sourceLeadId'] as String? ?? data['leadId'] as String?,
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      clientSince: parseTimestamp(data['clientSince']),
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      lastContactedAt: parseNullableTimestamp(data['lastContactedAt']),
      nextFollowUpAt: parseNullableTimestamp(data['nextFollowUpAt']),
      totalQuotationValue: (data['totalQuotationValue'] as num?)?.toDouble() ?? 0.0,
      totalProjectValue: (data['totalProjectValue'] as num?)?.toDouble() ?? 0.0,
      totalPaidAmount: (data['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String? ?? '',
      isArchived: data['isArchived'] as bool? ?? false,
      searchTokens: (data['searchTokens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Factory to convert from a Lead
  factory ClientModel.fromLead({
    required String id,
    required String companyName,
    required String contactPerson,
    required String phone,
    String alternatePhone = '',
    String email = '',
    String website = '',
    String address = '',
    String city = '',
    String state = '',
    String country = 'India',
    String pincode = '',
    String industry = '',
    ClientType clientType = ClientType.newClient,
    ClientPriority priority = ClientPriority.medium,
    required String assignedTo,
    required String assignedToName,
    String createdBy = '',
    String createdByName = '',
    String notes = '',
    required String leadId,
  }) {
    final now = DateTime.now();
    return ClientModel(
      id: id,
      companyName: companyName,
      contactPerson: contactPerson,
      phone: phone,
      alternatePhone: alternatePhone,
      email: email,
      website: website,
      address: address,
      city: city,
      state: state,
      country: country,
      pincode: pincode,
      industry: industry,
      clientType: clientType,
      status: ClientStatus.active,
      priority: priority,
      sourceLeadId: leadId,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      createdBy: createdBy,
      createdByName: createdByName,
      clientSince: now,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      isArchived: false,
    );
  }

  List<String> buildSearchTokens() {
    final tokens = <String>{};
    void addTokens(String text) {
      final clean = text.trim().toLowerCase();
      if (clean.isEmpty) return;
      tokens.add(clean);
      final words = clean.split(RegExp(r'[\s\-@.]+'));
      for (final w in words) {
        if (w.isNotEmpty) tokens.add(w);
      }
    }

    addTokens(companyName);
    addTokens(contactPerson);
    addTokens(phone);
    addTokens(alternatePhone);
    addTokens(email);
    addTokens(city);
    addTokens(industry);
    return tokens.toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'industry': industry,
      'clientType': clientType.name,
      'status': status.name,
      'priority': priority.name,
      'sourceLeadId': sourceLeadId,
      'leadId': sourceLeadId, // backward compatibility
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'clientSince': Timestamp.fromDate(clientSince),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastContactedAt != null)
        'lastContactedAt': Timestamp.fromDate(lastContactedAt!),
      if (nextFollowUpAt != null)
        'nextFollowUpAt': Timestamp.fromDate(nextFollowUpAt!),
      'totalQuotationValue': totalQuotationValue,
      'totalProjectValue': totalProjectValue,
      'totalPaidAmount': totalPaidAmount,
      'notes': notes,
      'isArchived': isArchived,
      'searchTokens': buildSearchTokens(),
    };
  }

  ClientModel copyWith({
    String? id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? alternatePhone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? industry,
    ClientType? clientType,
    ClientStatus? status,
    ClientPriority? priority,
    String? sourceLeadId,
    String? assignedTo,
    String? assignedToName,
    String? createdBy,
    String? createdByName,
    DateTime? clientSince,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastContactedAt,
    DateTime? nextFollowUpAt,
    double? totalQuotationValue,
    double? totalProjectValue,
    double? totalPaidAmount,
    String? notes,
    bool? isArchived,
    List<String>? searchTokens,
  }) {
    return ClientModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      industry: industry ?? this.industry,
      clientType: clientType ?? this.clientType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      clientSince: clientSince ?? this.clientSince,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      totalQuotationValue: totalQuotationValue ?? this.totalQuotationValue,
      totalProjectValue: totalProjectValue ?? this.totalProjectValue,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      searchTokens: searchTokens ?? this.searchTokens,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        contactPerson,
        phone,
        email,
        clientType,
        status,
        priority,
        sourceLeadId,
        assignedTo,
        isArchived,
      ];
}
