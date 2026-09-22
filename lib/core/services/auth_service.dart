// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);

    // Create user document in Firestore
    await _db.collection(AppCollections.users).doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email.trim(),
      'displayName': displayName.trim(),
      'role': role.name,
      'photoURL': null,
      'fcmToken': null,
      'isActive': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserRole> getCurrentUserRole() async {
    final uid = currentUserId;
    if (uid == null) return UserRole.salesStaff;

    final doc = await _db.collection(AppCollections.users).doc(uid).get();
    if (!doc.exists) return UserRole.salesStaff;

    final roleStr = doc.data()?['role'] as String? ?? 'salesStaff';
    return UserRole.fromString(roleStr);
  }

  Future<void> updateFCMToken(String token) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection(AppCollections.users).doc(uid).update({
      'fcmToken': token,
      'updatedAt': Timestamp.now(),
    });
  }
}
