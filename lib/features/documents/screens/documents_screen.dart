// lib/features/documents/screens/documents_screen.dart
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
import '../providers/document_providers.dart';
import '../repositories/document_repository.dart';
import '../widgets/document_grid_view.dart';
import '../widgets/document_kpi_header.dart';
import '../widgets/document_table_view.dart';
import '../widgets/upload_document_dialog.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(documentSearchQueryProvider);
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
      ref.read(documentSearchQueryProvider.notifier).state = query;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(documentSearchQueryProvider.notifier).state = '';
    ref.read(documentTypeFilterProvider.notifier).state = DocumentTypeFilter.all;
    ref.read(documentEntityFilterProvider.notifier).state = DocumentEntityFilter.all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final docsAsync = ref.watch(documentsStreamProvider);
    final filteredDocs = ref.watch(filteredDocumentsProvider);
    final viewMode = ref.watch(documentViewModeProvider);
    final searchQuery = ref.watch(documentSearchQueryProvider);
    final typeFilter = ref.watch(documentTypeFilterProvider);
    final entityFilter = ref.watch(documentEntityFilterProvider);

    final hasActiveFilters = searchQuery.isNotEmpty ||
        typeFilter != DocumentTypeFilter.all ||
        entityFilter != DocumentEntityFilter.all;

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
                BreadcrumbItem(label: 'Documents'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Page Header Row
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
                            'Documents',
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Central repository for contracts, proposals, NDAs, and project files.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => UploadDocumentDialog.show(context),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Upload Document'),
                      ),
                    ],
                  ],
                );
              },
            ),

            // Mobile upload button
            if (MediaQuery.of(context).size.width < 600) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => UploadDocumentDialog.show(context),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload Document'),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // KPI Header Cards
            const DocumentKpiHeader(),
            const SizedBox(height: AppSpacing.xl),

            // Search & Filter Toolbar
            _buildToolbar(context, isDark, viewMode, typeFilter, entityFilter),
            const SizedBox(height: AppSpacing.md),

            // Active filter tags if filtered
            if (hasActiveFilters) ...[
              _buildFilterChips(isDark, searchQuery, typeFilter, entityFilter),
              const SizedBox(height: AppSpacing.md),
            ],

            // Content Area
            docsAsync.when(
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
                message: 'Failed to load documents: $err',
                onRetry: () => ref.invalidate(documentsStreamProvider),
              ),
              data: (allDocs) {
                if (allDocs.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: EmptyState(
                      icon: Icons.attach_file_rounded,
                      title: 'No documents yet',
                      subtitle: 'Upload agreements, quotes, NDAs, and specs to centralize your company files.',
                      customAction: FilledButton.icon(
                        onPressed: () => UploadDocumentDialog.show(context),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload First Document'),
                      ),
                    ),
                  );
                }

                if (filteredDocs.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matching documents',
                      subtitle: 'Try adjusting your search terms or clearing selected filters.',
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
                        'Showing ${filteredDocs.length} of ${allDocs.length} documents',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Render selected view mode
                    if (viewMode == DocumentViewMode.table)
                      DocumentTableView(documents: filteredDocs)
                    else
                      DocumentGridView(documents: filteredDocs),
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
    DocumentViewMode viewMode,
    DocumentTypeFilter typeFilter,
    DocumentEntityFilter entityFilter,
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
              // Search Input Box
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 200,
                  maxWidth: isNarrow ? double.infinity : 320,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search documents or uploader...',
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

              // Filter Controls & View Mode
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // File Type Dropdown
                  DropdownButton<DocumentTypeFilter>(
                    value: typeFilter,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: DocumentTypeFilter.values.map((filter) {
                      return DropdownMenuItem(
                        value: filter,
                        child: Text(filter.label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (newFilter) {
                      if (newFilter != null) {
                        ref.read(documentTypeFilterProvider.notifier).state = newFilter;
                      }
                    },
                  ),

                  // Association Filter Dropdown
                  DropdownButton<DocumentEntityFilter>(
                    value: entityFilter,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: DocumentEntityFilter.values.map((filter) {
                      return DropdownMenuItem(
                        value: filter,
                        child: Text(filter.label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (newFilter) {
                      if (newFilter != null) {
                        ref.read(documentEntityFilterProvider.notifier).state = newFilter;
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
                          color: viewMode == DocumentViewMode.table
                              ? AppColors.primary
                              : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                          onPressed: () {
                            ref.read(documentViewModeProvider.notifier).state = DocumentViewMode.table;
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          tooltip: 'Grid view',
                          color: viewMode == DocumentViewMode.grid
                              ? AppColors.primary
                              : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                          onPressed: () {
                            ref.read(documentViewModeProvider.notifier).state = DocumentViewMode.grid;
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
    DocumentTypeFilter typeFilter,
    DocumentEntityFilter entityFilter,
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
            label: Text('Query: "$searchQuery"'),
            onDeleted: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            visualDensity: VisualDensity.compact,
          ),
        if (typeFilter != DocumentTypeFilter.all)
          Chip(
            label: Text('Type: ${typeFilter.label}'),
            onDeleted: () {
              ref.read(documentTypeFilterProvider.notifier).state = DocumentTypeFilter.all;
            },
            visualDensity: VisualDensity.compact,
          ),
        if (entityFilter != DocumentEntityFilter.all)
          Chip(
            label: Text('Association: ${entityFilter.label}'),
            onDeleted: () {
              ref.read(documentEntityFilterProvider.notifier).state = DocumentEntityFilter.all;
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
