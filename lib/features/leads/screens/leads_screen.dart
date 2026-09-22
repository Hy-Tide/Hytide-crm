import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/lead_filter_model.dart';
import '../providers/lead_providers.dart';
import '../widgets/lead_card_item.dart';
import '../widgets/lead_filter_drawer.dart';
import '../widgets/lead_kanban_board.dart';
import '../widgets/lead_sort_sheet.dart';
import '../widgets/lead_table_view.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(leadSearchQueryProvider);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(leadPaginationProvider);
      if (state.hasNextPage && !state.isLoading) {
        ref.read(leadPaginationProvider.notifier).loadNextPage();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop =
        !PlatformCapabilities.isAndroid &&
        MediaQuery.of(context).size.width >= 900;
    final viewMode = ref.watch(leadViewModeProvider);
    final sortOption = ref.watch(leadSortProvider);
    final filter = ref.watch(leadFilterProvider);
    final paginationState = ref.watch(leadPaginationProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      endDrawer: const LeadFilterDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section: Breadcrumb & Actions
            if (!PlatformCapabilities.isAndroid)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Breadcrumbs(
                      items: [
                        BreadcrumbItem(
                          label: 'Home',
                          route: AppRoutes.dashboard,
                        ),
                        BreadcrumbItem(label: 'Leads Management'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () =>
                              context.go('${AppRoutes.leads}/create'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create Lead'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Controls Bar: Search, View Mode, Filter, Sort
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: _buildControlsBar(
                isDesktop,
                isDark,
                viewMode,
                sortOption,
                filter,
                paginationState.totalCount,
              ),
            ),

            // Content Area (Table or Kanban)
            Expanded(
              child: viewMode == LeadViewMode.kanban
                  ? const LeadKanbanBoard()
                  : _buildTableView(isDesktop, isDark, paginationState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar(
    bool isDesktop,
    bool isDark,
    LeadViewMode viewMode,
    LeadSortOption sortOption,
    LeadFilter filter,
    int totalCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Search leads',
                onChanged: (val) {
                  ref.read(leadSearchQueryProvider.notifier).state = val;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton<LeadPriority>(
              icon: const Icon(Icons.flag_rounded),
              tooltip: 'Filter by Priority',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              onSelected: (priority) {
                ref.read(leadFilterProvider.notifier).state = filter.copyWith(
                  priorities: {priority},
                );
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<LeadPriority>(
                  enabled: false,
                  child: Text(
                    'Priority',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...LeadPriority.values.map(
                  (p) => PopupMenuItem(value: p, child: Text(p.displayName)),
                ),
              ],
            ),
            if (isDesktop) ...[
              const SizedBox(width: AppSpacing.sm),
              SegmentedButton<LeadViewMode>(
                segments: const [
                  ButtonSegment(
                    value: LeadViewMode.table,
                    icon: Icon(Icons.table_chart_outlined, size: 16),
                    label: Text('List'),
                  ),
                  ButtonSegment(
                    value: LeadViewMode.kanban,
                    icon: Icon(Icons.view_kanban_outlined, size: 16),
                    label: Text('Kanban'),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (selected) {
                  ref.read(leadViewModeProvider.notifier).state =
                      selected.first;
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Statuses',
                isActive: filter.status == null,
                isDark: isDark,
                onTap: () {
                  ref.read(leadFilterProvider.notifier).state = filter.copyWith(
                    clearStatus: true,
                  );
                },
              ),
              ...[
                LeadStatus.newLead,
                LeadStatus.followUp,
                LeadStatus.won,
                LeadStatus.lost,
              ].map((status) {
                final isActive = filter.status == status;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: _buildFilterChip(
                    label: status.displayName,
                    isActive: isActive,
                    isDark: isDark,
                    onTap: () {
                      ref.read(leadFilterProvider.notifier).state = filter
                          .copyWith(statuses: {status});
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$totalCount lead${totalCount == 1 ? "" : "s"} found',
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.surfaceVariantDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark
                      ? AppColors.surfaceBorderDark
                      : AppColors.surfaceBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(
    bool isDesktop,
    bool isDark,
    LeadPaginationState paginationState,
  ) {
    if (paginationState.isLoading && paginationState.leads.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 8,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonCard(),
        ),
      );
    }

    if (paginationState.error != null && paginationState.leads.isEmpty) {
      return ErrorState(
        message: paginationState.error!,
        onRetry: () => ref.read(leadPaginationProvider.notifier).refresh(),
      );
    }

    if (paginationState.leads.isEmpty) {
      final filter = ref.read(leadFilterProvider);
      final query = ref.read(leadSearchQueryProvider);
      final hasActiveFilters = filter.activeFilterCount > 0 || query.isNotEmpty;
      if (hasActiveFilters) {
        return EmptyState.filtered(
          title: 'No leads found',
          description: 'No leads match your current search and filters.',
          onAction: () {
            ref.read(leadFilterProvider.notifier).state = const LeadFilter();
            ref.read(leadSearchQueryProvider.notifier).state = '';
            _searchController.clear();
          },
        );
      }
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No leads yet',
        description: 'Create your first lead to start building your pipeline.',
        actionLabel: 'Create Lead',
        onAction: () => context.go('${AppRoutes.leads}/create'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(leadPaginationProvider.notifier).refresh();
      },
      child: isDesktop
          ? SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                bottom:
                    paginationState.isLoading &&
                        paginationState.leads.isNotEmpty
                    ? 16
                    : 0,
              ),
              child: Column(
                children: [
                  LeadTableView(
                    leads: paginationState.leads,
                    onRefresh: () =>
                        ref.read(leadPaginationProvider.notifier).refresh(),
                  ),
                  if (paginationState.isLoading &&
                      paginationState.leads.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: PlatformCapabilities.isAndroid ? 80 : AppSpacing.md,
              ),
              itemCount:
                  paginationState.leads.length +
                  (paginationState.isLoading && paginationState.leads.isNotEmpty
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index >= paginationState.leads.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final lead = paginationState.leads[index];
                return LeadCardItem(
                  lead: lead,
                  onRefresh: () =>
                      ref.read(leadPaginationProvider.notifier).refresh(),
                );
              },
            ),
    );
  }
}
