// lib/features/notifications/screens/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/notification_model.dart';
import '../providers/notification_providers.dart';
import '../repositories/notification_repository.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTab = ref.watch(notificationTabFilterProvider);
    final notificationsAsync = ref.watch(
      notificationListStreamProvider(activeTab == NotificationTabFilter.unread),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark All as Read'),
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Filter Tab Segmented Control (All / Unread)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      SegmentedButton<NotificationTabFilter>(
                        segments: const [
                          ButtonSegment(
                            value: NotificationTabFilter.all,
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: NotificationTabFilter.unread,
                            label: Text('Unread'),
                          ),
                        ],
                        selected: {activeTab},
                        onSelectionChanged: (set) {
                          ref.read(notificationTabFilterProvider.notifier).state =
                              set.first;
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Notifications List
                Expanded(
                  child: notificationsAsync.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 56,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                activeTab == NotificationTabFilter.unread
                                    ? 'No unread notifications'
                                    : 'No notifications yet',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'You will be alerted about due follow-ups and lead updates here.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _NotificationCard(notification: notif);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  IconData _getIcon(String type) {
    switch (type) {
      case 'follow_up_reminder':
        return Icons.alarm_rounded;
      case 'follow_up_completed':
        return Icons.check_circle_rounded;
      case 'follow_up_rescheduled':
        return Icons.event_repeat_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'follow_up_reminder':
        return AppColors.warning;
      case 'follow_up_completed':
        return AppColors.success;
      case 'follow_up_rescheduled':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = _getColor(notification.type);

    return Card(
      elevation: 0,
      color: notification.isRead
          ? theme.colorScheme.surface
          : theme.colorScheme.primaryContainer.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? theme.colorScheme.outlineVariant.withOpacity(0.5)
              : theme.colorScheme.primary.withOpacity(0.3),
          width: notification.isRead ? 1.0 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          }
          // Navigate to follow-up details if available
          if (notification.followUpId != null &&
              notification.followUpId!.isNotEmpty) {
            context.push('/followups/${notification.followUpId}');
          } else if (notification.leadId != null &&
              notification.leadId!.isNotEmpty) {
            context.push('/leads/${notification.leadId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(notification.type), color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          notification.formattedCreatedAt,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  tooltip: 'Mark as read',
                  onPressed: () {
                    ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(notification.id);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
