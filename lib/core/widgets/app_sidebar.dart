// lib/core/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/repositories/auth_repository.dart';
import 'app_logo.dart';
import 'user_avatar.dart';

class AppSidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const AppSidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class AppSidebarGroup {
  final String label;
  final List<AppSidebarItem> items;

  const AppSidebarGroup({required this.label, required this.items});
}

class AppSidebar extends ConsumerWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onCloseDrawer;

  const AppSidebar({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onCloseDrawer,
  });

  static const List<AppSidebarGroup> navGroups = [
    AppSidebarGroup(
      label: 'OVERVIEW',
      items: [
        AppSidebarItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
          route: AppRoutes.dashboard,
        ),
      ],
    ),
    AppSidebarGroup(
      label: 'SALES',
      items: [
        AppSidebarItem(
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          label: 'Leads',
          route: AppRoutes.leads,
        ),
        AppSidebarItem(
          icon: Icons.schedule_outlined,
          activeIcon: Icons.schedule_rounded,
          label: 'Follow-ups',
          route: AppRoutes.followups,
        ),
        AppSidebarItem(
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          label: 'Clients',
          route: AppRoutes.clients,
        ),
        AppSidebarItem(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Quotations',
          route: AppRoutes.quotations,
        ),
      ],
    ),
    AppSidebarGroup(
      label: 'DELIVERY',
      items: [
        AppSidebarItem(
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder_rounded,
          label: 'Projects',
          route: AppRoutes.projects,
        ),
        AppSidebarItem(
          icon: Icons.attach_file_outlined,
          activeIcon: Icons.attach_file_rounded,
          label: 'Documents',
          route: AppRoutes.documents,
        ),
      ],
    ),
    AppSidebarGroup(
      label: 'MANAGEMENT',
      items: [
        AppSidebarItem(
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications_rounded,
          label: 'Notifications',
          route: AppRoutes.notifications,
        ),
        AppSidebarItem(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          label: 'Reports',
          route: AppRoutes.reports,
        ),
        AppSidebarItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          label: 'Users',
          route: AppRoutes.users,
        ),
        AppSidebarItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: 'Expenses',
          route: AppRoutes.expenses,
        ),
        AppSidebarItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          label: 'Settings',
          route: AppRoutes.settings,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.asData?.value;
    final currentRoute = GoRouterState.of(context).uri.path;
    final width = isCollapsed ? 72.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.sidebarDivider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & App Name Header
          _buildHeader(context),
          const Divider(color: AppColors.sidebarDivider, height: 1),

          // Navigation Links (Scrollable)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                for (int g = 0; g < navGroups.length; g++) ...[
                  if (g > 0) const SizedBox(height: 4),
                  _buildGroupSection(context, navGroups[g], currentRoute),
                ],
              ],
            ),
          ),

          // Bottom User Profile & Logout
          const Divider(color: AppColors.sidebarDivider, height: 1),
          _buildBottomProfile(context, ref, user),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
    BuildContext context,
    AppSidebarGroup group,
    String currentRoute,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed) ...[
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 12, bottom: 4),
            child: Text(
              group.label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.sidebarItemText.withValues(alpha: 0.6),
                letterSpacing: 1.0,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ] else
          const SizedBox(height: 12),
        for (final item in group.items)
          _buildNavItem(context, item, currentRoute: currentRoute),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          // Logo mark
          const AppLogo.icon(
            size: 34,
            transparent: true,
          ),
          if (!isCollapsed) ...[
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hytide',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'CRM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.sidebarItemText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onCloseDrawer != null)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.sidebarItemText,
                size: 18,
              ),
              onPressed: onCloseDrawer,
              visualDensity: VisualDensity.compact,
            )
          else if (onToggleCollapse != null && !isCollapsed)
            IconButton(
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.sidebarItemText,
                size: 20,
              ),
              onPressed: onToggleCollapse,
              tooltip: 'Collapse sidebar',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AppSidebarItem item, {
    required String currentRoute,
  }) {
    final isActive =
        currentRoute == item.route ||
        (item.route != AppRoutes.dashboard &&
            currentRoute.startsWith(item.route));

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.sidebarItemActive.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.transparent),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onCloseDrawer?.call();
              if (currentRoute != item.route) {
                context.go(item.route);
              }
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: isActive
                ? Colors.transparent
                : AppColors.sidebarItemHover,
            splashColor: AppColors.sidebarItemActive.withValues(alpha: 0.3),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 0 : 10,
                vertical: 9,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 19,
                    color: isActive ? Colors.white : AppColors.sidebarItemText,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.sidebarItemText,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Active indicator dot
                    if (isActive)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: item.label, preferBelow: false, child: tile);
    }

    return tile;
  }

  Widget _buildBottomProfile(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
  ) {
    final displayName = (user != null && user.displayName.isNotEmpty)
        ? user.displayName
        : 'Admin User';
    final email = user?.email ?? '';
    final role = user?.role.displayName ?? 'Admin';

    return Container(
      padding: const EdgeInsets.all(10),
      child: isCollapsed
          ? _buildCollapsedProfile(context, ref, displayName)
          : _buildExpandedProfile(context, ref, displayName, email, role),
    );
  }

  Widget _buildCollapsedProfile(
    BuildContext context,
    WidgetRef ref,
    String displayName,
  ) {
    return Column(
      children: [
        Tooltip(
          message: displayName,
          child: UserAvatar(name: displayName, size: 36),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: 'Logout',
          child: IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.sidebarItemText,
              size: 18,
            ),
            onPressed: () => _handleLogout(context, ref),
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (onToggleCollapse != null) ...[
          const SizedBox(height: 4),
          Tooltip(
            message: 'Expand sidebar',
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.sidebarItemText,
                size: 18,
              ),
              onPressed: onToggleCollapse,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedProfile(
    BuildContext context,
    WidgetRef ref,
    String displayName,
    String email,
    String role,
  ) {
    return Row(
      children: [
        UserAvatar(name: displayName, size: 36),
        AppSpacing.gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                role.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.sidebarItemText,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.sidebarItemText,
            size: 18,
          ),
          tooltip: 'Logout',
          onPressed: () => _handleLogout(context, ref),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}
