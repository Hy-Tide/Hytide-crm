// lib/features/reports/widgets/report_kpi_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/report_providers.dart';

class ReportKpiHeader extends ConsumerWidget {
  const ReportKpiHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(reportMetricsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

        final cards = [
          _KpiData(
            label: 'Total Pipeline',
            value: metrics.totalPipelineValue.formatted,
            subtitle: '${metrics.totalLeads} Total Leads',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
          ),
          _KpiData(
            label: 'Closed Won Revenue',
            value: metrics.wonRevenue.formatted,
            subtitle: '${metrics.wonLeads} Deals Won',
            icon: Icons.verified_rounded,
            color: AppColors.success,
          ),
          _KpiData(
            label: 'Lead Conversion',
            value: '${metrics.leadConversionRate.toStringAsFixed(1)}%',
            subtitle: '${metrics.wonLeads} Won · ${metrics.lostLeads} Lost',
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
          _KpiData(
            label: 'Quotation Win Rate',
            value: '${metrics.quotationWinRate.toStringAsFixed(1)}%',
            subtitle: '${metrics.acceptedQuotations} of ${metrics.totalQuotations} Approved',
            icon: Icons.request_quote_rounded,
            color: AppColors.info,
          ),
          _KpiData(
            label: 'Average Deal Size',
            value: metrics.averageDealSize.formatted,
            subtitle: 'Avg estimated value',
            icon: Icons.pie_chart_rounded,
            color: const Color(0xFF8B5CF6),
          ),
        ];

        if (isMobile) {
          return SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 200,
                  child: _buildCard(context, cards[index]),
                );
              },
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 5,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: isTablet ? 1.9 : 1.75,
          ),
          itemBuilder: (context, index) {
            return _buildCard(context, cards[index]);
          },
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, _KpiData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
