// lib/features/expenses/screens/expenses_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../models/expense_model.dart';
import '../providers/expense_providers.dart';
import '../widgets/add_money_dialog.dart';
import '../widgets/expense_filter_sheet.dart';
import '../widgets/expense_kpi_cards.dart';
import '../widgets/expense_mobile_card_item.dart';
import '../widgets/expense_money_overview_cards.dart';
import '../widgets/expense_table_view.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  DocumentSnapshot? _currentStartAfter;
  final List<DocumentSnapshot?> _pageHistory = [];
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(expenseSearchQueryProvider.notifier).state = query.trim();
      setState(() {
        _currentStartAfter = null;
        _pageHistory.clear();
        _currentPage = 1;
      });
    });
  }

  Future<void> _handleVoidExpense(ExpenseModel expense) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Void Expense'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to void "${expense.paymentName}" for ₹${expense.amount.toStringAsFixed(2)}?',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'This will automatically restore ₹${expense.amount.toStringAsFixed(2)} back to ${expense.paidFromAccountName}\'s balance.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for voiding',
                hintText: 'e.g. Cancelled / Refunded',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Void Expense'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim().isNotEmpty
          ? reasonController.text.trim()
          : 'Voided by admin';

      try {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.voidExpense(expenseId: expense.id, reason: reason);

        ref.read(appEventBusProvider).emit(
              ExpenseVoidedEvent(
                expenseId: expense.id,
                restoredAmount: expense.amount,
                paidFromAccountId: expense.paidFromAccountId,
              ),
            );

        ref.read(expenseRefreshTriggerProvider.notifier).state++;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense voided. Restored ₹${expense.amount.toStringAsFixed(2)} to ${expense.paidFromAccountName}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to void: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768 || PlatformCapabilities.isAndroid;

    final filter = ref.watch(expenseFilterProvider);
    final paginatedAsync =
        ref.watch(paginatedExpensesProvider(_currentStartAfter));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => context.push(AppRoutes.expenseCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Expense'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(expenseRefreshTriggerProvider.notifier).state++;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs (Desktop)
              if (!isMobile) ...[
                const Breadcrumbs(
                  items: [
                    BreadcrumbItem(label: 'Home', route: AppRoutes.dashboard),
                    BreadcrumbItem(label: 'Expenses'),
                  ],
                ),
                AppSpacing.gapH16,
              ],

              // Top Title & Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses & Working Capital',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track Hytide money flow, holder balances & project expenses',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (!isMobile)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () => AddMoneyDialog.show(context),
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 18),
                          label: const Text('Add Money'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () => context.push(AppRoutes.expenseCreate),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('+ Expense'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Mobile Quick Actions Bar
              if (isMobile) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () => context.push(AppRoutes.expenseCreate),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('+ Expense'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 5,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () => AddMoneyDialog.show(context),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 18),
                        label: const Text('+ Money'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ─── 1. MONEY OVERVIEW CARDS ──────────────────────────────────
              ExpenseMoneyOverviewCards(
                onAddMoneyPressed: () => AddMoneyDialog.show(context),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── 2. EXPENSE KPIS ──────────────────────────────────────────
              const ExpenseKpiCards(),
              const SizedBox(height: AppSpacing.xl),

              // ─── 3. SEARCH & FILTERS BAR ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search payments, projects, persons...',
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Badge(
                    isLabelVisible: filter.hasActiveFilters,
                    label: Text('${filter.activeFilterCount}'),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () => ExpenseFilterSheet.show(context),
                      icon: const Icon(Icons.filter_list_rounded, size: 18),
                      label: Text(isMobile ? 'Filter' : 'Filters'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── 4. EXPENSE LIST / TABLE ──────────────────────────────────
              paginatedAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Error loading expenses: $err'),
                  ),
                ),
                data: (result) {
                  final expenses = result.expenses;

                  if (expenses.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 52,
                            color: isDark
                                ? AppColors.onSurfaceVariantDark
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No expenses yet',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track project and Hytide expenses here.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: () =>
                                context.push(AppRoutes.expenseCreate),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Expense'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (isMobile)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return ExpenseMobileCardItem(
                              expense: expense,
                              onTap: () => context.push(
                                  '${AppRoutes.expenses}/${expense.id}'),
                            );
                          },
                        )
                      else
                        ExpenseTableView(
                          expenses: expenses,
                          onExpenseTap: (expense) => context
                              .push('${AppRoutes.expenses}/${expense.id}'),
                          onVoidTap: (expense) => _handleVoidExpense(expense),
                        ),
                      const SizedBox(height: AppSpacing.md),

                      // Pagination Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page $_currentPage (${expenses.length} records)',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                          _pageHistory.removeLast();
                                          _currentStartAfter =
                                              _pageHistory.isNotEmpty
                                                  ? _pageHistory.last
                                                  : null;
                                        });
                                      }
                                    : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              OutlinedButton(
                                onPressed: result.hasMore
                                    ? () {
                                        setState(() {
                                          _pageHistory.add(_currentStartAfter);
                                          _currentStartAfter =
                                              result.lastDocument;
                                          _currentPage++;
                                        });
                                      }
                                    : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
