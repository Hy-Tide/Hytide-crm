// lib/core/widgets/app_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import 'app_search_field.dart';
import 'user_avatar.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onOpenDrawer;
  final bool showDrawerButton;

  const AppTopBar({
    super.key,
    required this.title,
    this.onOpenDrawer,
    this.showDrawerButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final displayName = user?.displayName ?? 'Admin User';
    final email = user?.email ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder;
    final iconColor = isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Drawer Button (mobile/tablet)
                if (showDrawerButton) ...[
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: iconColor, size: 22),
                    onPressed: onOpenDrawer,
                    tooltip: 'Open menu',
                    visualDensity: VisualDensity.compact,
                  ),
                  AppSpacing.gapW8,
                ],

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Search Field (Desktop only)
                if (isDesktop) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: AppSearchField(
                      hintText: 'Search leads, clients...',
                      onChanged: (query) {
                        if (query.trim().length >= 2) {
                          context.go('${AppRoutes.leads}?search=${Uri.encodeComponent(query.trim())}');
                        }
                      },
                    ),
                  ),
                  AppSpacing.gapW12,
                ],

                // Theme Toggle
                IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 19,
                    color: iconColor,
                  ),
                  tooltip: themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                  visualDensity: VisualDensity.compact,
                ),

                // Notification Icon with unread badge
                Consumer(
                  builder: (context, ref, _) {
                    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
                    final unreadCount = unreadCountAsync.value ?? 0;

                    return Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: AppColors.error,
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          size: 19,
                          color: iconColor,
                        ),
                        tooltip: 'Notifications',
                        onPressed: () => context.go(AppRoutes.notifications),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),

                AppSpacing.gapW4,

                // User Avatar + popup menu
                _UserMenuButton(
                  displayName: displayName,
                  email: email,
                  showName: !isMobile,
                  isDark: isDark,
                  iconColor: iconColor,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMenuButton extends ConsumerWidget {
  final String displayName;
  final String email;
  final bool showName;
  final bool isDark;
  final Color iconColor;
  final Color textColor;

  const _UserMenuButton({
    required this.displayName,
    required this.email,
    required this.showName,
    required this.isDark,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Account menu',
      offset: const Offset(0, 44),
      onSelected: (value) async {
        switch (value) {
          case 'settings':
            context.go(AppRoutes.settings);
            break;
          case 'logout':
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) context.go(AppRoutes.login);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'settings',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Text(
                'Settings',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 10),
              Text(
                'Sign out',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(name: displayName, size: 30),
              if (showName) ...[
                AppSpacing.gapW8,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    displayName,
                    style: AppTypography.labelMedium.copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 16, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
