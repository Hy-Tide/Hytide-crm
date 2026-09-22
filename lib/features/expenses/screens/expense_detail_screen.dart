// lib/features/expenses/screens/expense_detail_screen.dart
import 'package:flutter/material.dart';
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
import '../models/expense_model.dart';
import '../providers/expense_providers.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _isVoiding = false;

  Future<void> _handleVoid(ExpenseModel expense) async {
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
            Text('Void / Archive Expense'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voiding will cancel this debit and automatically restore ₹${expense.amount.toStringAsFixed(2)} back to ${expense.paidFromAccountName}\'s balance.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for voiding',
                hintText: 'e.g. Duplicate entry, refund received, etc.',
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

      setState(() => _isVoiding = true);

      try {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.voidExpense(
          expenseId: expense.id,
          reason: reason,
        );

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
                'Expense voided. ₹${expense.amount.toStringAsFixed(2)} restored to ${expense.paidFromAccountName}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to void expense: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isVoiding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseAsync = ref.watch(expenseDetailStreamProvider(widget.expenseId));
    final activitiesAsync =
        ref.watch(expenseActivitiesStreamProvider(widget.expenseId));

    final inrFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: expenseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading expense: $err')),
        data: (expense) {
          if (expense == null) {
            return const Center(child: Text('Expense record not found'));
          }

          final isVoided = expense.isVoided;

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!PlatformCapabilities.isAndroid) ...[
                      Breadcrumbs(
                        items: [
                          const BreadcrumbItem(
                              label: 'Home', route: AppRoutes.dashboard),
                          const BreadcrumbItem(
                              label: 'Expenses', route: AppRoutes.expenses),
                          BreadcrumbItem(label: expense.paymentName),
                        ],
                      ),
                      AppSpacing.gapH16,
                    ],

                    // Top Hero Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isVoided
                              ? AppColors.error.withValues(alpha: 0.4)
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Action Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isVoided
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : AppColors.success.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  isVoided ? 'VOIDED / CANCELLED' : 'COMPLETED',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isVoided
                                        ? AppColors.error
                                        : AppColors.success,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              if (!isVoided)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                        color: AppColors.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                  onPressed: _isVoiding
                                      ? null
                                      : () => _handleVoid(expense),
                                  icon: const Icon(Icons.block_rounded, size: 16),
                                  label: const Text('Void Expense'),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Payment Name & Prominent Amount
                          Text(
                            expense.paymentName,
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              decoration: isVoided
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isVoided
                                  ? (isDark
                                      ? AppColors.onSurfaceVariantDark
                                      : AppColors.onSurfaceVariant)
                                  : (isDark
                                      ? AppColors.onSurfaceDark
                                      : AppColors.onSurface),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inrFormat.format(expense.amount),
                            style: AppTypography.displayMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isVoided
                                  ? AppColors.error
                                  : const Color(0xFFE11D48),
                              decoration: isVoided
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.lg),

                          // Metadata Grid
                          _DetailRow(
                            label: 'Project',
                            child: expense.hasProject
                                ? InkWell(
                                    onTap: () => context.push(
                                        '${AppRoutes.projects}/${expense.projectId}'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.folder_outlined,
                                            size: 16, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${expense.projectName} (${expense.projectNumber ?? ''})',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Text('No Project (General Hytide Expense)'),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(
                            label: 'Paid From',
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    expense.paidFromAccountName.isNotEmpty
                                        ? expense.paidFromAccountName[0]
                                            .toUpperCase()
                                        : 'P',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  expense.paidFromAccountName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(Money Holder)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.onSurfaceVariantDark
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(
                            label: 'Used By',
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    expense.usedByAccountName.isNotEmpty
                                        ? expense.usedByAccountName[0]
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  expense.usedByAccountName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(Money Spender)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.onSurfaceVariantDark
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(
                            label: 'Category',
                            child: Text(
                              expense.category.displayName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(
                            label: 'Payment Method',
                            child: Text(
                              expense.paymentMethod.displayName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(
                            label: 'Date',
                            child: Text(
                              DateFormat('dd MMMM yyyy')
                                  .format(expense.expenseDate),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(
                            label: 'Description',
                            child: Text(
                              expense.description.isNotEmpty
                                  ? expense.description
                                  : 'No additional description provided.',
                              style: AppTypography.bodyMedium,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.lg),

                          // ─── BALANCE AFTER TRANSACTION SECTION (CRITICAL) ───
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.cardSurfaceDark
                                      : AppColors.cardSurface)
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Balance After Transaction',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.onSurfaceVariantDark
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${expense.paidFromAccountName}: ${inrFormat.format(expense.balanceAfterTransaction)}',
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Audit Activity History
                    Text(
                      'Audit & Activity Log',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    activitiesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading activities: $e'),
                      data: (activities) {
                        if (activities.isEmpty) {
                          return Text(
                            'No audit logs available',
                            style: AppTypography.bodySmall,
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activities.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, idx) {
                            final act = activities[idx];
                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.description,
                                          style: AppTypography.bodySmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${act.createdByName}  •  ${dateFormat.format(act.createdAt)}',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: isDark
                                                ? AppColors.onSurfaceVariantDark
                                                : AppColors.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
