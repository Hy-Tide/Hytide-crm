// lib/features/expenses/widgets/add_money_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../projects/models/project_model.dart';
import '../../projects/repositories/project_repository.dart';
import '../models/expense_account_model.dart';
import '../providers/expense_providers.dart';

class AddMoneyDialog extends ConsumerStatefulWidget {
  final String? initialAccountId;

  const AddMoneyDialog({super.key, this.initialAccountId});

  static Future<bool?> show(BuildContext context, {String? initialAccountId}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddMoneyDialog(initialAccountId: initialAccountId),
    );
  }

  @override
  ConsumerState<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends ConsumerState<AddMoneyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController(text: 'Project Payment Received');
  final _noteController = TextEditingController();

  String? _selectedAccountId;
  ProjectModel? _selectedProject;
  DateTime _transactionDate = DateTime.now();
  String _paymentMethod = 'Bank Transfer';
  bool _isLoading = false;

  final List<String> _sourcePresets = [
    'Project Payment Received',
    'Client Advance',
    'Company Capital',
    'Reimbursement Deposit',
    'Bank Interest',
    'Other Funds',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(List<ExpenseAccountModel> accounts) async {
    if (!_formKey.currentState!.validate()) return;

    final account = accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => accounts.first,
    );

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

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final txId = await repo.addMoney(
        accountId: account.id,
        accountName: account.name,
        amount: amount,
        sourceOrReason: _sourceController.text.trim(),
        projectId: _selectedProject?.id,
        projectName: _selectedProject?.title,
        transactionDate: _transactionDate,
        note: _noteController.text.trim(),
        paymentMethod: _paymentMethod,
      );

      ref.read(appEventBusProvider).emit(
            MoneyAddedEvent(
              transactionId: txId,
              accountId: account.id,
              amount: amount,
            ),
          );

      // Trigger refresh
      ref.read(expenseRefreshTriggerProvider.notifier).state++;

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added ₹${amount.toStringAsFixed(2)} to ${account.name}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add funds: $e'),
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
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: accountsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Failed to load accounts: $err'),
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              ref.read(expenseRepositoryProvider).initializeDefaultAccounts();
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text('Setting up Mugesh & Deepika accounts...'),
                  ],
                ),
              );
            }

            if (_selectedAccountId == null ||
                !accounts.any((a) => a.id == _selectedAccountId)) {
              _selectedAccountId = accounts.first.id;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.add_card_rounded,
                            color: AppColors.success,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Money to Account',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.onSurfaceDark
                                      : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Record capital deposit or incoming project fund',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.onSurfaceVariantDark
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 1. Account Selection
                    Text(
                      'Account (Money Holder)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedAccountId,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: accounts
                          .map((acc) => DropdownMenuItem(
                                value: acc.id,
                                child: Text(acc.name, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAccountId = val;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Amount Input
                    Text(
                      'Amount to Add (₹)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        hintText: '50,000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                    const SizedBox(height: AppSpacing.md),

                    // 3. Source / Reason
                    Text(
                      'Source / Reason',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _sourceController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.source_outlined, size: 20),
                        hintText: 'e.g. Project Payment Received',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Source/Reason is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _sourcePresets.map((preset) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(preset, style: const TextStyle(fontSize: 11)),
                          onPressed: () => _sourceController.text = preset,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Project (Optional)
                    Text(
                      'Associated Project (Optional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    projectsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (projects) {
                        return DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: _selectedProject?.id,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          hint: const Text('Select Project (Optional)', overflow: TextOverflow.ellipsis),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No Project / General Funds', overflow: TextOverflow.ellipsis),
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
                              _selectedProject = val != null
                                  ? projects.firstWhere((p) => p.id == val)
                                  : null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 5. Date & Payment Method
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _transactionDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _transactionDate = picked);
                                  }
                                },
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
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
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(_transactionDate),
                                        style: AppTypography.bodyMedium,
                                      ),
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Method',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _paymentMethod,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Bank Transfer',
                                      child: Text('Bank Transfer', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(
                                      value: 'UPI', child: Text('UPI', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(
                                      value: 'Cash', child: Text('Cash', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(
                                      value: 'Cheque', child: Text('Cheque', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(
                                      value: 'Other', child: Text('Other', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _paymentMethod = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 6. Note (Optional)
                    Text(
                      'Note / Reference (Optional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Client advance for milestones 1 & 2',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () => _handleSubmit(accounts),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded,
                                  size: 18),
                          label: Text(_isLoading ? 'Saving...' : 'Add Money'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
