// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../widgets/android_dashboard_view.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/active_clients_card.dart';
import '../widgets/active_projects_card.dart';
import '../widgets/conversion_overview_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/followup_overview_card.dart';
import '../widgets/lead_pipeline_card.dart';
import '../widgets/lead_sources_card.dart';
import '../widgets/overdue_followups_card.dart';
import '../widgets/quotation_summary_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/todays_followups_card.dart';
import '../../expenses/widgets/dashboard_expense_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dashboardSyncCoordinatorProvider);

    if (PlatformCapabilities.isAndroid) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: AndroidDashboardView(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 768;
          final isTablet = width >= 768 && width < 1100;

          Widget content;
          if (isMobile) {
            content = _buildMobileLayout(context);
          } else if (isTablet) {
            content = _buildTabletLayout(context);
          } else {
            content = _buildDesktopLayout(context);
          }

          return RefreshIndicator(
            onRefresh: () => triggerDashboardRefresh(ref),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desktop / Tablet Breadcrumbs
                  if (!isMobile) ...[
                    const Breadcrumbs(
                      items: [
                        BreadcrumbItem(label: 'Home', route: AppRoutes.dashboard),
                        BreadcrumbItem(label: 'Dashboard'),
                      ],
                    ),
                    AppSpacing.gapH12,
                  ],

                  // Dashboard Header with Greetings, Date Filter & Refresh
                  const DashboardHeader(),
                  AppSpacing.gapH24,

                  // Main Responsive Layout
                  content,

                  AppSpacing.gapH32,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Desktop Layout ─────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. KPI Cards Grid (4 per row)
        const DashboardKpiGrid(),
        AppSpacing.gapH24,

        // 1.1 Working Capital & Expense Summary Card
        const DashboardExpenseCard(),
        AppSpacing.gapH24,

        // 2. Row: Lead Pipeline (flex 7) | Conversion Overview (flex 5)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: LeadPipelineCard()),
            AppSpacing.gapW24,
            Expanded(flex: 5, child: ConversionOverviewCard()),
          ],
        ),
        AppSpacing.gapH24,

        // 3. Row: Today's Follow-ups (flex 7) | Needs Attention / Overdue (flex 5)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: TodaysFollowupsCard()),
            AppSpacing.gapW24,
            Expanded(flex: 5, child: OverdueFollowupsCard()),
          ],
        ),
        AppSpacing.gapH24,

        // 4. Row: Lead Sources (flex 6) | Follow-up Stats (flex 6)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: LeadSourcesCard()),
            AppSpacing.gapW24,
            Expanded(flex: 6, child: FollowupOverviewCard()),
          ],
        ),
        AppSpacing.gapH24,

        // 5. Row: Active Clients (flex 6) | Active Projects (flex 6)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: ActiveClientsCard()),
            AppSpacing.gapW24,
            Expanded(flex: 6, child: ActiveProjectsCard()),
          ],
        ),
        AppSpacing.gapH24,

        // 6. Row: Quotation Overview (flex 6) | Recent Activity (flex 6)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: QuotationSummaryCard()),
            AppSpacing.gapW24,
            Expanded(flex: 6, child: RecentActivityCard()),
          ],
        ),
      ],
    );
  }

  // ─── Tablet Layout ──────────────────────────────────────────────────────────

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. KPI Cards Grid (2 per row)
        const DashboardKpiGrid(),
        AppSpacing.gapH20,

        // Working Capital & Expenses
        const DashboardExpenseCard(),
        AppSpacing.gapH20,

        // 2. Today's Follow-ups | Needs Attention
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: TodaysFollowupsCard()),
            AppSpacing.gapW16,
            Expanded(child: OverdueFollowupsCard()),
          ],
        ),
        AppSpacing.gapH20,

        // 3. Lead Pipeline | Conversion Overview
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: LeadPipelineCard()),
            AppSpacing.gapW16,
            Expanded(child: ConversionOverviewCard()),
          ],
        ),
        AppSpacing.gapH20,

        // 4. Lead Sources | Follow-up Overview
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: LeadSourcesCard()),
            AppSpacing.gapW16,
            Expanded(child: FollowupOverviewCard()),
          ],
        ),
        AppSpacing.gapH20,

        // 5. Active Projects | Active Clients
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ActiveProjectsCard()),
            AppSpacing.gapW16,
            Expanded(child: ActiveClientsCard()),
          ],
        ),
        AppSpacing.gapH20,

        // 6. Quotation Overview | Recent Activity
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: QuotationSummaryCard()),
            AppSpacing.gapW16,
            Expanded(child: RecentActivityCard()),
          ],
        ),
      ],
    );
  }

  // ─── Mobile / Android Layout ────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    // Mobile order specified in prompt:
    // Header (rendered above)
    // Date Filter (rendered in header)
    // Important KPIs
    // Today's Follow-ups
    // Needs Attention
    // Lead Pipeline
    // Conversion
    // Lead Sources
    // Active Projects
    // Active Clients
    // Quotation Overview
    // Recent Activity
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // 1. Important KPIs Grid
        DashboardKpiGrid(),
        AppSpacing.gapH16,

        // 1.1 Working Capital & Expenses
        DashboardExpenseCard(),
        AppSpacing.gapH16,

        // 2. Today's Follow-ups
        TodaysFollowupsCard(),
        AppSpacing.gapH16,

        // 3. Needs Attention
        OverdueFollowupsCard(),
        AppSpacing.gapH16,

        // 4. Lead Pipeline
        LeadPipelineCard(),
        AppSpacing.gapH16,

        // 5. Conversion Overview
        ConversionOverviewCard(),
        AppSpacing.gapH16,

        // 6. Lead Sources
        LeadSourcesCard(),
        AppSpacing.gapH16,

        // 7. Follow-up Overview
        FollowupOverviewCard(),
        AppSpacing.gapH16,

        // 8. Active Projects
        ActiveProjectsCard(),
        AppSpacing.gapH16,

        // 9. Active Clients
        ActiveClientsCard(),
        AppSpacing.gapH16,

        // 10. Quotation Overview
        QuotationSummaryCard(),
        AppSpacing.gapH16,

        // 11. Recent Activity
        RecentActivityCard(),
      ],
    );
  }
}
