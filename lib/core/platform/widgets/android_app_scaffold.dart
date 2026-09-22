// lib/core/platform/widgets/android_app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/notifications/repositories/notification_repository.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'android_foreground_banner.dart';
import 'android_notification_permission_dialog.dart';

class AndroidAppScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;

  const AndroidAppScaffold({super.key, required this.child, this.title});

  @override
  ConsumerState<AndroidAppScaffold> createState() => _AndroidAppScaffoldState();
}

class _AndroidAppScaffoldState extends ConsumerState<AndroidAppScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AndroidNotificationPermissionHelper.checkAndPromptPermission(context);
      }
    });
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  int _getBottomNavIndex(String route) {
    if (route == AppRoutes.dashboard) return 0;
    if (route == AppRoutes.leads || route.startsWith('${AppRoutes.leads}/')) return 1;
    if (route == AppRoutes.followups || route.startsWith('${AppRoutes.followups}/')) return 2;
    if (route == AppRoutes.projects || route.startsWith('${AppRoutes.projects}/')) return 3;
    if (route == AppRoutes.more ||
        route.startsWith(AppRoutes.clients) ||
        route.startsWith(AppRoutes.quotations) ||
        route.startsWith(AppRoutes.documents) ||
        route.startsWith(AppRoutes.notifications) ||
        route.startsWith(AppRoutes.reports) ||
        route.startsWith(AppRoutes.users) ||
        route.startsWith(AppRoutes.settings)) {
      return 4;
    }
    return 0;
  }

  String _deriveTitle(BuildContext context) {
    if (widget.title != null) return widget.title!;
    final route = GoRouterState.of(context).uri.path;
    if (route == AppRoutes.dashboard) return 'Hytide CRM';
    if (route == AppRoutes.leads) return 'Leads Management';
    if (route == AppRoutes.followups) return 'Follow-ups';
    if (route == AppRoutes.projects) return 'Projects';
    if (route == AppRoutes.more) return 'More';
    if (route.startsWith(AppRoutes.clients)) return 'Clients';
    if (route.startsWith(AppRoutes.quotations)) return 'Quotations';
    if (route.startsWith(AppRoutes.documents)) return 'Documents';
    if (route.startsWith(AppRoutes.notifications)) return 'Notifications';
    if (route.startsWith(AppRoutes.reports)) return 'Reports';
    if (route.startsWith(AppRoutes.users)) return 'Team & Users';
    if (route.startsWith(AppRoutes.settings)) return 'Settings';
    return 'Hytide CRM';
  }

  bool _isRootTab(String route) {
    return route == AppRoutes.dashboard ||
        route == AppRoutes.leads ||
        route == AppRoutes.followups ||
        route == AppRoutes.projects ||
        route == AppRoutes.more;
  }

  bool _hasOwnAppBar(String route) {
    return route == AppRoutes.leadCreate ||
        route.startsWith('${AppRoutes.leads}/') ||
        route == AppRoutes.followupCreate ||
        route.startsWith('${AppRoutes.followups}/') ||
        route == AppRoutes.clientCreate ||
        route.endsWith('/edit') ||
        route == AppRoutes.quotationCreate ||
        route.startsWith('${AppRoutes.quotations}/') ||
        route == AppRoutes.projectCreate ||
        route.startsWith('${AppRoutes.projects}/') ||
        route == AppRoutes.notifications;
  }

  bool _isDashboard(String route) => route == AppRoutes.dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).uri.path;
    final unreadNotifications =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final title = _deriveTitle(context);
    final isRoot = _isRootTab(currentRoute);
    final isDash = _isDashboard(currentRoute);
    final hasOwnAppBar = _hasOwnAppBar(currentRoute);
    final currentUser = ref.watch(currentUserModelProvider).valueOrNull;

    // Status bar overlay for gradient header on dashboard
    final statusBarStyle = isDark || isDash
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: AndroidForegroundBannerHost(
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.background,
          appBar: hasOwnAppBar
              ? null
              : _buildAppBar(
                  context,
                  isDark: isDark,
                  isDash: isDash,
                  isRoot: isRoot,
                  title: title,
                  unreadNotifications: unreadNotifications,
                  currentUser: currentUser,
                  currentRoute: currentRoute,
                ),
          body: SafeArea(bottom: false, child: widget.child),
          bottomNavigationBar: isRoot
              ? _buildBottomNav(
                  context,
                  isDark: isDark,
                  currentRoute: currentRoute,
                )
              : null,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDark,
    required bool isDash,
    required bool isRoot,
    required String title,
    required int unreadNotifications,
    required dynamic currentUser,
    required String currentRoute,
  }) {
    if (isDash) {
      // Dashboard: transparent gradient header embedded in body
      return AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 0,
      );
    }

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      centerTitle: false,
      title: Text(
        title,
        style: AppTypography.titleLarge.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      leading: (!isRoot || currentRoute == AppRoutes.leads)
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.borderDark.withValues(alpha: 0.6)
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
              onPressed: () {
                if (currentRoute == AppRoutes.leads) {
                  context.go(AppRoutes.dashboard);
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.waves_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
      leadingWidth: isRoot ? 56 : 56,
      actions: [
        if (currentRoute == AppRoutes.leads)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.go('${AppRoutes.leads}/create'),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context, {
    required bool isDark,
    required String currentRoute,
  }) {
    final selectedIndex = _getBottomNavIndex(currentRoute);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          elevation: 0,
          selectedIndex: selectedIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            switch (index) {
              case 0:
                context.go(AppRoutes.dashboard);
                break;
              case 1:
                context.go(AppRoutes.leads);
                break;
              case 2:
                context.go(AppRoutes.followups);
                break;
              case 3:
                context.go(AppRoutes.projects);
                break;
              case 4:
                context.go(AppRoutes.more);
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 22),
              selectedIcon: const Icon(
                Icons.home_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded, size: 22),
              selectedIcon: const Icon(
                Icons.people_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              label: 'Leads',
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_note_outlined, size: 22),
              selectedIcon: const Icon(
                Icons.event_note_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              label: 'Follow-ups',
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_open_outlined, size: 22),
              selectedIcon: const Icon(
                Icons.folder_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: const Icon(Icons.apps_outlined, size: 22),
              selectedIcon: const Icon(
                Icons.apps_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
