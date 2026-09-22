import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../clients/models/client_model.dart';
import '../../followups/models/followup_model.dart';
import '../../projects/models/project_model.dart';
import '../models/activity_model.dart';
import '../models/dashboard_models.dart';
import '../repositories/dashboard_repository.dart';
import '../../expenses/providers/expense_providers.dart';

// ─── Date Range Filters ───────────────────────────────────────────────────────

final selectedDateRangeProvider = StateProvider<DashboardDateRange>((ref) {
  return DashboardDateRange.thisMonth;
});

final customDateRangeProvider = StateProvider<DateRangeValue?>((ref) => null);

final activeDateRangeProvider = Provider<DateRangeValue>((ref) {
  final selected = ref.watch(selectedDateRangeProvider);
  final custom = ref.watch(customDateRangeProvider);

  if (selected == DashboardDateRange.custom && custom != null) {
    return custom;
  }
  return selected.calculateRange();
});

// ─── Refresh Trigger & State ──────────────────────────────────────────────────

final dashboardRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final isDashboardRefreshingProvider = StateProvider<bool>((ref) => false);

// ─── Dashboard Section Providers ──────────────────────────────────────────────

final dashboardKpisProvider = FutureProvider<DashboardKpiData>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final range = ref.watch(activeDateRangeProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getKpiData(range);
});

final dashboardPipelineProvider = FutureProvider<List<LeadPipelineItem>>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final range = ref.watch(activeDateRangeProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getLeadPipeline(range);
});

final dashboardConversionProvider = FutureProvider<ConversionStats>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final range = ref.watch(activeDateRangeProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getConversionStats(range);
});

final dashboardSourcesProvider = FutureProvider<List<LeadSourceStats>>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final range = ref.watch(activeDateRangeProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getLeadSources(range);
});

final dashboardFollowUpSummaryProvider = FutureProvider<FollowUpSummary>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getFollowUpSummary();
});

final todaysFollowUpsStreamProvider = StreamProvider<List<FollowUpModel>>((ref) {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.streamTodaysFollowUps();
});

final overdueFollowUpsStreamProvider = StreamProvider<List<FollowUpModel>>((ref) {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.streamOverdueFollowUps();
});

final recentActivitiesStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.streamRecentActivities(limit: 10);
});

final activeClientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getActiveClients(limit: 5);
});

final activeProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getActiveProjects(limit: 5);
});

final quotationSummaryProvider = FutureProvider<QuotationSummary>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getQuotationSummary();
});

// ─── Event-driven Targeted Synchronization ──────────────────────────────────

/// Listens to central domain events and invalidates ONLY the affected dashboard providers
final dashboardSyncCoordinatorProvider = Provider<void>((ref) {
  final bus = ref.watch(appEventBusProvider);

  final sub = bus.stream.listen((event) {
    switch (event) {
      case LeadCreatedEvent():
      case LeadUpdatedEvent():
      case LeadStatusChangedEvent():
      case LeadDeletedEvent():
        // Invalidate ONLY lead-related metrics
        ref.invalidate(dashboardKpisProvider);
        ref.invalidate(dashboardPipelineProvider);
        ref.invalidate(dashboardConversionProvider);
        ref.invalidate(dashboardSourcesProvider);
        break;

      case FollowUpCreatedEvent():
      case FollowUpUpdatedEvent():
      case FollowUpCompletedEvent():
      case FollowUpCancelledEvent():
      case FollowUpDeletedEvent():
        // Invalidate ONLY follow-up metrics and KPIs
        ref.invalidate(dashboardFollowUpSummaryProvider);
        ref.invalidate(dashboardKpisProvider);
        break;

      case ClientCreatedEvent():
      case ClientUpdatedEvent():
      case ClientArchivedEvent():
      case ClientRestoredEvent():
      case ClientConvertedEvent():
        // Invalidate ONLY active clients list and overall KPIs
        ref.invalidate(activeClientsProvider);
        ref.invalidate(dashboardKpisProvider);
        break;

      case QuotationCreatedEvent():
      case QuotationUpdatedEvent():
      case QuotationStatusChangedEvent():
      case QuotationDeletedEvent():
        // Invalidate quotation metrics and overall KPIs
        ref.invalidate(quotationSummaryProvider);
        ref.invalidate(dashboardKpisProvider);
        break;

      case QuotationConvertedEvent():
        // Cross-module: quotation and project metrics
        ref.invalidate(quotationSummaryProvider);
        ref.invalidate(activeProjectsProvider);
        ref.invalidate(dashboardKpisProvider);
        break;

      case ProjectCreatedEvent():
      case ProjectUpdatedEvent():
      case ProjectStatusChangedEvent():
      case ProjectCompletedEvent():
      case ProjectArchivedEvent():
      case ProjectRestoredEvent():
      case ProjectDeletedEvent():
        // Invalidate ONLY project metrics and overall KPIs
        ref.invalidate(activeProjectsProvider);
        ref.invalidate(dashboardKpisProvider);
        break;

      case ExpenseCreatedEvent():
      case ExpenseUpdatedEvent():
      case ExpenseVoidedEvent():
      case MoneyAddedEvent():
        ref.invalidate(expenseDashboardSummaryProvider);
        ref.invalidate(expenseAccountSummariesProvider);
        break;
    }
  });

  ref.onDispose(sub.cancel);
});

// ─── Manual Refresh Action (Fallback) ────────────────────────────────────────

Future<void> triggerDashboardRefresh(WidgetRef ref) async {
  ref.read(isDashboardRefreshingProvider.notifier).state = true;
  ref.read(dashboardRefreshTriggerProvider.notifier).state++;

  // Invalidate individual future providers to ensure network reload
  ref.invalidate(dashboardKpisProvider);
  ref.invalidate(dashboardPipelineProvider);
  ref.invalidate(dashboardConversionProvider);
  ref.invalidate(dashboardSourcesProvider);
  ref.invalidate(dashboardFollowUpSummaryProvider);
  ref.invalidate(activeClientsProvider);
  ref.invalidate(activeProjectsProvider);
  ref.invalidate(quotationSummaryProvider);

  // Small delay for smooth UI feedback
  await Future.delayed(const Duration(milliseconds: 600));
  ref.read(isDashboardRefreshingProvider.notifier).state = false;
}

