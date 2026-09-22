// lib/features/expenses/screens/expense_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../projects/models/project_model.dart';
import '../../projects/repositories/project_repository.dart';
import '../models/expense_account_model.dart';
import '../models/expense_account_summary_model.dart';
import '../providers/expense_providers.dart';
import '../repositories/expense_repository.dart';
import '../widgets/add_money_dialog.dart';
import '../widgets/expense_insufficient_balance_dialog.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? initialProjectId;

  const ExpenseFormScreen({super.key, this.initialProjectId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Payment Name
  final _paymentNameController = TextEditingController();

  // 2. Amount
  final _amountController = TextEditingController();

  // 3. Project
  ProjectModel? _selectedProject;

  // 4. Paid From & 5. Used By
  String? _paidFromAccountId;
  String? _paidFromAccountName;
  String? _usedByAccountId;
  String? _usedByAccountName;

  // 6. Category
  ExpenseCategory _category = ExpenseCategory.hosting;

  // 7. Date
  DateTime _expenseDate = DateTime.now();

  // 8. Payment Method
  ExpensePaymentMethod _paymentMethod = ExpensePaymentMethod.upi;

  // 9. Description
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  final List<String> _commonPaymentPresets = [
    'AWS Hosting',
    'Domain Renewal',
    'Client Travel',
    'Petrol',
    'Food & Refreshments',
    'Figma Subscription',
    'Firebase Billing',
    'Server Maintenance',
    'Office Purchase',
    'Client Meeting',
    'Marketing',
    'Hardware & Equipment',
  ];

  @override
  void dispose() {
    _paymentNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({
    required List<ExpenseAccountModel> accounts,
    required List<ExpenseAccountSummaryModel> summaries,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final paidFromAccount = accounts.firstWhere(
      (a) => a.id == _paidFromAccountId,
      orElse: () => accounts.first,
    );

    final usedByAccount = accounts.firstWhere(
      (a) => a.id == _usedByAccountId,
      orElse: () => accounts.first,
    );

    // Find summary for balance checking
    final summary = summaries.firstWhere(
      (s) => s.accountId == paidFromAccount.id,
      orElse: () => ExpenseAccountSummaryModel(
        accountId: paidFromAccount.id,
        accountName: paidFromAccount.name,
        currentBalance: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    // Pre-flight check: Prevent negative balance
    if (amount > summary.currentBalance) {
      ExpenseInsufficientBalanceDialog.show(
        context: context,
        accountName: paidFromAccount.name,
        currentBalance: summary.currentBalance,
        requestedAmount: amount,
        onAddFunds: () {
          AddMoneyDialog.show(context, initialAccountId: paidFromAccount.id);
        },
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final expenseId = await repo.createExpense(
        paymentName: _paymentNameController.text.trim(),
        amount: amount,
        projectId: _selectedProject?.id,
        projectName: _selectedProject?.title,
        projectNumber: _selectedProject?.projectNumber,
        paidFromAccountId: paidFromAccount.id,
        paidFromAccountName: paidFromAccount.name,
        usedByAccountId: usedByAccount.id,
        usedByAccountName: usedByAccount.name,
        category: _category,
        paymentMethod: _paymentMethod,
        expenseDate: _expenseDate,
        description: _descriptionController.text.trim(),
      );

      ref.read(appEventBusProvider).emit(
            ExpenseCreatedEvent(
              expenseId: expenseId,
              amount: amount,
              paidFromAccountId: paidFromAccount.id,
              projectId: _selectedProject?.id,
            ),
          );

      // Trigger refresh
      ref.read(expenseRefreshTriggerProvider.notifier).state++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recorded expense "${_paymentNameController.text.trim()}" (₹${amount.toStringAsFixed(2)})',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on InsufficientBalanceException catch (e) {
      if (mounted) {
        ExpenseInsufficientBalanceDialog.show(
          context: context,
          accountName: e.accountName,
          currentBalance: e.currentBalance,
          requestedAmount: e.requestedAmount,
          onAddFunds: () {
            AddMoneyDialog.show(context, initialAccountId: paidFromAccount.id);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record expense: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(expenseAccountsProvider);
    final summariesAsync = ref.watch(expenseAccountSummariesProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Create Expense'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => AddMoneyDialog.show(context),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Add Funds'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load accounts: $err',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(expenseAccountsProvider);
                    ref.read(expenseRepositoryProvider).initializeDefaultAccounts();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            ref.read(expenseRepositoryProvider).initializeDefaultAccounts();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Setting up Mugesh & Deepika accounts...',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Setup initial default account selections
          _paidFromAccountId ??= accounts.first.id;
          _paidFromAccountName ??= accounts.first.name;

          _usedByAccountId ??= accounts.length > 1
              ? accounts[1].id
              : accounts.first.id;
          _usedByAccountName ??= accounts.length > 1
              ? accounts[1].name
              : accounts.first.name;

          final summaries = summariesAsync.valueOrNull ?? [];

          // Pre-select project if passed in query
          projectsAsync.whenData((projects) {
            if (widget.initialProjectId != null && _selectedProject == null) {
              for (final p in projects) {
                if (p.id == widget.initialProjectId) {
                  _selectedProject = p;
                  break;
                }
              }
            }
          });

          // Selected paid from account balance
          final selectedSummary = summaries.firstWhere(
            (s) => s.accountId == _paidFromAccountId,
            orElse: () => ExpenseAccountSummaryModel(
              accountId: _paidFromAccountId ?? '',
              accountName: _paidFromAccountName ?? '',
              currentBalance: 0.0,
              updatedAt: DateTime.now(),
            ),
          );

          final inrFormat = NumberFormat.currency(
              locale: 'en_IN', symbol: '₹', decimalDigits: 2);

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!PlatformCapabilities.isAndroid) ...[
                        const Breadcrumbs(
                          items: [
                            BreadcrumbItem(label: 'Home', route: AppRoutes.dashboard),
                            BreadcrumbItem(label: 'Expenses', route: AppRoutes.expenses),
                            BreadcrumbItem(label: 'Create Expense'),
                          ],
                        ),
                        AppSpacing.gapH16,
                      ],

                      // Card Container
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── 1. FIRST INPUT: PAYMENT NAME ────────────────
                            Text(
                              'Payment Name',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'What was purchased or paid for?',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _paymentNameController,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                    Icons.label_important_outline_rounded),
                                hintText: 'e.g. AWS Hosting',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Payment name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _commonPaymentPresets.take(6).map((preset) {
                                return ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(preset,
                                      style: const TextStyle(fontSize: 11)),
                                  onPressed: () =>
                                      _paymentNameController.text = preset,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ─── 2. SECOND INPUT: AMOUNT ─────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Available: ${inrFormat.format(selectedSummary.currentBalance)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: selectedSummary.currentBalance > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE11D48),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Text(
                                    '₹',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                                hintText: '1,500',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter an amount greater than 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.lg),

                            // ─── 3. PROJECT SELECTION ────────────────────────
                            Text(
                              'Project (Optional)',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Assign this expense to a project or select No Project',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            projectsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Error loading projects: $e'),
                              data: (projects) {
                                return DropdownButtonFormField<String?>(
                                  value: _selectedProject?.id,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                        Icons.folder_outlined,
                                        size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                  ),
                                  isExpanded: true,
                                  hint: const Text('Select Project'),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(
                                        'No Project (General Hytide Expense)',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    ...projects.map((p) {
                                      final label =
                                          '${p.title} • ${p.clientName} (${p.projectNumber})';
                                      return DropdownMenuItem<String?>(
                                        value: p.id,
                                        child: Text(
                                          label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedProject = val != null
                                          ? projects.firstWhere((p) => p.id == val)
                                          : null;
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ─── 4. PAID FROM & 5. USED BY (DISTINCTION) ──────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 4. Paid From (Money Holder)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Paid From',
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Who held/owned the money?',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.onSurfaceVariantDark
                                              : AppColors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _paidFromAccountId,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              size: 18),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                        ),
                                        items: accounts.map((acc) {
                                          return DropdownMenuItem(
                                            value: acc.id,
                                            child: Text(acc.name, overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _paidFromAccountId = val;
                                            _paidFromAccountName = accounts
                                                .firstWhere((a) => a.id == val)
                                                .name;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),

                                // 5. Used By (Money Spender)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Used By',
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Who actually spent it?',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.onSurfaceVariantDark
                                              : AppColors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _usedByAccountId,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                              Icons.person_outline_rounded,
                                              size: 18),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                        ),
                                        items: accounts.map((acc) {
                                          return DropdownMenuItem(
                                            value: acc.id,
                                            child: Text(acc.name, overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _usedByAccountId = val;
                                            _usedByAccountName = accounts
                                                .firstWhere((a) => a.id == val)
                                                .name;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ─── 6. CATEGORY & 7. DATE ─────────────────────────
                            Row(
                              children: [
                                // 6. Category
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Category',
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      DropdownButtonFormField<ExpenseCategory>(
                                        isExpanded: true,
                                        value: _category,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                              Icons.category_outlined,
                                              size: 18),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                        ),
                                        items: ExpenseCategory.values
                                            .map((cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(cat.displayName, overflow: TextOverflow.ellipsis),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _category = val);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),

                                // 7. Date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date',
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _expenseDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                          if (picked != null) {
                                            setState(
                                                () => _expenseDate = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.md),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat('dd MMM yyyy')
                                                    .format(_expenseDate),
                                                style: AppTypography.bodyMedium,
                                              ),
                                              const Icon(
                                                  Icons
                                                      .calendar_today_rounded,
                                                  size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ─── 8. PAYMENT METHOD ────────────────────────────
                            Text(
                              'Payment Method',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<ExpensePaymentMethod>(
                              isExpanded: true,
                              value: _paymentMethod,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                    Icons.credit_card_outlined,
                                    size: 18),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items: ExpensePaymentMethod.values
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m.displayName, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paymentMethod = val);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ─── 9. DESCRIPTION ───────────────────────────────
                            Text(
                              'Description / Purpose',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g. Monthly AWS hosting bill for project backend',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // ─── SUBMIT BUTTON ────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _handleSave(
                                          accounts: accounts,
                                          summaries: summaries,
                                        ),
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 20),
                                label: Text(
                                  _isLoading ? 'Saving...' : 'Save Expense',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
