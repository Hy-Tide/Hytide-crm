// lib/features/expenses/widgets/expense_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../projects/repositories/project_repository.dart';
import '../models/expense_filter_model.dart';
import '../providers/expense_providers.dart';

class ExpenseFilterSheet extends ConsumerStatefulWidget {
  const ExpenseFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExpenseFilterSheet(),
    );
  }

  @override
  ConsumerState<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<ExpenseFilterSheet> {
  late ExpenseFilter _filter;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = ref.read(expenseFilterProvider);
    if (_filter.minAmount != null) {
      _minAmountController.text = _filter.minAmount!.toStringAsFixed(0);
    }
    if (_filter.maxAmount != null) {
      _maxAmountController.text = _filter.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final min = double.tryParse(_minAmountController.text.trim());
    final max = double.tryParse(_maxAmountController.text.trim());

    final updated = _filter.copyWith(
      minAmount: min,
      maxAmount: max,
      clearAmountRange: min == null && max == null,
    );

    ref.read(expenseFilterProvider.notifier).state = updated;
    ref.read(expenseRefreshTriggerProvider.notifier).state++;
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    ref.read(expenseFilterProvider.notifier).state = const ExpenseFilter();
    ref.read(expenseRefreshTriggerProvider.notifier).state++;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(expenseAccountsProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Filter Expenses',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _resetFilter,
                  child: const Text('Reset All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // 1. Date Range
                Text(
                  'Date Range',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          _filter.startDate != null
                              ? DateFormat('dd MMM yyyy').format(_filter.startDate!)
                              : 'From Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filter.startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _filter = _filter.copyWith(startDate: picked);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          _filter.endDate != null
                              ? DateFormat('dd MMM yyyy').format(_filter.endDate!)
                              : 'To Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filter.endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _filter = _filter.copyWith(endDate: picked);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_filter.startDate != null || _filter.endDate != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          _filter = _filter.copyWith(clearDates: true);
                        });
                      },
                      child: const Text('Clear Dates', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // 2. Project Filter
                Text(
                  'Project',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                projectsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (projects) {
                    return DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _filter.projectId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      hint: const Text('All Projects', overflow: TextOverflow.ellipsis),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Projects', overflow: TextOverflow.ellipsis),
                        ),
                        ...projects.map((p) => DropdownMenuItem<String?>(
                              value: p.id,
                              child: Text(
                                '${p.title} (${p.projectNumber})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filter = _filter.copyWith(
                            projectId: val,
                            clearProject: val == null,
                          );
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Paid From Account
                Text(
                  'Paid From (Money Holder)',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                accountsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (accounts) {
                    return DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _filter.paidFromAccountId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      hint: const Text('All Accounts', overflow: TextOverflow.ellipsis),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Accounts', overflow: TextOverflow.ellipsis),
                        ),
                        ...accounts.map((a) => DropdownMenuItem<String?>(
                              value: a.id,
                              child: Text(a.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filter = _filter.copyWith(
                            paidFromAccountId: val,
                            clearPaidFrom: val == null,
                          );
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Used By Account
                Text(
                  'Used By (Money Spender)',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                accountsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (accounts) {
                    return DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _filter.usedByAccountId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      hint: const Text('All Persons', overflow: TextOverflow.ellipsis),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Persons', overflow: TextOverflow.ellipsis),
                        ),
                        ...accounts.map((a) => DropdownMenuItem<String?>(
                              value: a.id,
                              child: Text(a.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filter = _filter.copyWith(
                            usedByAccountId: val,
                            clearUsedBy: val == null,
                          );
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 5. Category
                Text(
                  'Category',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<ExpenseCategory?>(
                  isExpanded: true,
                  initialValue: _filter.category,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  hint: const Text('All Categories', overflow: TextOverflow.ellipsis),
                  items: [
                    const DropdownMenuItem<ExpenseCategory?>(
                      value: null,
                      child: Text('All Categories', overflow: TextOverflow.ellipsis),
                    ),
                    ...ExpenseCategory.values.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.displayName, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filter = _filter.copyWith(
                        category: val,
                        clearCategory: val == null,
                      );
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 6. Payment Method
                Text(
                  'Payment Method',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<ExpensePaymentMethod?>(
                  isExpanded: true,
                  initialValue: _filter.paymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  hint: const Text('All Payment Methods', overflow: TextOverflow.ellipsis),
                  items: [
                    const DropdownMenuItem<ExpensePaymentMethod?>(
                      value: null,
                      child: Text('All Payment Methods', overflow: TextOverflow.ellipsis),
                    ),
                    ...ExpensePaymentMethod.values.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.displayName, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filter = _filter.copyWith(
                        paymentMethod: val,
                        clearPaymentMethod: val == null,
                      );
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 7. Amount Range
                Text(
                  'Amount Range (₹)',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'Min',
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
                    const Text('to'),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'Max',
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
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 8. Include Voided
                CheckboxListTile(
                  title: const Text('Include Voided Expenses'),
                  value: _filter.includeVoided,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      _filter = _filter.copyWith(includeVoided: val ?? false);
                    });
                  },
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
