// lib/features/clients/services/lead_conversion_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../leads/models/lead_model.dart';
import '../models/client_activity_model.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';

class ConversionEligibilityResult {
  final bool isEligible;
  final String? message;
  final String? existingClientId;

  const ConversionEligibilityResult({
    required this.isEligible,
    this.message,
    this.existingClientId,
  });
}

class LeadConversionService {
  final FirebaseFirestore? _db;
  final ClientRepository? _clientRepo;
  final String? currentUserId;
  final String currentUserName;

  LeadConversionService({
    FirebaseFirestore? db,
    ClientRepository? clientRepo,
    required this.currentUserId,
    required this.currentUserName,
  })  : _db = db,
        _clientRepo = clientRepo;

  CollectionReference<Map<String, dynamic>> get _leads =>
      _db!.collection(AppCollections.leads);

  CollectionReference<Map<String, dynamic>> get _clients =>
      _db!.collection(AppCollections.clients);

  CollectionReference<Map<String, dynamic>> get _followups =>
      _db!.collection(AppCollections.followups);

  CollectionReference<Map<String, dynamic>> get _globalActivities =>
      _db!.collection(AppCollections.activities);

  /// Check whether lead is eligible for conversion
  ConversionEligibilityResult checkEligibility(LeadModel lead) {
    if (lead.convertedToClient && lead.clientId != null && lead.clientId!.isNotEmpty) {
      return ConversionEligibilityResult(
        isEligible: false,
        message: 'This lead has already been converted into a client.',
        existingClientId: lead.clientId,
      );
    }

    if (lead.status != LeadStatus.won) {
      return const ConversionEligibilityResult(
        isEligible: false,
        message:
            'This lead is not ready for conversion.\n\nMark the lead as Won before converting it to a client.',
      );
    }

    return const ConversionEligibilityResult(isEligible: true);
  }

  /// Check if a client with matching phone or email already exists
  Future<ClientModel?> checkForDuplicate({
    String? phone,
    String? email,
    String? companyName,
  }) async {
    return _clientRepo!.checkDuplicateClient(
      phone: phone,
      email: email,
      companyName: companyName,
    );
  }

  /// Execute atomic conversion using Firestore transaction
  Future<String> convertLeadToClient({
    required LeadModel lead,
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
    String notes = '',
    String? convertedByUid,
    String? convertedByName,
  }) async {
    final authorUid = convertedByUid ?? currentUserId ?? '';
    final authorName = convertedByName ?? (currentUserName.isNotEmpty ? currentUserName : 'Admin');
    final now = DateTime.now();

    final leadRef = _leads.doc(lead.id);
    final clientRef = _clients.doc();
    final newClientId = clientRef.id;

    // 1. Transaction to guarantee atomic conversion and prevent duplicate conversions
    await _db!.runTransaction((tx) async {
      final leadSnap = await tx.get(leadRef);
      if (!leadSnap.exists) {
        throw Exception('Lead not found');
      }

      final leadData = leadSnap.data()!;
      final alreadyConverted =
          leadData['convertedToClient'] as bool? ?? leadData['isConverted'] as bool? ?? false;

      if (alreadyConverted) {
        final existingId = leadData['clientId'] as String?;
        if (existingId != null && existingId.isNotEmpty) {
          throw Exception('Lead has already been converted to client (ID: $existingId)');
        }
        throw Exception('Lead has already been converted to a client.');
      }

      // Prepare client document
      final clientModel = ClientModel(
        id: newClientId,
        companyName: companyName.trim(),
        contactPerson: contactPerson.trim(),
        phone: phone.trim(),
        alternatePhone: alternatePhone.trim(),
        email: email.trim(),
        website: website.trim(),
        address: address.trim(),
        city: city.trim(),
        state: state.trim(),
        country: country.trim(),
        pincode: pincode.trim(),
        industry: industry.trim(),
        clientType: clientType,
        status: ClientStatus.active,
        priority: priority,
        sourceLeadId: lead.id,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        createdBy: authorUid,
        createdByName: authorName,
        clientSince: now,
        createdAt: now,
        updatedAt: now,
        notes: notes.trim(),
        isArchived: false,
      );

      // A. Create client doc
      tx.set(clientRef, clientModel.toMap());

      // B. Update lead doc
      tx.update(leadRef, {
        'convertedToClient': true,
        'isConverted': true,
        'clientId': newClientId,
        'status': LeadStatus.won.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // 2. Post-transaction operations: Audit activities and follow-up linking

    // A. Log in lead activities
    try {
      final leadActivityRef = leadRef.collection('activities').doc();
      await leadActivityRef.set({
        'type': 'converted_to_client',
        'title': 'Lead converted to client',
        'description': 'Onboarded $companyName as a client',
        'createdBy': authorUid,
        'createdByName': authorName,
        'createdAt': Timestamp.fromDate(now),
        'metadata': {
          'clientId': newClientId,
          'convertedAt': now.toIso8601String(),
        },
      });
    } catch (_) {}

    // B. Log in client activities
    try {
      final clientActivity = ClientActivityModel(
        id: '',
        type: 'client_created_from_lead',
        title: 'Client created from lead',
        description: 'Converted from lead "${lead.companyName}"',
        createdBy: authorUid,
        createdByName: authorName,
        createdAt: now,
        metadata: {
          'sourceLeadId': lead.id,
          'convertedAt': now.toIso8601String(),
        },
      );
      await _clientRepo!.addClientActivity(newClientId, clientActivity);
    } catch (_) {}

    // C. Log in global activities
    try {
      await _globalActivities.add({
        'type': ActivityType.convertedToClient.name,
        'description': '$companyName converted from lead to client',
        'userName': authorName,
        'timestamp': Timestamp.fromDate(now),
        'entityId': newClientId,
        'entityType': 'client',
        'createdAt': Timestamp.fromDate(now),
      });
    } catch (_) {}

    // D. Link pending follow-ups of this lead to the new clientId safely
    try {
      final pendingFollowups = await _followups
          .where('leadId', isEqualTo: lead.id)
          .where('status', isEqualTo: FollowUpStatus.pending.name)
          .get();

      for (final doc in pendingFollowups.docs) {
        await doc.reference.update({
          'clientId': newClientId,
          'clientName': companyName,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } catch (_) {}

    return newClientId;
  }
}

final leadConversionServiceProvider = Provider<LeadConversionService>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final clientRepo = ref.watch(clientRepositoryProvider);
  return LeadConversionService(
    db: FirebaseFirestore.instance,
    clientRepo: clientRepo,
    currentUserId: auth.currentUserId,
    currentUserName: auth.currentUser?.displayName ?? '',
  );
});
