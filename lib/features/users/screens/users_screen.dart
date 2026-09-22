// lib/features/users/screens/users_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/repositories/auth_repository.dart';
import '../providers/user_providers.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/user_grid_view.dart';
import '../widgets/user_kpi_header.dart';
import '../widgets/user_table_view.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(userSearchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(userSearchQueryProvider.notifier).state = query;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(userSearchQueryProvider.notifier).state = '';
    ref.read(userRoleFilterProvider.notifier).state = UserRoleFilter.all;
    ref.read(userStatusFilterProvider.notifier).state = UserStatusFilter.all;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usersAsync = ref.watch(allUsersProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);
    final viewMode = ref.watch(userViewModeProvider);
    final searchQuery = ref.watch(userSearchQueryProvider);
    final roleFilter = ref.watch(userRoleFilterProvider);
    final statusFilter = ref.watch(userStatusFilterProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    final hasActiveFilters = searchQuery.isNotEmpty ||
        roleFilter != UserRoleFilter.all ||
        statusFilter != UserStatusFilter.all;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            const Breadcrumbs(
              items: [
                BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                BreadcrumbItem(label: 'Users & Team'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Page Header Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team & Access Management',
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage administrators, managers, sales representatives, and access permissions.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile && isSuperAdmin) ...[
                      const SizedBox(width: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => AddUserDialog.show(context),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Add Team Member'),
                      ),
                    ],
                  ],
                );
              },
            ),

            // Mobile Add Member button
            if (MediaQuery.of(context).size.width < 650 && isSuperAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => AddUserDialog.show(context),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add Team Member'),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // KPI Header Cards
            const UserKpiHeader(),
            const SizedBox(height: AppSpacing.xl),

            // Search & Filter Toolbar
            _buildToolbar(context, isDark, viewMode, roleFilter, statusFilter),
            const SizedBox(height: AppSpacing.md),

            // Active Filter Tags
            if (hasActiveFilters) ...[
              _buildFilterChips(isDark, searchQuery, roleFilter, statusFilter),
              const SizedBox(height: AppSpacing.md),
            ],

            // Content Area
            usersAsync.when(
              loading: () => Column(
                children: List.generate(
                  4,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: SkeletonCard(),
                  ),
                ),
              ),
              error: (err, _) => ErrorState(
                message: 'Failed to load team members: $err',
                onRetry: () => ref.invalidate(allUsersProvider),
              ),
              data: (allUsers) {
                if (allUsers.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'No team members registered',
                      subtitle: 'Add your team members to grant them access to HyTide CRM.',
                      customAction: isSuperAdmin
                          ? FilledButton.icon(
                              onPressed: () => AddUserDialog.show(context),
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Add First Member'),
                            )
                          : null,
                    ),
                  );
                }

                if (filteredUsers.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: EmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'No matching team members',
                      subtitle: 'Try adjusting your search terms or clearing selected role/status filters.',
                      customAction: OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Clear Filters'),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Count indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Showing ${filteredUsers.length} of ${allUsers.length} team members',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Render Selected View Mode
                    if (viewMode == UserViewMode.table)
                      UserTableView(users: filteredUsers)
                    else
                      UserGridView(users: filteredUsers),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    bool isDark,
    UserViewMode viewMode,
    UserRoleFilter roleFilter,
    UserStatusFilter statusFilter,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Search Field
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 200,
                  maxWidth: isNarrow ? double.infinity : 320,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              // Filters & View Mode
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Role Filter Dropdown
                  DropdownButton<UserRoleFilter>(
                    value: roleFilter,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: UserRoleFilter.values.map((rf) {
                      return DropdownMenuItem(
                        value: rf,
                        child: Text(rf.label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (newFilter) {
                      if (newFilter != null) {
                        ref.read(userRoleFilterProvider.notifier).state = newFilter;
                      }
                    },
                  ),

                  // Status Filter Dropdown
                  DropdownButton<UserStatusFilter>(
                    value: statusFilter,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: UserStatusFilter.values.map((sf) {
                      return DropdownMenuItem(
                        value: sf,
                        child: Text(sf.label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (newFilter) {
                      if (newFilter != null) {
                        ref.read(userStatusFilterProvider.notifier).state = newFilter;
                      }
                    },
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  // View Mode Toggle (Table / Grid)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.table_rows_rounded, size: 18),
                          tooltip: 'Table view',
                          color: viewMode == UserViewMode.table
                              ? AppColors.primary
                              : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                          onPressed: () {
                            ref.read(userViewModeProvider.notifier).state = UserViewMode.table;
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          tooltip: 'Grid view',
                          color: viewMode == UserViewMode.grid
                              ? AppColors.primary
                              : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                          onPressed: () {
                            ref.read(userViewModeProvider.notifier).state = UserViewMode.grid;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(
    bool isDark,
    String searchQuery,
    UserRoleFilter roleFilter,
    UserStatusFilter statusFilter,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Active Filters:',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
          ),
        ),
        if (searchQuery.isNotEmpty)
          Chip(
            label: Text('Search: "$searchQuery"'),
            onDeleted: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            visualDensity: VisualDensity.compact,
          ),
        if (roleFilter != UserRoleFilter.all)
          Chip(
            label: Text('Role: ${roleFilter.label}'),
            onDeleted: () {
              ref.read(userRoleFilterProvider.notifier).state = UserRoleFilter.all;
            },
            visualDensity: VisualDensity.compact,
          ),
        if (statusFilter != UserStatusFilter.all)
          Chip(
            label: Text('Status: ${statusFilter.label}'),
            onDeleted: () {
              ref.read(userStatusFilterProvider.notifier).state = UserStatusFilter.all;
            },
            visualDensity: VisualDensity.compact,
          ),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear All', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
