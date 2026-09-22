// lib/features/notifications/providers/notification_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationTabFilter {
  all,
  unread;

  String get displayName => this == all ? 'All' : 'Unread';
}

final notificationTabFilterProvider =
    StateProvider<NotificationTabFilter>((ref) => NotificationTabFilter.all);
