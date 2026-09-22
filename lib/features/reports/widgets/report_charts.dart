// lib/features/reports/widgets/report_charts.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/report_providers.dart';

class WonLostBarChartCard extends StatelessWidget {
  final ReportMetrics metrics;

  const WonLostBarChartCard({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wonCount = metrics.wonLeads.toDouble();
    final lostCount = metrics.lostLeads.toDouble();
    final maxCount = (wonCount > lostCount ? wonCount : lostCount);
    final maxY = maxCount < 5 ? 5.0 : maxCount * 1.25;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Won vs. Lost Performance',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Deal conversion outcomes & lost opportunities',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendIndicator('Won (${metrics.wonLeads})', AppColors.success),
                  const SizedBox(width: AppSpacing.md),
                  _buildLegendIndicator('Lost (${metrics.lostLeads})', AppColors.error),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Value stats highlight
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Won Value', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        metrics.wonRevenue.formatted,
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lost Opportunity', style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        metrics.lostValue.formatted,
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Bar Chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? AppColors.surfaceContainerDark : Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isWon = group.x == 0;
                      return BarTooltipItem(
                        '${isWon ? "Won" : "Lost"}: ${rod.toY.toInt()} Deals\n${isWon ? metrics.wonRevenue.formatted : metrics.lostValue.formatted}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            val.toInt() == 0 ? 'Closed Won' : 'Closed Lost',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: val.toInt() == 0 ? AppColors.success : AppColors.error,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        if (val % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          val.toInt().toString(),
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: wonCount,
                        color: AppColors.success,
                        width: 42,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: lostCount,
                        color: AppColors.error,
                        width: 42,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class LeadSourcesPieChartCard extends StatelessWidget {
  final ReportMetrics metrics;

  const LeadSourcesPieChartCard({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceCounts = metrics.leadSourceDistribution;
    final total = metrics.totalLeads;

    final sourceColors = {
      LeadSource.website: const Color(0xFF3B82F6),
      LeadSource.referral: const Color(0xFF10B981),
      LeadSource.linkedin: const Color(0xFF0284C7),
      LeadSource.googleMaps: const Color(0xFFF59E0B),
      LeadSource.instagram: const Color(0xFFE1306C),
      LeadSource.facebook: const Color(0xFF1877F2),
      LeadSource.whatsapp: const Color(0xFF25D366),
      LeadSource.coldCall: const Color(0xFFF97316),
      LeadSource.email: const Color(0xFF6366F1),
      LeadSource.direct: const Color(0xFF14B8A6),
      LeadSource.other: const Color(0xFF8B5CF6),
    };

    final sections = <PieChartSectionData>[];

    for (final source in LeadSource.values) {
      final count = sourceCounts[source] ?? 0;
      if (count > 0) {
        final pct = total == 0 ? 0.0 : (count / total) * 100;
        final color = sourceColors[source] ?? AppColors.primary;
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            color: color,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 54,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lead Acquisition Channels',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Where your new business opportunities originate',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (total == 0)
            const SizedBox(
              height: 220,
              child: Center(child: Text('No leads found for this period')),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: LeadSource.values.map((source) {
                      final count = sourceCounts[source] ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      final color = sourceColors[source] ?? AppColors.primary;
                      final pct = (count / total) * 100;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                source.displayName,
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$count (${pct.toStringAsFixed(0)}%)',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class PipelineFunnelCard extends StatelessWidget {
  final ReportMetrics metrics;

  const PipelineFunnelCard({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusCounts = metrics.leadStatusDistribution;
    final total = metrics.totalLeads;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pipeline Stage Funnel',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active deals progressing through each sales stage',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$total Total Deals',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No leads recorded in this period')),
            )
          else
            ...LeadStatus.values.map((status) {
              final count = statusCounts[status] ?? 0;
              final pct = total == 0 ? 0.0 : count / total;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.displayName,
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '$count deals  ·  ${(pct * 100).toStringAsFixed(1)}%',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
