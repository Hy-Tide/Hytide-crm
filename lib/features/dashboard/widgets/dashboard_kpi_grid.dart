// lib/features/dashboard/widgets/dashboard_kpi_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class DashboardKpiGrid extends ConsumerWidget {
  const DashboardKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardKpisProvider);

    return kpisAsync.when(
      loading: () => _buildSkeleton(context),
      error: (err, _) => SectionErrorCard(
        title: 'KPI Metrics',
        message: 'Could not load KPI totals: $err',
        onRetry: () => ref.invalidate(dashboardKpisProvider),
      ),
      data: (kpi) => _buildGrid(context, kpi),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1024 ? 4 : (width >= 640 ? 2 : 1);

    return GridView.builder(
      itemCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.s16,
        mainAxisSpacing: AppSpacing.s16,
        mainAxisExtent: 116,
      ),
      itemBuilder: (_, index) => const SkeletonStatCard(),
    );
  }

  Widget _buildGrid(BuildContext context, DashboardKpiData kpi) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1024 ? 4 : (width >= 640 ? 2 : 1);
    final formatter = NumberFormat('#,###');

    final growth = kpi.newLeadsGrowthPercentage;
    final growthText = growth != null && growth != 0
        ? '${growth > 0 ? '+' : ''}$growth% vs prev period'
        : (kpi.newLeads == 0 ? 'No leads created' : 'Same as prev period');

    final cards = [
      _KpiCardData(
        title: 'Total Leads',
        value: formatter.format(kpi.totalLeads),
        subtitle: kpi.totalLeads == 0 ? 'No leads yet' : 'All-time pipeline',
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
        onTap: () => context.go(AppRoutes.leads),
      ),
      _KpiCardData(
        title: 'New Leads',
        value: formatter.format(kpi.newLeads),
        subtitle: growthText,
        icon: Icons.person_add_alt_1_rounded,
        iconColor: AppColors.info,
        iconBgColor: AppColors.infoContainer,
        comparisonPositive: growth != null && growth > 0,
        onTap: () => context.go('${AppRoutes.leads}?status=newLead'),
      ),
      _KpiCardData(
        title: "Today's Follow-ups",
        value: formatter.format(kpi.todaysFollowups),
        subtitle: kpi.todaysFollowups == 0 ? 'No follow-ups today' : 'Scheduled for today',
        icon: Icons.today_rounded,
        iconColor: AppColors.warning,
        iconBgColor: AppColors.warningContainer,
        onTap: () => context.go('${AppRoutes.followups}?filter=today'),
      ),
      _KpiCardData(
        title: 'Overdue Follow-ups',
        value: formatter.format(kpi.overdueFollowups),
        subtitle: kpi.overdueFollowups == 0 ? "You're all caught up" : 'Needs urgent attention',
        icon: Icons.warning_amber_rounded,
        iconColor: kpi.overdueFollowups > 0 ? AppColors.error : AppColors.success,
        iconBgColor: kpi.overdueFollowups > 0 ? AppColors.errorContainer : AppColors.successContainer,
        isWarning: kpi.overdueFollowups > 0,
        onTap: () => context.go('${AppRoutes.followups}?filter=overdue'),
      ),
      _KpiCardData(
        title: 'Active Clients',
        value: formatter.format(kpi.activeClients),
        subtitle: kpi.activeClients == 0 ? 'No clients yet' : 'Onboarded accounts',
        icon: Icons.business_rounded,
        iconColor: AppColors.secondary,
        iconBgColor: AppColors.secondaryContainer,
        onTap: () => context.go(AppRoutes.clients),
      ),
      _KpiCardData(
        title: 'Active Projects',
        value: formatter.format(kpi.activeProjects),
        subtitle: kpi.activeProjects == 0 ? 'No active projects' : 'In-flight deliverables',
        icon: Icons.folder_open_rounded,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
        onTap: () => context.go('${AppRoutes.projects}?status=active'),
      ),
      _KpiCardData(
        title: 'Pending Quotations',
        value: formatter.format(kpi.pendingQuotations),
        subtitle: kpi.pendingQuotations == 0 ? 'No pending quotes' : 'Draft, sent & viewed',
        icon: Icons.request_quote_rounded,
        iconColor: AppColors.info,
        iconBgColor: AppColors.infoContainer,
        onTap: () => context.go('${AppRoutes.quotations}?filter=pending'),
      ),
      _KpiCardData(
        title: 'Won Leads',
        value: formatter.format(kpi.wonLeads),
        subtitle: kpi.wonLeads == 0 ? 'No conversions yet' : 'Successfully closed',
        icon: Icons.verified_rounded,
        iconColor: AppColors.success,
        iconBgColor: AppColors.successContainer,
        onTap: () => context.go('${AppRoutes.leads}?status=won'),
      ),
    ];

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.s16,
        mainAxisSpacing: AppSpacing.s16,
        mainAxisExtent: 120,
      ),
      itemBuilder: (context, index) {
        final item = cards[index];
        return AppCard(
          onTap: item.onTap,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.gapW8,
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 18, color: item.iconColor),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.value,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: item.isWarning ? AppColors.error : null,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (item.comparisonPositive != null) ...[
                    Icon(
                      item.comparisonPositive!
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: item.comparisonPositive! ? AppColors.success : AppColors.textMuted,
                    ),
                    AppSpacing.gapW4,
                  ],
                  Expanded(
                    child: Text(
                      item.subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: item.isWarning
                            ? AppColors.error
                            : (item.comparisonPositive == true
                                ? AppColors.success
                                : AppColors.textMuted),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool? comparisonPositive;
  final bool isWarning;
  final VoidCallback onTap;

  const _KpiCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.comparisonPositive,
    this.isWarning = false,
    required this.onTap,
  });
}
