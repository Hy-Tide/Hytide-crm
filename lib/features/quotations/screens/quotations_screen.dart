// lib/features/quotations/screens/quotations_screen.dart
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
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/quotation_filter_model.dart';
import '../models/quotation_model.dart';
import '../providers/quotation_providers.dart';
import '../repositories/quotation_repository.dart';
import '../services/quotation_conversion_service.dart';
import '../widgets/quotation_action_dialogs.dart';
import '../widgets/quotation_card_item.dart';
import '../widgets/quotation_filter_drawer.dart';
import '../widgets/quotation_kpi_header.dart';
import '../widgets/quotation_pdf_dialog.dart';
import '../widgets/quotation_table_view.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounceTimer;

  // Pagination state
  final List<QuotationModel> _loadedQuotations = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(quotationSearchQueryProvider);
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
      ref.read(quotationSearchQueryProvider.notifier).state = query.trim();
      _resetPagination();
    });
  }

  void _resetPagination() {
    setState(() {
      _loadedQuotations.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    ref.invalidate(paginatedQuotationsProvider(null));
    ref.invalidate(quotationKpiCountsProvider);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final filter = ref.read(quotationFilterProvider);
      final query = ref.read(quotationSearchQueryProvider);

      final nextResult = await repo.getQuotationsPaginated(
        filter: filter,
        searchQuery: query,
        limit: 20,
        startAfter: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _loadedQuotations.addAll(nextResult.quotations);
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

  Future<void> _handlePreviewPdf(QuotationModel q) async {
    await QuotationPdfDialog.show(context, q);
  }

  Future<void> _handleSend(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showSendDialog(context, q);
    if (confirmed && mounted) {
      try {
        await ref.read(quotationRepositoryProvider).markAsSent(q.id);
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quotation ${q.quotationNumber} marked as Sent'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send quotation: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleAccept(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showAcceptDialog(context, q);
    if (confirmed && mounted) {
      try {
        await ref.read(quotationRepositoryProvider).markAsAccepted(q.id);
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quotation ${q.quotationNumber} accepted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept quotation: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleReject(QuotationModel q) async {
    final reason = await QuotationActionDialogs.showRejectDialog(context, q);
    if (reason != null && mounted) {
      try {
        await ref.read(quotationRepositoryProvider).markAsRejected(q.id, reason: reason);
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quotation ${q.quotationNumber} marked as Rejected'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject quotation: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleConvertToProject(QuotationModel q) async {
    final projName = await QuotationActionDialogs.showConvertToProjectDialog(context, q);
    if (projName != null && mounted) {
      try {
        final service = ref.read(quotationConversionServiceProvider);
        final newProjectId = await service.convertQuotationToProject(
          quotation: q,
          projectName: projName,
        );
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project created successfully! Project ID: $newProjectId'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => context.push('${AppRoutes.projects}/$newProjectId'),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project conversion failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleDuplicate(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showDuplicateDialog(context, q);
    if (confirmed && mounted) {
      try {
        final newId = await ref.read(quotationRepositoryProvider).duplicateQuotation(q.id);
        _resetPagination();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quotation duplicated as new Draft'),
              backgroundColor: AppColors.success,
            ),
          );
          context.push('${AppRoutes.quotations}/$newId');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to duplicate: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleArchive(QuotationModel q) async {
    try {
      if (q.isArchived) {
        await ref.read(quotationRepositoryProvider).restoreQuotation(q.id);
      } else {
        await ref.read(quotationRepositoryProvider).archiveQuotation(q.id);
      }
      _resetPagination();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(q.isArchived ? 'Quotation restored' : 'Quotation archived'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update archive state: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(quotationSyncCoordinatorProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(quotationFilterProvider);
    final searchQuery = ref.watch(quotationSearchQueryProvider);

    final firstPageAsync = ref.watch(paginatedQuotationsProvider(null));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      endDrawer: const QuotationFilterDrawer(),
      // Android: FAB for thumb-friendly quotation creation
      floatingActionButton: PlatformCapabilities.isAndroid
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.quotationCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Quotation'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumbs only on Web — not needed on Android
                    if (!PlatformCapabilities.isAndroid) ...[
                      const Breadcrumbs(
                        items: [
                          BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                          BreadcrumbItem(label: 'Quotations'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // Title row (Web only)
                    if (!PlatformCapabilities.isAndroid) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quotations',
                                  style: AppTypography.headlineMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Create, manage and track your customer quotations.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: () => context.push(AppRoutes.quotationCreate),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Quotation'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // KPI Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: QuotationKpiHeader(),
              ),
            ),

            // Search & Filter Toolbar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by quotation #, company, contact person or title...',
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
                        ),
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
                              builder: (ctx) => const QuotationFilterDrawer(),
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
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorState(
                  message: 'Failed to load quotations: $err',
                  onRetry: _resetPagination,
                ),
              ),
              data: (initialResult) {
                // Synchronize pagination state on initial load
                if (_loadedQuotations.isEmpty && initialResult.quotations.isNotEmpty) {
                  _loadedQuotations.addAll(initialResult.quotations);
                  _lastDocument = initialResult.lastDocument;
                  _hasMore = initialResult.hasMore;
                }

                final displayList = _loadedQuotations.isNotEmpty
                    ? _loadedQuotations
                    : initialResult.quotations;

                if (displayList.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 40),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? 'No matching quotations found'
                            : 'No quotations yet',
                        subtitle: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? 'Try clearing your active filters or changing your search terms.'
                            : 'Create sales estimates and commercial quotations for your clients.',
                        customAction: filter.hasActiveFilters || searchQuery.isNotEmpty
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(quotationSearchQueryProvider.notifier).state = '';
                                  ref.read(quotationFilterProvider.notifier).state =
                                      const QuotationFilter();
                                  _resetPagination();
                                },
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Clear Filters'),
                              )
                            : FilledButton.icon(
                                onPressed: () => context.push(AppRoutes.quotationCreate),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create First Quotation'),
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
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: QuotationCardItem(
                                    quotation: displayList[index],
                                    onPreviewPdf: _handlePreviewPdf,
                                    onSend: _handleSend,
                                    onAccept: _handleAccept,
                                    onReject: _handleReject,
                                    onConvertToProject: _handleConvertToProject,
                                    onDuplicate: _handleDuplicate,
                                    onArchive: _handleArchive,
                                  ),
                                );
                              }

                              // Pagination load more button
                              if (_hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? const CircularProgressIndicator()
                                        : OutlinedButton(
                                            onPressed: _loadMore,
                                            child: const Text('Load More Quotations'),
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

                      // Desktop Table
                      return SliverList(
                        delegate: SliverChildListDelegate([
                          QuotationTableView(
                            quotations: displayList,
                            onPreviewPdf: _handlePreviewPdf,
                            onSend: _handleSend,
                            onAccept: _handleAccept,
                            onReject: _handleReject,
                            onConvertToProject: _handleConvertToProject,
                            onDuplicate: _handleDuplicate,
                            onArchive: _handleArchive,
                          ),
                          if (_hasMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                              child: Center(
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: _loadMore,
                                        child: const Text('Load More Quotations'),
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
