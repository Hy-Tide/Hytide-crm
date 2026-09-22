// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../platform/platform_capabilities.dart';
import '../platform/widgets/android_app_scaffold.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  final String? title;

  const AppScaffold({
    super.key,
    required this.child,
    this.title,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarCollapsed = false;

  static const _collapsedKey = 'sidebar_collapsed';

  @override
  void initState() {
    super.initState();
    _loadSidebarState();
  }

  Future<void> _loadSidebarState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collapsed = prefs.getBool(_collapsedKey) ?? false;
      if (mounted && collapsed != _isSidebarCollapsed) {
        setState(() => _isSidebarCollapsed = collapsed);
      }
    } catch (_) {}
  }

  Future<void> _toggleSidebar() async {
    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_collapsedKey, _isSidebarCollapsed);
    } catch (_) {}
  }

  String _deriveTitle(BuildContext context) {
    if (widget.title != null) return widget.title!;
    final route = GoRouterState.of(context).uri.path;

    if (route == AppRoutes.dashboard) return 'Dashboard';
    if (route.startsWith(AppRoutes.leads)) return 'Leads';
    if (route.startsWith(AppRoutes.followups)) return 'Follow-ups';
    if (route.startsWith(AppRoutes.clients)) return 'Clients';
    if (route.startsWith(AppRoutes.projects)) return 'Projects';
    if (route.startsWith(AppRoutes.quotations)) return 'Quotations';
    if (route.startsWith(AppRoutes.documents)) return 'Documents';
    if (route.startsWith(AppRoutes.notifications)) return 'Notifications';
    if (route.startsWith(AppRoutes.reports)) return 'Reports';
    if (route.startsWith(AppRoutes.users)) return 'Users';
    if (route.startsWith(AppRoutes.settings)) return 'Settings';
    if (route.startsWith(AppRoutes.expenses)) return 'Expenses';

    return 'Hytide CRM';
  }

  int _getBottomNavIndex(String route) {
    if (route == AppRoutes.dashboard) return 0;
    if (route.startsWith(AppRoutes.leads)) return 1;
    if (route.startsWith(AppRoutes.followups)) return 2;
    if (route.startsWith(AppRoutes.clients)) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.isAndroid) {
      return AndroidAppScaffold(
        title: widget.title,
        child: widget.child,
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final isMobile = width < 600;
    final title = _deriveTitle(context);
    final currentRoute = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            AppSidebar(
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: _toggleSidebar,
            ),
            Expanded(
              child: Column(
                children: [
                  AppTopBar(title: title),
                  Expanded(
                    child: SelectionArea(
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tablet & Mobile
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: Drawer(
        backgroundColor: AppColors.sidebarBg,
        child: AppSidebar(
          onCloseDrawer: () => Navigator.of(context).pop(),
        ),
      ),
      appBar: AppTopBar(
        title: title,
        showDrawerButton: true,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: SafeArea(
        bottom: !isMobile,
        child: widget.child,
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _getBottomNavIndex(currentRoute),
              onDestinationSelected: (index) {
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
                    context.go(AppRoutes.clients);
                    break;
                  case 4:
                    _scaffoldKey.currentState?.openDrawer();
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Leads',
                ),
                NavigationDestination(
                  icon: Icon(Icons.schedule_outlined),
                  selectedIcon: Icon(Icons.schedule_rounded),
                  label: 'Follow-ups',
                ),
                NavigationDestination(
                  icon: Icon(Icons.business_outlined),
                  selectedIcon: Icon(Icons.business_rounded),
                  label: 'Clients',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded),
                  selectedIcon: Icon(Icons.menu_open_rounded),
                  label: 'More',
                ),
              ],
            )
          : null,
    );
  }
}
