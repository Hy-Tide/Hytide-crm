// lib/features/expenses/widgets/expense_money_overview_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/expense_account_summary_model.dart';
import '../providers/expense_providers.dart';

class ExpenseMoneyOverviewCards extends ConsumerWidget {
  final VoidCallback? onAddMoneyPressed;

  const ExpenseMoneyOverviewCards({
    super.key,
    this.onAddMoneyPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardSummaryAsync = ref.watch(expenseDashboardSummaryProvider);
    final accountSummariesAsync = ref.watch(expenseAccountSummariesProvider);
    final inrFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final dashboardSummary = dashboardSummaryAsync.valueOrNull;
    final accountSummaries = accountSummariesAsync.valueOrNull ?? [];

    final totalAvailable = dashboardSummary?.availableBalance ??
        accountSummaries.fold<double>(0.0, (sum, a) => sum + a.currentBalance);

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Money Overview',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            if (onAddMoneyPressed != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onAddMoneyPressed,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Add Funds'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Grid / Row of overview cards
        if (isMobile)
          _buildMobileCards(context, totalAvailable, accountSummaries, inrFormat, isDark)
        else
          _buildDesktopCards(context, totalAvailable, accountSummaries, inrFormat, isDark),
      ],
    );
  }

  Widget _buildDesktopCards(
    BuildContext context,
    double totalAvailable,
    List<ExpenseAccountSummaryModel> accounts,
    NumberFormat inrFormat,
    bool isDark,
  ) {
    return Row(
      children: [
        // Total Available Card (Hero)
        Expanded(
          flex: 4,
          child: _OverviewHeroCard(
            title: 'Total Available Balance',
            amount: inrFormat.format(totalAvailable),
            subtitle: 'Aggregated Hytide Working Capital',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF0284C7),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Account Cards (Mugesh, Deepika, and other accounts)
        ...accounts.map((acc) {
          final isMugesh = acc.accountName.toLowerCase().contains('mugesh');
          final color = isMugesh ? const Color(0xFF10B981) : const Color(0xFF8B5CF6);

          return Expanded(
            flex: 3,
            child: _AccountBalanceCard(
              account: acc,
              formattedAmount: inrFormat.format(acc.currentBalance),
              color: color,
              isDark: isDark,
              onTap: () {
                context.push('${AppRoutes.expenses}/accounts/${acc.accountId}');
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileCards(
    BuildContext context,
    double totalAvailable,
    List<ExpenseAccountSummaryModel> accounts,
    NumberFormat inrFormat,
    bool isDark,
  ) {
    return Column(
      children: [
        // Total Available Hero Card
        _OverviewHeroCard(
          title: 'Total Available Balance',
          amount: inrFormat.format(totalAvailable),
          subtitle: 'Active Working Capital',
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF0284C7),
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Account Chips / Cards Row
        Row(
          children: accounts.map((acc) {
            final isMugesh = acc.accountName.toLowerCase().contains('mugesh');
            final color = isMugesh ? const Color(0xFF10B981) : const Color(0xFF8B5CF6);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: _AccountBalanceCard(
                  account: acc,
                  formattedAmount: inrFormat.format(acc.currentBalance),
                  color: color,
                  isDark: isDark,
                  isCompact: true,
                  onTap: () {
                    context.push('${AppRoutes.expenses}/accounts/${acc.accountId}');
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _OverviewHeroCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
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

class _AccountBalanceCard extends StatelessWidget {
  final ExpenseAccountSummaryModel account;
  final String formattedAmount;
  final Color color;
  final bool isDark;
  final bool isCompact;
  final VoidCallback onTap;

  const _AccountBalanceCard({
    required this.account,
    required this.formattedAmount,
    required this.color,
    required this.isDark,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        account.accountName.isNotEmpty
                            ? account.accountName[0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      account.accountName,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formattedAmount,
              style: (isCompact
                      ? AppTypography.titleMedium
                      : AppTypography.titleLarge)
                  .copyWith(
                fontWeight: FontWeight.w800,
                color: account.currentBalance > 0
                    ? color
                    : (account.currentBalance < 0
                        ? AppColors.error
                        : (isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariant)),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 2),
              Text(
                'Click for ledger history',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
