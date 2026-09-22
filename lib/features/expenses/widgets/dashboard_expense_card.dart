// lib/features/expenses/widgets/dashboard_expense_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/expense_providers.dart';

class DashboardExpenseCard extends ConsumerWidget {
  const DashboardExpenseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inrFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final dashboardSummaryAsync = ref.watch(expenseDashboardSummaryProvider);
    final accountSummariesAsync = ref.watch(expenseAccountSummariesProvider);

    final dashboardSummary = dashboardSummaryAsync.valueOrNull;
    final accountSummaries = accountSummariesAsync.valueOrNull ?? [];

    final totalMoney = dashboardSummary?.totalMoney ?? 0.0;
    final totalSpent = dashboardSummary?.totalSpent ?? 0.0;
    final availableBalance =
        dashboardSummary?.availableBalance ??
        accountSummaries.fold<double>(0.0, (s, a) => s + a.currentBalance);
    final thisMonthSpent = dashboardSummary?.thisMonthSpent ?? 0.0;

    return AppCard(
      onTap: () => context.push(AppRoutes.expenses),
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF0D9488),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Working Capital & Expenses',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Main 3 KPIs Row
          Row(
            children: [
              Expanded(
                child: _MiniKpi(
                  label: 'Total Money',
                  value: inrFormat.format(totalMoney),
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.borderDark : AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _MiniKpi(
                  label: 'Available Balance',
                  value: inrFormat.format(availableBalance),
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.borderDark : AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _MiniKpi(
                  label: 'Spent (Total)',
                  value: inrFormat.format(totalSpent),
                  color: const Color(0xFFE11D48),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Account Holders balances & This month row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: accountSummaries.map((acc) {
                    final isMugesh = acc.accountName.toLowerCase().contains(
                      'mugesh',
                    );
                    final color = isMugesh
                        ? const Color(0xFF10B981)
                        : const Color(0xFF8B5CF6);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: color),
                        const SizedBox(width: 5),
                        Text(
                          '${acc.accountName}: ',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.onSurfaceVariantDark
                                : AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          inrFormat.format(acc.currentBalance),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.onSurfaceDark
                                : AppColors.onSurface,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'This Month: ${inrFormat.format(thisMonthSpent)}',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniKpi({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: isDark
                ? AppColors.onSurfaceVariantDark
                : AppColors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
