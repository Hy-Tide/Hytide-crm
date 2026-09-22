// lib/core/platform/widgets/android_more_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/notifications/repositories/notification_repository.dart';
import '../../constants/app_constants.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/user_avatar.dart';

class AndroidMoreSheet extends ConsumerWidget {
  const AndroidMoreSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AndroidMoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // User Profile Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceBorderSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      photoUrl: user?.photoURL,
                      name: user?.displayName ?? 'User',
                      size: 48,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'CRM Member',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.onSurfaceDark
                                  : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              user?.role.displayName.toUpperCase() ?? 'STAFF',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),

            // Module Grid
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // 3-column grid of module icons
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.9,
                    children: [
                      _ModuleGridItem(
                        icon: Icons.business_rounded,
                        color: const Color(0xFF0284C7),
                        label: 'Clients',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.clients);
                        },
                      ),
                      _ModuleGridItem(
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF10B981),
                        label: 'Quotations',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.quotations);
                        },
                      ),
                      _ModuleGridItem(
                        icon: Icons.notifications_rounded,
                        color: const Color(0xFFF59E0B),
                        label: 'Notifications',
                        badge: unreadCount > 0 ? '$unreadCount' : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.notifications);
                        },
                      ),
                      _ModuleGridItem(
                        icon: Icons.description_rounded,
                        color: const Color(0xFF6366F1),
                        label: 'Documents',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.documents);
                        },
                      ),
                      _ModuleGridItem(
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFF8B5CF6),
                        label: 'Reports',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.reports);
                        },
                      ),
                      if (user?.role == UserRole.admin ||
                          (user?.isSuperAdmin ?? false))
                        _ModuleGridItem(
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFFEC4899),
                          label: 'Team',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRoutes.users);
                          },
                        ),
                      _ModuleGridItem(
                        icon: Icons.settings_rounded,
                        color: const Color(0xFF64748B),
                        label: 'Settings',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.settings);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),

                  // Theme Toggle
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.amber : Colors.blueGrey)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark ? Colors.amber : Colors.blueGrey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Dark Appearance',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (val) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setTheme(val ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ),

                  // Sign Out
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sign Out',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Sign Out',
                        message:
                            'Are you sure you want to sign out of Hytide CRM?',
                        confirmLabel: 'Sign Out',
                        isDestructive: true,
                      );
                      if (confirmed == true && context.mounted) {
                        Navigator.of(context).pop();
                        final uid = ref
                            .read(authRepositoryProvider)
                            .currentUser
                            ?.uid;
                        if (uid != null) {
                          await NotificationService().deactivateDevice(uid);
                        }
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGridItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ModuleGridItem({
    required this.icon,
    required this.color,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
