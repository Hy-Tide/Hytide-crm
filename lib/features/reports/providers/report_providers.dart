// lib/features/reports/providers/report_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../followups/repositories/followup_repository.dart';
import '../../leads/repositories/lead_repository.dart';
import '../../projects/repositories/project_repository.dart';
import '../../quotations/repositories/quotation_repository.dart';

enum ReportPeriod {
  allTime('All Time'),
  last30Days('Last 30 Days'),
  thisMonth('This Month'),
  thisQuarter('This Quarter'),
  thisYear('This Year');

  final String label;
  const ReportPeriod(this.label);

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.allTime:
        return null;
      case ReportPeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.thisQuarter:
        final currentQuarter = (now.month - 1) ~/ 3;
        return DateTime(now.year, currentQuarter * 3 + 1, 1);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
    }
  }
}

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.allTime);

class ReportMetrics {
  final int totalLeads;
  final int wonLeads;
  final int lostLeads;
  final int activeLeads;
  final double leadConversionRate;
  final double totalPipelineValue;
  final double wonRevenue;
  final double lostValue;
  final double averageDealSize;
  final Map<LeadStatus, int> leadStatusDistribution;
  final Map<LeadSource, int> leadSourceDistribution;
  final Map<LeadSource, double> leadSourceValues;

  // Quotations
  final int totalQuotations;
  final int acceptedQuotations;
  final double quotationWinRate;
  final double totalQuotedAmount;
  final double acceptedQuotedAmount;

  // Projects
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final double averageProjectProgress;

  // Followups
  final int followupsCompleted;
  final int followupsTotal;
  final double followupCompletionRate;

  const ReportMetrics({
    this.totalLeads = 0,
    this.wonLeads = 0,
    this.lostLeads = 0,
    this.activeLeads = 0,
    this.leadConversionRate = 0.0,
    this.totalPipelineValue = 0.0,
    this.wonRevenue = 0.0,
    this.lostValue = 0.0,
    this.averageDealSize = 0.0,
    this.leadStatusDistribution = const {},
    this.leadSourceDistribution = const {},
    this.leadSourceValues = const {},
    this.totalQuotations = 0,
    this.acceptedQuotations = 0,
    this.quotationWinRate = 0.0,
    this.totalQuotedAmount = 0.0,
    this.acceptedQuotedAmount = 0.0,
    this.totalProjects = 0,
    this.activeProjects = 0,
    this.completedProjects = 0,
    this.averageProjectProgress = 0.0,
    this.followupsCompleted = 0,
    this.followupsTotal = 0,
    this.followupCompletionRate = 0.0,
  });
}

final reportMetricsProvider = Provider<ReportMetrics>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final startDate = period.startDate;

  final allLeads = ref.watch(leadsStreamProvider).asData?.value ?? [];
  final allQuotations = ref.watch(quotationsStreamProvider).asData?.value ?? [];
  final allProjects = ref.watch(projectsStreamProvider).asData?.value ?? [];
  final allFollowups = ref.watch(followupsStreamProvider).asData?.value ?? [];

  // Filter Leads by Period
  final leads = startDate == null
      ? allLeads
      : allLeads.where((l) => l.createdAt.isAfter(startDate)).toList();

  // Filter Quotations by Period
  final quotations = startDate == null
      ? allQuotations
      : allQuotations.where((q) => q.createdAt.isAfter(startDate)).toList();

  // Filter Projects by Period
  final projects = startDate == null
      ? allProjects
      : allProjects.where((p) => p.createdAt.isAfter(startDate)).toList();

  // Filter Followups by Period
  final followups = startDate == null
      ? allFollowups
      : allFollowups.where((f) => f.createdAt.isAfter(startDate)).toList();

  // Compute Lead Metrics
  int wonLeads = 0;
  int lostLeads = 0;
  int activeLeads = 0;
  double pipelineValue = 0.0;
  double wonRev = 0.0;
  double lostVal = 0.0;

  final statusDist = <LeadStatus, int>{};
  final sourceDist = <LeadSource, int>{};
  final sourceVals = <LeadSource, double>{};

  for (final status in LeadStatus.values) {
    statusDist[status] = 0;
  }
  for (final source in LeadSource.values) {
    sourceDist[source] = 0;
    sourceVals[source] = 0.0;
  }

  for (final lead in leads) {
    pipelineValue += lead.estimatedValue;
    statusDist[lead.status] = (statusDist[lead.status] ?? 0) + 1;
    sourceDist[lead.source] = (sourceDist[lead.source] ?? 0) + 1;
    sourceVals[lead.source] = (sourceVals[lead.source] ?? 0.0) + lead.estimatedValue;

    if (lead.status == LeadStatus.won) {
      wonLeads++;
      wonRev += lead.estimatedValue;
    } else if (lead.status == LeadStatus.lost) {
      lostLeads++;
      lostVal += lead.estimatedValue;
    } else {
      activeLeads++;
    }
  }

  final convRate = leads.isEmpty ? 0.0 : (wonLeads / leads.length) * 100.0;
  final avgDeal = leads.isEmpty ? 0.0 : pipelineValue / leads.length;

  // Compute Quotation Metrics
  int acceptedQuotes = 0;
  double totalQuoted = 0.0;
  double acceptedQuoted = 0.0;

  for (final quote in quotations) {
    totalQuoted += quote.grandTotal;
    if (quote.status == QuotationStatus.accepted) {
      acceptedQuotes++;
      acceptedQuoted += quote.grandTotal;
    }
  }

  final quoteWinRate = quotations.isEmpty ? 0.0 : (acceptedQuotes / quotations.length) * 100.0;

  // Compute Project Metrics
  int activeProjects = 0;
  int completedProjects = 0;
  double totalProgress = 0.0;

  for (final p in projects) {
    totalProgress += p.progress;
    if (p.status == ProjectStatus.completed) {
      completedProjects++;
    } else if (p.status != ProjectStatus.cancelled) {
      activeProjects++;
    }
  }

  final avgProgress = projects.isEmpty ? 0.0 : totalProgress / projects.length;

  // Compute Followup Metrics
  int completedFollowups = 0;
  for (final f in followups) {
    if (f.status == FollowUpStatus.completed) {
      completedFollowups++;
    }
  }
  final followupRate = followups.isEmpty ? 0.0 : (completedFollowups / followups.length) * 100.0;

  return ReportMetrics(
    totalLeads: leads.length,
    wonLeads: wonLeads,
    lostLeads: lostLeads,
    activeLeads: activeLeads,
    leadConversionRate: convRate,
    totalPipelineValue: pipelineValue,
    wonRevenue: wonRev,
    lostValue: lostVal,
    averageDealSize: avgDeal,
    leadStatusDistribution: statusDist,
    leadSourceDistribution: sourceDist,
    leadSourceValues: sourceVals,
    totalQuotations: quotations.length,
    acceptedQuotations: acceptedQuotes,
    quotationWinRate: quoteWinRate,
    totalQuotedAmount: totalQuoted,
    acceptedQuotedAmount: acceptedQuoted,
    totalProjects: projects.length,
    activeProjects: activeProjects,
    completedProjects: completedProjects,
    averageProjectProgress: avgProgress,
    followupsCompleted: completedFollowups,
    followupsTotal: followups.length,
    followupCompletionRate: followupRate,
  );
});
