// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  DocumentReference<Map<String, dynamic>> doc(
    String collectionPath,
    String docId,
  ) {
    return _db.collection(collectionPath).doc(docId);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    String collectionPath,
    String docId,
  ) {
    return _db.collection(collectionPath).doc(docId).get();
  }

  Future<void> setDoc(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return _db
        .collection(collectionPath)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  Future<DocumentReference<Map<String, dynamic>>> addDoc(
    String collectionPath,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collectionPath).add(data);
  }

  Future<void> updateDoc(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collectionPath).doc(docId).update(data);
  }

  Future<void> deleteDoc(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collectionPath,
  ) {
    return _db.collection(collectionPath).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(
    String collectionPath,
    String docId,
  ) {
    return _db.collection(collectionPath).doc(docId).snapshots();
  }

  Timestamp get now => Timestamp.now();

  static Map<String, dynamic> withTimestamps(
    Map<String, dynamic> data, {
    bool isCreate = true,
  }) {
    final now = Timestamp.now();
    final result = Map<String, dynamic>.from(data);
    if (isCreate) {
      result['createdAt'] = now;
    }
    result['updatedAt'] = now;
    return result;
  }
}
