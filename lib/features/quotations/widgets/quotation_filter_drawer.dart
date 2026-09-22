// lib/features/quotations/widgets/quotation_filter_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/quotation_filter_model.dart';
import '../providers/quotation_providers.dart';

class QuotationFilterDrawer extends ConsumerStatefulWidget {
  const QuotationFilterDrawer({super.key});

  @override
  ConsumerState<QuotationFilterDrawer> createState() => _QuotationFilterDrawerState();
}

class _QuotationFilterDrawerState extends ConsumerState<QuotationFilterDrawer> {
  late QuotationFilter _tempFilter;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _tempFilter = ref.read(quotationFilterProvider);
    _minAmountController = TextEditingController(
      text: _tempFilter.minAmount != null ? _tempFilter.minAmount!.toStringAsFixed(0) : '',
    );
    _maxAmountController = TextEditingController(
      text: _tempFilter.maxAmount != null ? _tempFilter.maxAmount!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffAsync = ref.watch(activeUsersProvider);

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Filter Quotations',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 1. Status Filter
                  _buildSectionHeader('Status'),
                  DropdownButtonFormField<QuotationStatus?>(
                    initialValue: _tempFilter.status,
                    decoration: const InputDecoration(hintText: 'All Statuses'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...QuotationStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(status: () => val);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Date Filter
                  _buildSectionHeader('Date Filter'),
                  DropdownButtonFormField<QuotationDateFilter>(
                    initialValue: _tempFilter.dateFilter,
                    decoration: const InputDecoration(hintText: 'Date Range'),
                    items: QuotationDateFilter.values.map(
                      (d) => DropdownMenuItem(value: d, child: Text(d.displayName)),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(dateFilter: val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Assigned Staff
                  _buildSectionHeader('Assigned Staff'),
                  staffAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, stack) => const SizedBox.shrink(),
                    data: (staff) {
                      return DropdownButtonFormField<String?>(
                        initialValue: _tempFilter.assignedTo,
                        decoration: const InputDecoration(hintText: 'All Staff Members'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Staff Members')),
                          ...staff.map((s) => DropdownMenuItem(value: s.uid, child: Text(s.displayName))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(assignedTo: () => val);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Amount Range
                  _buildSectionHeader('Amount Range (₹)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min ₹',
                            prefixText: '₹ ',
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            _tempFilter = _tempFilter.copyWith(minAmount: () => parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _maxAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max ₹',
                            prefixText: '₹ ',
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            _tempFilter = _tempFilter.copyWith(maxAmount: () => parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 5. Sort By
                  _buildSectionHeader('Sort By'),
                  DropdownButtonFormField<QuotationSortBy>(
                    initialValue: _tempFilter.sortBy,
                    decoration: const InputDecoration(hintText: 'Sort Order'),
                    items: QuotationSortBy.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(sortBy: val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. Archived Toggle
                  SwitchListTile(
                    title: const Text('Show Archived Quotations'),
                    subtitle: const Text('Include archived/inactive records'),
                    contentPadding: EdgeInsets.zero,
                    value: _tempFilter.isArchived,
                    onChanged: (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(isArchived: val);
                      });
                    },
                  ),
                ],
              ),
            ),

            // Drawer Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _tempFilter = const QuotationFilter();
                          _minAmountController.clear();
                          _maxAmountController.clear();
                        });
                        ref.read(quotationFilterProvider.notifier).state = const QuotationFilter();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(quotationFilterProvider.notifier).state = _tempFilter;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
