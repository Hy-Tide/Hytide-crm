// lib/features/reports/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../leads/repositories/lead_repository.dart';
import '../providers/report_providers.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_kpi_header.dart';
import '../widgets/report_quotation_summary.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  void _exportSummary(BuildContext context, ReportMetrics metrics, ReportPeriod period) {
    final buffer = StringBuffer();
    buffer.writeln('HYTIDE CRM - EXECUTIVE REPORT SUMMARY');
    buffer.writeln('Period: ${period.label}');
    buffer.writeln('Generated: ${DateTime.now().formattedWithTime}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Total Leads: ${metrics.totalLeads}');
    buffer.writeln('Won Deals: ${metrics.wonLeads} (${metrics.leadConversionRate.toStringAsFixed(1)}%)');
    buffer.writeln('Lost Deals: ${metrics.lostLeads}');
    buffer.writeln('Total Pipeline Value: ${metrics.totalPipelineValue.formatted}');
    buffer.writeln('Closed Won Revenue: ${metrics.wonRevenue.formatted}');
    buffer.writeln('Average Deal Size: ${metrics.averageDealSize.formatted}');
    buffer.writeln('Total Quotations: ${metrics.totalQuotations}');
    buffer.writeln('Accepted Quotations: ${metrics.acceptedQuotations} (${metrics.quotationWinRate.toStringAsFixed(1)}%)');
    buffer.writeln('Quoted Amount: ${metrics.totalQuotedAmount.formatted}');
    buffer.writeln('Accepted Amount: ${metrics.acceptedQuotedAmount.formatted}');
    buffer.writeln('Active Projects: ${metrics.activeProjects}');
    buffer.writeln('Completed Projects: ${metrics.completedProjects}');
    buffer.writeln('Average Project Progress: ${metrics.averageProjectProgress.toStringAsFixed(0)}%');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppToast.success(context, 'Executive report summary copied to clipboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final period = ref.watch(reportPeriodProvider);
    final metrics = ref.watch(reportMetricsProvider);
    final leadsAsync = ref.watch(leadsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            const Breadcrumbs(
              items: [
                BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                BreadcrumbItem(label: 'Reports & Analytics'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Page Header Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports & Analytics',
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pipeline velocity, commercial outcomes, revenue analytics, and performance tracking.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: AppSpacing.md),
                      _buildPeriodSelector(ref, period, isDark),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: () => _exportSummary(context, metrics, period),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export Summary'),
                      ),
                    ],
                  ],
                );
              },
            ),

            // Mobile Controls Row
            if (MediaQuery.of(context).size.width < 650) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _buildPeriodSelector(ref, period, isDark)),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => _exportSummary(context, metrics, period),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Export'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Content
            leadsAsync.when(
              loading: () => Column(
                children: List.generate(
                  4,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: SkeletonCard(),
                  ),
                ),
              ),
              error: (err, _) => AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('Error loading reports data: $err')),
              ),
              data: (_) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    const ReportKpiHeader(),
                    const SizedBox(height: AppSpacing.xl),

                    // Primary Charts Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 950;

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: WonLostBarChartCard(metrics: metrics)),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(flex: 4, child: LeadSourcesPieChartCard(metrics: metrics)),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            WonLostBarChartCard(metrics: metrics),
                            const SizedBox(height: AppSpacing.md),
                            LeadSourcesPieChartCard(metrics: metrics),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Pipeline Stage Funnel
                    PipelineFunnelCard(metrics: metrics),
                    const SizedBox(height: AppSpacing.xl),

                    // Quotations & Projects Delivery Health
                    QuotationProjectSummaryCards(metrics: metrics),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(WidgetRef ref, ReportPeriod period, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: DropdownButton<ReportPeriod>(
        value: period,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(AppRadius.md),
        icon: const Icon(Icons.calendar_month_rounded, size: 18),
        items: ReportPeriod.values.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Text(p.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          );
        }).toList(),
        onChanged: (newVal) {
          if (newVal != null) {
            ref.read(reportPeriodProvider.notifier).state = newVal;
          }
        },
      ),
    );
  }
}
