// lib/features/notifications/repositories/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db;
  final String? currentUserId;

  NotificationRepository({
    required FirebaseFirestore db,
    required this.currentUserId,
  }) : _db = db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(AppCollections.notifications);

  /// Streams notifications for current authenticated user
  Stream<List<NotificationModel>> streamNotifications({
    bool? unreadOnly,
    int limit = 50,
  }) {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query = _notifications
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true);

    if (unreadOnly == true) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.limit(limit).snapshots().map((snap) {
      return snap.docs.map(NotificationModel.fromFirestore).toList();
    }).handleError((_) => <NotificationModel>[]);
  }

  /// Streams the count of unread notifications for badge display
  Stream<int> streamUnreadCount() {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return Stream.value(0);
    }

    return _notifications
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((_) => 0);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _notifications.doc(id).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Mark all notifications for the user as read in batch
  Future<void> markAllAsRead() async {
    if (currentUserId == null || currentUserId!.isEmpty) return;

    try {
      final snap = await _notifications
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Creates an in-app notification doc
  Future<String> createNotification(NotificationModel notification) async {
    final ref = await _notifications.add(notification.toMap());
    return ref.id;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return NotificationRepository(
    db: FirebaseFirestore.instance,
    currentUserId: authRepo.currentUserId,
  );
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationRepositoryProvider).streamUnreadCount();
});

final notificationListStreamProvider =
    StreamProvider.family<List<NotificationModel>, bool?>((ref, unreadOnly) {
  return ref
      .watch(notificationRepositoryProvider)
      .streamNotifications(unreadOnly: unreadOnly);
});
