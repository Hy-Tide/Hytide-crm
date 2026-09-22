// lib/features/auth/repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/error_handler.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthService _authService;
  final FirebaseFirestore _db;

  AuthRepository(this._authService, this._db);

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;
  String? get currentUserId => _authService.currentUserId;

  Future<UserModel?> getCurrentUserModel() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final doc = await _db.collection(AppCollections.users).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> streamCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    return _db
        .collection(AppCollections.users)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Sign in with email and password, then validate that the user has admin role and is active.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user?.uid;
    if (uid == null) {
      throw const AuthRoleException('Authentication failed. Please try again.');
    }

    // Read users/{uid} document from Firestore
    final doc = await _db.collection(AppCollections.users).doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      await _authService.signOut();
      throw const AuthRoleException('Access denied. Admin access is required.');
    }

    final data = doc.data()!;
    final role = (data['role'] as String? ?? '').toLowerCase();
    final isActive = data['isActive'] as bool? ?? false;

    // Role validation: Admin required
    if (role != 'admin') {
      await _authService.signOut();
      throw const AuthRoleException('Access denied. Admin access is required.');
    }

    // Active validation
    if (!isActive) {
      await _authService.signOut();
      throw const AuthInactiveException('Your account is currently inactive. Please contact an administrator.');
    }

    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _authService.sendPasswordResetEmail(email);

  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection(AppCollections.users).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<UserCredential> createUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) {
    final callerEmail = _authService.currentUser?.email?.trim().toLowerCase();
    if (callerEmail != AppAuthConstants.superAdminEmail.toLowerCase()) {
      throw Exception('Only the primary administrator (${AppAuthConstants.superAdminEmail}) is authorized to create users.');
    }
    return _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
    );
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    final doc = await _db.collection(AppCollections.users).doc(uid).get();
    if (doc.exists) {
      final targetEmail = (doc.data()?['email'] as String? ?? '').trim().toLowerCase();
      if (targetEmail == AppAuthConstants.superAdminEmail.toLowerCase()) {
        throw Exception('The primary administrator account role cannot be changed.');
      }
    }
    await _db.collection(AppCollections.users).doc(uid).update({
      'role': role.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> toggleUserStatus(String uid, bool isActive) async {
    final doc = await _db.collection(AppCollections.users).doc(uid).get();
    if (doc.exists) {
      final targetEmail = (doc.data()?['email'] as String? ?? '').trim().toLowerCase();
      if (targetEmail == AppAuthConstants.superAdminEmail.toLowerCase()) {
        throw Exception('The primary administrator account cannot be deactivated.');
      }
    }
    await _db.collection(AppCollections.users).doc(uid).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authServiceProvider),
    FirebaseFirestore.instance,
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.asData?.value == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).streamCurrentUser();
});

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserModelProvider).asData?.value;
  return user?.role ?? UserRole.salesStaff;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserModelProvider).asData?.value;
  return user != null && user.role == UserRole.admin && user.isActive;
});

final isSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserModelProvider).asData?.value;
  return user != null && user.isSuperAdmin && user.isActive;
});

