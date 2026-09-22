// lib/features/clients/screens/clients_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/client_filter_model.dart';
import '../providers/client_providers.dart';
import '../widgets/client_card_item.dart';
import '../widgets/client_filter_drawer.dart';
import '../widgets/client_kpi_header.dart';
import '../widgets/client_table_view.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedClientsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(clientSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clientsState = ref.watch(paginatedClientsProvider);
    final filter = ref.watch(clientFilterProvider);
    final searchQuery = ref.watch(clientSearchQueryProvider);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ClientFilterDrawer(),
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      // Android: FAB for thumb-friendly client creation
      floatingActionButton: PlatformCapabilities.isAndroid
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.clientCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Client'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paginatedClientsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumbs only on Web — not needed on Android
                    if (!PlatformCapabilities.isAndroid) ...[
                      const Breadcrumbs(
                        items: [
                          BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                          BreadcrumbItem(label: 'Clients'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Header Row (Web only)
                    if (!PlatformCapabilities.isAndroid) ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clients',
                                      style: AppTypography.headlineMedium.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage your customers, relationships and business history.',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.onSurfaceVariantDark
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: AppSpacing.md),
                                FilledButton.icon(
                                  onPressed: () => context.push(AppRoutes.clientCreate),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('New Client'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],

                    // On Android use FAB instead of inline buttons
                    if (!PlatformCapabilities.isAndroid) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.clientCreate),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New Client'),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // KPI Header
                    const ClientKpiHeader(),
                    const SizedBox(height: AppSpacing.xl),

                    // Search & Filters Toolbar
                    _buildToolbar(context, ref, filter, isDark),
                    const SizedBox(height: AppSpacing.md),

                    // Active Filter Chips
                    if (filter.hasActiveFilters || searchQuery.isNotEmpty)
                      _buildActiveFilterChips(context, ref, filter, searchQuery, isDark),
                  ],
                ),
              ),
            ),

            // Clients List / Table
            clientsState.when(
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading clients...',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ErrorState(
                    message: 'Failed to load clients: $err',
                    onRetry: () => ref.read(paginatedClientsProvider.notifier).refresh(),
                  ),
                ),
              ),
              data: (data) {
                if (data.clients.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 40),
                      child: EmptyState(
                        icon: Icons.business_outlined,
                        title: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? 'No matching clients found'
                            : 'No clients yet',
                        subtitle: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? 'Try clearing your active filters or changing your search terms.'
                            : 'Convert a won lead into a client or create a client manually.',
                        customAction: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(clientSearchQueryProvider.notifier).state = '';
                                  ref.read(clientFilterProvider.notifier).state = const ClientFilter();
                                },
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Clear Filters'),
                              )
                            : FilledButton.icon(
                                onPressed: () => context.push(AppRoutes.clientCreate),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create First Client'),
                              ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = !PlatformCapabilities.isAndroid && constraints.crossAxisExtent >= 900;

                      if (isDesktop) {
                        return SliverList(
                          delegate: SliverChildListDelegate([
                            ClientTableView(
                              clients: data.clients,
                              onRefresh: () => ref.read(paginatedClientsProvider.notifier).refresh(),
                            ),
                            if (data.isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            const SizedBox(height: AppSpacing.xxl),
                          ]),
                        );
                      }

                      // Mobile / Tablet Card View
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == data.clients.length) {
                              return data.isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(AppSpacing.md),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  : const SizedBox(height: AppSpacing.xxl);
                            }
                            return ClientCardItem(
                              client: data.clients[index],
                              onRefresh: () => ref.read(paginatedClientsProvider.notifier).refresh(),
                            );
                          },
                          childCount: data.clients.length + 1,
                        ),
                      );
                    },
                  ),
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
    WidgetRef ref,
    ClientFilter filter,
    bool isDark,
  ) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by company, contact, phone, email, city...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Filter Drawer Button
        Badge(
          isLabelVisible: filter.hasActiveFilters,
          label: Text('${filter.activeFilterCount}'),
          child: OutlinedButton.icon(
            onPressed: () {
              if (PlatformCapabilities.isAndroid) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const ClientFilterDrawer(),
                );
              } else {
                _scaffoldKey.currentState?.openEndDrawer();
              }
            },
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Filter'),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    WidgetRef ref,
    ClientFilter filter,
    String searchQuery,
    bool isDark,
  ) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (searchQuery.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.search_rounded, size: 14),
            label: Text('Search: "$searchQuery"'),
            onDeleted: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
        if (filter.status != null)
          Chip(
            avatar: const Icon(Icons.check_circle_outline_rounded, size: 14),
            label: Text('Status: ${filter.status!.displayName}'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(status: () => null);
            },
          ),
        if (filter.priority != null)
          Chip(
            avatar: const Icon(Icons.flag_outlined, size: 14),
            label: Text('Priority: ${filter.priority!.displayName}'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(priority: () => null);
            },
          ),
        if (filter.clientType != null)
          Chip(
            avatar: const Icon(Icons.category_outlined, size: 14),
            label: Text('Type: ${filter.clientType!.displayName}'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(clientType: () => null);
            },
          ),
        if (filter.industry != null && filter.industry!.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.domain_rounded, size: 14),
            label: Text('Industry: ${filter.industry}'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(industry: () => null);
            },
          ),
        if (filter.city != null && filter.city!.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.location_city_rounded, size: 14),
            label: Text('City: ${filter.city}'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(city: () => null);
            },
          ),
        if (filter.dateFilter != ClientDateFilter.all)
          Chip(
            avatar: const Icon(Icons.calendar_today_rounded, size: 14),
            label: Text('Date: ${filter.dateFilter.displayName}'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(dateFilter: ClientDateFilter.all);
            },
          ),
        if (filter.showArchived)
          Chip(
            avatar: const Icon(Icons.archive_outlined, size: 14),
            label: const Text('Archived Clients'),
            onDeleted: () {
              ref.read(clientFilterProvider.notifier).state =
                  filter.copyWith(showArchived: false);
            },
          ),
        TextButton(
          onPressed: () {
            _searchController.clear();
            ref.read(clientSearchQueryProvider.notifier).state = '';
            ref.read(clientFilterProvider.notifier).state = const ClientFilter();
          },
          child: const Text('Clear All'),
        ),
      ],
    );
  }
}
