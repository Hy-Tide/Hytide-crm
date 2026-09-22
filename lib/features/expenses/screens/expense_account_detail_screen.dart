// lib/features/expenses/screens/expense_account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../providers/expense_providers.dart';
import '../widgets/add_money_dialog.dart';

class ExpenseAccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;

  const ExpenseAccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<ExpenseAccountDetailScreen> createState() =>
      _ExpenseAccountDetailScreenState();
}

class _ExpenseAccountDetailScreenState
    extends ConsumerState<ExpenseAccountDetailScreen> {
  String _filterType = 'all'; // all, credit, debit

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync =
        ref.watch(expenseAccountSummaryFamily(widget.accountId));
    final transactionsAsync =
        ref.watch(accountTransactionsProvider(widget.accountId));

    final inrFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: summaryAsync.when(
          data: (s) => Text('${s?.accountName ?? "Account"} — Money Ledger'),
          loading: () => const Text('Account Ledger'),
          error: (_, __) => const Text('Account Ledger'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => AddMoneyDialog.show(
              context,
              initialAccountId: widget.accountId,
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Add Funds'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading account: $err')),
        data: (summary) {
          if (summary == null) {
            return const Center(child: Text('Account not found'));
          }

          final isMugesh =
              summary.accountName.toLowerCase().contains('mugesh');
          final color =
              isMugesh ? const Color(0xFF10B981) : const Color(0xFF8B5CF6);

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
                          BreadcrumbItem(label: summary.accountName),
                        ],
                      ),
                      AppSpacing.gapH16,
                    ],

                    // Account Profile & Hero KPI Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Text(
                                  summary.accountName.isNotEmpty
                                      ? summary.accountName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summary.accountName,
                                      style:
                                          AppTypography.headlineSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.onSurfaceDark
                                            : AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Designated Hytide Fund Holder',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.onSurfaceVariantDark
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                onPressed: () => AddMoneyDialog.show(
                                  context,
                                  initialAccountId: widget.accountId,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Money'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.lg),

                          // 3 Financial KPIs: Current Balance, Total Added, Total Spent
                          Row(
                            children: [
                              Expanded(
                                child: _AccountMetric(
                                  label: 'Current Balance',
                                  amount: inrFormat
                                      .format(summary.currentBalance),
                                  color: color,
                                  isHero: true,
                                ),
                              ),
                              Container(
                                height: 44,
                                width: 1,
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              Expanded(
                                child: _AccountMetric(
                                  label: 'Total Added (Credits)',
                                  amount:
                                      inrFormat.format(summary.totalCredits),
                                  color: AppColors.success,
                                ),
                              ),
                              Container(
                                height: 44,
                                width: 1,
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              Expanded(
                                child: _AccountMetric(
                                  label: 'Total Spent (Debits)',
                                  amount:
                                      inrFormat.format(summary.totalDebits),
                                  color: const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Ledger Filter & History Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction Ledger',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Filter Pills
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('All')),
                            ButtonSegment(
                                value: 'credit', label: Text('Credits (+)')),
                            ButtonSegment(
                                value: 'debit', label: Text('Debits (-)')),
                          ],
                          selected: {_filterType},
                          onSelectionChanged: (val) {
                            setState(() => _filterType = val.first);
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStateProperty.all(
                              const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Ledger List
                    transactionsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) =>
                          Center(child: Text('Error loading ledger: $err')),
                      data: (txList) {
                        var filtered = txList;
                        if (_filterType == 'credit') {
                          filtered =
                              filtered.where((t) => t.isCredit).toList();
                        } else if (_filterType == 'debit') {
                          filtered = filtered.where((t) => t.isDebit).toList();
                        }

                        if (filtered.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 40, color: Colors.grey),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No transactions recorded yet for ${summary.accountName}',
                                  style: AppTypography.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton.icon(
                                  onPressed: () => AddMoneyDialog.show(
                                    context,
                                    initialAccountId: widget.accountId,
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add First Funds'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            final isCredit = tx.isCredit;
                            final isVoided = tx.isVoided;

                            return InkWell(
                              onTap: tx.expenseId != null
                                  ? () => context.push(
                                      '${AppRoutes.expenses}/${tx.expenseId}')
                                  : null,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: isVoided
                                        ? AppColors.error
                                            .withValues(alpha: 0.3)
                                        : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Direction Icon
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isCredit
                                            ? AppColors.success
                                                .withValues(alpha: 0.12)
                                            : const Color(0xFFE11D48)
                                                .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Icon(
                                        isCredit
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                        size: 18,
                                        color: isCredit
                                            ? AppColors.success
                                            : const Color(0xFFE11D48),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    // Title & details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  tx.title,
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    decoration: isVoided
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                              ),
                                              if (isVoided)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error
                                                        .withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppRadius.xs),
                                                  ),
                                                  child: const Text(
                                                    'VOIDED',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.error,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${tx.description}  •  ${dateFormat.format(tx.transactionDate)}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: isDark
                                                  ? AppColors
                                                      .onSurfaceVariantDark
                                                  : AppColors
                                                      .onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (tx.projectName != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Project: ${tx.projectName}',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    // Transaction Amount & Running Balance
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isCredit ? "+ " : "- "}${inrFormat.format(tx.amount)}',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isCredit
                                                ? AppColors.success
                                                : const Color(0xFFE11D48),
                                            decoration: isVoided
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Bal: ${inrFormat.format(tx.runningBalance)}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors
                                                    .onSurfaceVariantDark
                                                : AppColors
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

class _AccountMetric extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isHero;

  const _AccountMetric({
    required this.label,
    required this.amount,
    required this.color,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: isDark
                ? AppColors.onSurfaceVariantDark
                : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: (isHero
                  ? AppTypography.headlineSmall
                  : AppTypography.titleMedium)
              .copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
