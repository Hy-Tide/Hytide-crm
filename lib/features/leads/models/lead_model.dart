// lib/features/leads/models/lead_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class LeadModel extends Equatable {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String alternatePhone;
  final String email;
  final String website;
  final String address;
  final String city;
  final String state;
  final String country;
  final String industry;
  final String jobTitle;
  final LeadSource leadSource;
  final LeadStatus status;
  final LeadPriority priority;
  final String assignedTo; // uid
  final String assignedToName;
  final double estimatedValue;
  final DateTime? expectedClosingDate;
  final String description;
  final String notes;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastContactedAt;
  final DateTime? nextFollowUpAt;
  final bool isArchived;
  final bool convertedToClient;
  final String? clientId;
  final String? lostReason;
  final int probability;

  // Backward compatibility & convenience getters
  LeadSource get source => leadSource;
  bool get isConverted => convertedToClient;
  String get currency => 'INR';
  DateTime? get nextFollowUpDate => nextFollowUpAt;
  DateTime? get expectedCloseDate => expectedClosingDate;
  String get assignedToUserId => assignedTo;
  String get requirements => description;
  List<String> get tags => const [];
  String get whatsappNumber => alternatePhone;
  String get postalCode => '';
  String get createdByUserId => createdBy;

  const LeadModel({
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
    this.country = '',
    this.industry = '',
    this.jobTitle = '',
    required this.leadSource,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.assignedToName,
    this.estimatedValue = 0,
    this.expectedClosingDate,
    this.description = '',
    this.notes = '',
    required this.createdBy,
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
    this.lastContactedAt,
    this.nextFollowUpAt,
    this.isArchived = false,
    this.convertedToClient = false,
    this.clientId,
    this.lostReason,
    this.probability = 0,
  });

  factory LeadModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawSource = data['leadSource'] as String? ?? data['source'] as String? ?? 'website';
    final rawConverted = data['convertedToClient'] as bool? ?? data['isConverted'] as bool? ?? false;

    return LeadModel(
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
      country: data['country'] as String? ?? '',
      industry: data['industry'] as String? ?? '',
      jobTitle: data['jobTitle'] as String? ?? '',
      leadSource: LeadSource.fromString(rawSource),
      status: LeadStatus.fromString(data['status'] as String? ?? 'newLead'),
      priority: LeadPriority.fromString(data['priority'] as String? ?? 'medium'),
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      estimatedValue: (data['estimatedValue'] as num?)?.toDouble() ?? 0.0,
      expectedClosingDate: (data['expectedClosingDate'] as Timestamp?)?.toDate(),
      description: data['description'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastContactedAt: (data['lastContactedAt'] as Timestamp?)?.toDate(),
      nextFollowUpAt: (data['nextFollowUpAt'] as Timestamp?)?.toDate(),
      isArchived: data['isArchived'] as bool? ?? false,
      convertedToClient: rawConverted,
      clientId: data['clientId'] as String?,
      lostReason: data['lostReason'] as String?,
      probability: (data['probability'] as num?)?.toInt() ?? 0,
    );
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
      'industry': industry,
      'jobTitle': jobTitle,
      'leadSource': leadSource.name,
      'source': leadSource.name, // compatibility
      'status': status.name,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'estimatedValue': estimatedValue,
      'expectedClosingDate': expectedClosingDate != null
          ? Timestamp.fromDate(expectedClosingDate!)
          : null,
      'description': description,
      'notes': notes,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastContactedAt': lastContactedAt != null
          ? Timestamp.fromDate(lastContactedAt!)
          : null,
      'nextFollowUpAt': nextFollowUpAt != null
          ? Timestamp.fromDate(nextFollowUpAt!)
          : null,
      'isArchived': isArchived,
      'convertedToClient': convertedToClient,
      'isConverted': convertedToClient, // compatibility
      'clientId': clientId,
      'lostReason': lostReason,
      'probability': probability,
      // Search index tokens (lowercase)
      'searchTokens': _buildSearchTokens(),
    };
  }

  List<String> _buildSearchTokens() {
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
    addTokens(jobTitle);
    addTokens(industry);
    addTokens(phone);
    addTokens(alternatePhone);
    addTokens(email);
    addTokens(website);
    return tokens.toList();
  }

  LeadModel copyWith({
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
    String? industry,
    String? jobTitle,
    LeadSource? leadSource,
    LeadStatus? status,
    LeadPriority? priority,
    String? assignedTo,
    String? assignedToName,
    double? estimatedValue,
    DateTime? expectedClosingDate,
    String? description,
    String? notes,
    String? createdByName,
    DateTime? updatedAt,
    DateTime? lastContactedAt,
    DateTime? nextFollowUpAt,
    bool? isArchived,
    bool? convertedToClient,
    String? clientId,
    String? lostReason,
    int? probability,
  }) {
    return LeadModel(
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
      industry: industry ?? this.industry,
      jobTitle: jobTitle ?? this.jobTitle,
      leadSource: leadSource ?? this.leadSource,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      expectedClosingDate: expectedClosingDate ?? this.expectedClosingDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      isArchived: isArchived ?? this.isArchived,
      convertedToClient: convertedToClient ?? this.convertedToClient,
      clientId: clientId ?? this.clientId,
      lostReason: lostReason ?? this.lostReason,
      probability: probability ?? this.probability,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        contactPerson,
        phone,
        email,
        leadSource,
        status,
        priority,
        assignedTo,
        estimatedValue,
        expectedClosingDate,
        isArchived,
        convertedToClient,
        updatedAt,
        probability,
      ];
}
