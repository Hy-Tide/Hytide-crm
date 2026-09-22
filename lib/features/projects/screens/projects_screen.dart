// lib/features/projects/screens/projects_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../models/project_filter_model.dart';
import '../models/project_model.dart';
import '../providers/project_providers.dart';
import '../repositories/project_repository.dart';
import '../widgets/project_action_dialogs.dart';
import '../widgets/project_card_item.dart';
import '../widgets/project_filter_drawer.dart';
import '../widgets/project_kpi_header.dart';
import '../widgets/project_table_view.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounceTimer;

  // Pagination state
  final List<ProjectModel> _loadedProjects = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(projectSearchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(projectSearchQueryProvider.notifier).state = query.trim();
      _resetPagination();
    });
  }

  void _resetPagination() {
    setState(() {
      _loadedProjects.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    ref.invalidate(paginatedProjectsProvider(null));
    ref.invalidate(projectKpiCountsProvider);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final filter = ref.read(projectFilterProvider);
      final query = ref.read(projectSearchQueryProvider);

      final nextResult = await repo.getProjectsPaginated(
        filter: filter,
        searchQuery: query,
        limit: 20,
        startAfter: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _loadedProjects.addAll(nextResult.projects);
          _lastDocument = nextResult.lastDocument;
          _hasMore = nextResult.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _handleStatusChange(ProjectModel project) async {
    final result = await ProjectActionDialogs.showStatusChangeDialog(
      context,
      project,
    );
    if (result != null && mounted) {
      try {
        await ref
            .read(projectRepositoryProvider)
            .updateProjectStatus(
              project.id,
              result.newStatus,
              reason: result.reason,
            );
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Project status updated to ${result.newStatus.name}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleProgressUpdate(ProjectModel project) async {
    final progress = await ProjectActionDialogs.showProgressDialog(
      context,
      project,
    );
    if (progress != null && mounted) {
      try {
        await ref
            .read(projectRepositoryProvider)
            .updateProjectProgress(project.id, progress);
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progress updated to $progress%'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update progress: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleArchive(ProjectModel project) async {
    final confirmed = await ProjectActionDialogs.showArchiveDialog(
      context,
      project,
    );
    if (confirmed && mounted) {
      try {
        if (project.isArchived) {
          await ref.read(projectRepositoryProvider).restoreProject(project.id);
        } else {
          await ref.read(projectRepositoryProvider).archiveProject(project.id);
        }
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                project.isArchived
                    ? 'Project restored'
                    : 'Project moved to archive',
              ),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update archive state: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(ProjectModel project) async {
    final confirmed = await ProjectActionDialogs.showDeleteDialog(
      context,
      project,
    );
    if (confirmed && mounted) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(project.id);
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete project: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(projectSyncCoordinatorProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(projectFilterProvider);
    final searchQuery = ref.watch(projectSearchQueryProvider);

    final firstPageAsync = ref.watch(paginatedProjectsProvider(null));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      endDrawer: const ProjectFilterDrawer(),
      // Android: FAB for thumb-friendly project creation
      floatingActionButton: PlatformCapabilities.isAndroid
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.projectCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Project'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar (Breadcrumbs & Title - Web only)
            if (!PlatformCapabilities.isAndroid)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Breadcrumbs(
                        items: [
                          BreadcrumbItem(
                            label: 'Dashboard',
                            route: AppRoutes.dashboard,
                          ),
                          BreadcrumbItem(label: 'Projects'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Projects',
                                  style: AppTypography.headlineMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.onSurfaceDark
                                        : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Track deliverables, milestones, requirements and project progress.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.onSurfaceVariantDark
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.projectCreate),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Project'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // KPI Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: ProjectKpiHeader(),
              ),
            ),

            // Search & Filter Toolbar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        controller: _searchController,
                        hintText:
                            'Search by project #, title, client, or manager...',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Badge(
                      isLabelVisible: filter.hasActiveFilters,
                      label: Text(filter.activeFilterCount.toString()),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (PlatformCapabilities.isAndroid) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const ProjectFilterDrawer(),
                            );
                          } else {
                            _scaffoldKey.currentState?.openEndDrawer();
                          }
                        },
                        icon: const Icon(Icons.filter_list_rounded, size: 18),
                        label: const Text('Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Area
            firstPageAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SkeletonCard(),
                    ),
                    childCount: 6,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorState(
                  message: 'Failed to load projects: $err',
                  onRetry: _resetPagination,
                ),
              ),
              data: (initialResult) {
                if (_loadedProjects.isEmpty &&
                    initialResult.projects.isNotEmpty) {
                  _loadedProjects.addAll(initialResult.projects);
                  _lastDocument = initialResult.lastDocument;
                  _hasMore = initialResult.hasMore;
                }

                final displayList = _loadedProjects.isNotEmpty
                    ? _loadedProjects
                    : initialResult.projects;

                if (displayList.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 40,
                      ),
                      child: EmptyState(
                        icon: Icons.folder_open_outlined,
                        title: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? 'No matching projects found'
                            : 'No projects yet',
                        subtitle:
                            filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? 'Try clearing your active filters or changing your search terms.'
                            : 'Create active client projects, track milestones, and deliver results.',
                        customAction:
                            filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                          .read(
                                            projectSearchQueryProvider.notifier,
                                          )
                                          .state =
                                      '';
                                  ref
                                          .read(projectFilterProvider.notifier)
                                          .state =
                                      const ProjectFilter();
                                  _resetPagination();
                                },
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Clear Filters'),
                              )
                            : FilledButton.icon(
                                onPressed: () =>
                                    context.push(AppRoutes.projectCreate),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create First Project'),
                              ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = PlatformCapabilities.isAndroid || constraints.crossAxisExtent < 768;

                      if (isMobile) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index < displayList.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: ProjectCardItem(
                                    project: displayList[index],
                                    onStatusChange: _handleStatusChange,
                                    onProgressUpdate: _handleProgressUpdate,
                                    onArchive: _handleArchive,
                                    onDelete: _handleDelete,
                                  ),
                                );
                              }

                              if (_hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? const CircularProgressIndicator()
                                        : OutlinedButton(
                                            onPressed: _loadMore,
                                            child: const Text(
                                              'Load More Projects',
                                            ),
                                          ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            childCount: displayList.length + (_hasMore ? 1 : 0),
                          ),
                        );
                      }

                      // Desktop Table View
                      return SliverList(
                        delegate: SliverChildListDelegate([
                          ProjectTableView(
                            projects: displayList,
                            onStatusChange: _handleStatusChange,
                            onProgressUpdate: _handleProgressUpdate,
                            onArchive: _handleArchive,
                            onDelete: _handleDelete,
                          ),
                          if (_hasMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Center(
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: _loadMore,
                                        child: const Text('Load More Projects'),
                                      ),
                              ),
                            ),
                        ]),
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
}
