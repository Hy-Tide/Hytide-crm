import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final FirebaseFirestore _db;
  DocumentRepository({required FirebaseFirestore db}) : _db = db;

  CollectionReference<Map<String, dynamic>> get _docs => _db.collection(AppCollections.documents);

  Stream<List<DocumentModel>> streamDocuments({
    String? leadId,
    String? clientId,
    String? projectId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q = _docs;
    if (leadId != null) {
      q = q.where('leadId', isEqualTo: leadId);
    } else if (clientId != null) {
      q = q.where('clientId', isEqualTo: clientId);
    } else if (projectId != null) {
      q = q.where('projectId', isEqualTo: projectId);
    }
    q = q.orderBy('uploadedAt', descending: true);
    return q.limit(limit).snapshots().map((s) => s.docs.map(DocumentModel.fromFirestore).toList());
  }

  Future<String> addDocument(DocumentModel doc) async {
    final ref = await _docs.add(doc.toMap());
    return ref.id;
  }

  Future<void> deleteDocument(String id) async => await _docs.doc(id).delete();
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) => DocumentRepository(db: FirebaseFirestore.instance));
final documentsStreamProvider = StreamProvider<List<DocumentModel>>((ref) => ref.watch(documentRepositoryProvider).streamDocuments());

final documentsByLeadProvider = StreamProvider.family<List<DocumentModel>, String>((ref, leadId) {
  return ref.watch(documentRepositoryProvider).streamDocuments(leadId: leadId);
});

final documentsByClientProvider = StreamProvider.family<List<DocumentModel>, String>((ref, clientId) {
  return ref.watch(documentRepositoryProvider).streamDocuments(clientId: clientId);
});

final documentsByProjectProvider = StreamProvider.family<List<DocumentModel>, String>((ref, projectId) {
  return ref.watch(documentRepositoryProvider).streamDocuments(projectId: projectId);
});
