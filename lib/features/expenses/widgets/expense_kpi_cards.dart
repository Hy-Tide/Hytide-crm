// lib/features/expenses/widgets/expense_kpi_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/expense_providers.dart';

class ExpenseKpiCards extends ConsumerWidget {
  const ExpenseKpiCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(expenseDashboardSummaryProvider);
    final summary = summaryAsync.valueOrNull;

    final inrFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final totalSpent = summary?.totalSpent ?? 0.0;
    final thisMonthSpent = summary?.thisMonthSpent ?? 0.0;
    final totalMoney = summary?.totalMoney ?? 0.0;

    final isMobile = MediaQuery.of(context).size.width < 768;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Total Money In',
                  value: inrFormat.format(totalMoney),
                  icon: Icons.savings_outlined,
                  color: const Color(0xFF0D9488),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _KpiCard(
                  label: 'Total Spent',
                  value: inrFormat.format(totalSpent),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFE11D48),
                  isDark: isDark,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Money Added',
                value: inrFormat.format(totalMoney),
                icon: Icons.savings_outlined,
                color: const Color(0xFF0D9488),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Total Spent (All Time)',
                value: inrFormat.format(totalSpent),
                icon: Icons.payments_outlined,
                color: const Color(0xFFE11D48),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'This Month Expenses',
                value: inrFormat.format(thisMonthSpent),
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
