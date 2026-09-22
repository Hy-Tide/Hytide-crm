// lib/features/dashboard/models/dashboard_models.dart
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

enum DashboardDateRange {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisYear,
  custom;

  String get displayName {
    switch (this) {
      case DashboardDateRange.today:
        return 'Today';
      case DashboardDateRange.thisWeek:
        return 'This Week';
      case DashboardDateRange.thisMonth:
        return 'This Month';
      case DashboardDateRange.thisQuarter:
        return 'This Quarter';
      case DashboardDateRange.thisYear:
        return 'This Year';
      case DashboardDateRange.custom:
        return 'Custom Range';
    }
  }

  DateRangeValue calculateRange({
    DateTime? now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final current = now ?? DateTime.now();
    final startOfToday = DateTime(current.year, current.month, current.day);
    final endOfToday = DateTime(current.year, current.month, current.day, 23, 59, 59, 999);

    switch (this) {
      case DashboardDateRange.today:
        return DateRangeValue(
          start: startOfToday,
          end: endOfToday,
          label: 'Today',
          previousStart: startOfToday.subtract(const Duration(days: 1)),
          previousEnd: endOfToday.subtract(const Duration(days: 1)),
        );

      case DashboardDateRange.thisWeek:
        // Week starts Monday (weekday 1)
        final weekday = current.weekday;
        final startOfWeek = DateTime(current.year, current.month, current.day - (weekday - 1));
        final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59, 999);
        final prevStart = startOfWeek.subtract(const Duration(days: 7));
        final prevEnd = DateTime(prevStart.year, prevStart.month, prevStart.day + 6, 23, 59, 59, 999);
        return DateRangeValue(
          start: startOfWeek,
          end: endOfWeek,
          label: 'This Week',
          previousStart: prevStart,
          previousEnd: prevEnd,
        );

      case DashboardDateRange.thisMonth:
        final startOfMonth = DateTime(current.year, current.month, 1);
        final nextMonth = current.month == 12 ? 1 : current.month + 1;
        final nextYear = current.month == 12 ? current.year + 1 : current.year;
        final endOfMonth = DateTime(nextYear, nextMonth, 1).subtract(const Duration(milliseconds: 1));

        final prevMonthYear = current.month == 1 ? current.year - 1 : current.year;
        final prevMonthNum = current.month == 1 ? 12 : current.month - 1;
        final prevStart = DateTime(prevMonthYear, prevMonthNum, 1);
        final prevEnd = DateTime(current.year, current.month, 1).subtract(const Duration(milliseconds: 1));

        return DateRangeValue(
          start: startOfMonth,
          end: endOfMonth,
          label: 'This Month',
          previousStart: prevStart,
          previousEnd: prevEnd,
        );

      case DashboardDateRange.thisQuarter:
        final quarter = ((current.month - 1) / 3).floor();
        final startQuarterMonth = quarter * 3 + 1;
        final startOfQuarter = DateTime(current.year, startQuarterMonth, 1);
        final endQuarterMonth = startQuarterMonth + 2;
        final nextMonthAfterQuarter = endQuarterMonth == 12 ? 1 : endQuarterMonth + 1;
        final nextYearAfterQuarter = endQuarterMonth == 12 ? current.year + 1 : current.year;
        final endOfQuarter = DateTime(nextYearAfterQuarter, nextMonthAfterQuarter, 1)
            .subtract(const Duration(milliseconds: 1));

        final prevQuarterMonth = startQuarterMonth == 1 ? 10 : startQuarterMonth - 3;
        final prevQuarterYear = startQuarterMonth == 1 ? current.year - 1 : current.year;
        final prevStart = DateTime(prevQuarterYear, prevQuarterMonth, 1);
        final prevEnd = startOfQuarter.subtract(const Duration(milliseconds: 1));

        return DateRangeValue(
          start: startOfQuarter,
          end: endOfQuarter,
          label: 'This Quarter (Q${quarter + 1})',
          previousStart: prevStart,
          previousEnd: prevEnd,
        );

      case DashboardDateRange.thisYear:
        final startOfYear = DateTime(current.year, 1, 1);
        final endOfYear = DateTime(current.year, 12, 31, 23, 59, 59, 999);
        final prevStart = DateTime(current.year - 1, 1, 1);
        final prevEnd = DateTime(current.year - 1, 12, 31, 23, 59, 59, 999);
        return DateRangeValue(
          start: startOfYear,
          end: endOfYear,
          label: 'This Year (${current.year})',
          previousStart: prevStart,
          previousEnd: prevEnd,
        );

      case DashboardDateRange.custom:
        final s = customStart ?? startOfToday;
        final e = customEnd ?? endOfToday;
        final duration = e.difference(s);
        final prevStart = s.subtract(duration);
        final prevEnd = s.subtract(const Duration(milliseconds: 1));
        return DateRangeValue(
          start: s,
          end: e,
          label: 'Custom Range',
          previousStart: prevStart,
          previousEnd: prevEnd,
        );
    }
  }
}

class DateRangeValue extends Equatable {
  final DateTime start;
  final DateTime end;
  final String label;
  final DateTime previousStart;
  final DateTime previousEnd;

  const DateRangeValue({
    required this.start,
    required this.end,
    required this.label,
    required this.previousStart,
    required this.previousEnd,
  });

  @override
  List<Object?> get props => [start, end, label, previousStart, previousEnd];
}

class DashboardKpiData extends Equatable {
  final int totalLeads;
  final int newLeads;
  final int newLeadsPreviousPeriod;
  final int todaysFollowups;
  final int overdueFollowups;
  final int activeClients;
  final int activeProjects;
  final int pendingQuotations;
  final int wonLeads;

  const DashboardKpiData({
    this.totalLeads = 0,
    this.newLeads = 0,
    this.newLeadsPreviousPeriod = 0,
    this.todaysFollowups = 0,
    this.overdueFollowups = 0,
    this.activeClients = 0,
    this.activeProjects = 0,
    this.pendingQuotations = 0,
    this.wonLeads = 0,
  });

  double? get newLeadsGrowthPercentage {
    if (newLeadsPreviousPeriod == 0) {
      return newLeads > 0 ? 100.0 : 0.0;
    }
    final change = ((newLeads - newLeadsPreviousPeriod) / newLeadsPreviousPeriod) * 100;
    return double.parse(change.toStringAsFixed(1));
  }

  @override
  List<Object?> get props => [
        totalLeads,
        newLeads,
        newLeadsPreviousPeriod,
        todaysFollowups,
        overdueFollowups,
        activeClients,
        activeProjects,
        pendingQuotations,
        wonLeads,
      ];
}

class LeadPipelineItem extends Equatable {
  final LeadStatus status;
  final int count;
  final double percentage;

  const LeadPipelineItem({
    required this.status,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [status, count, percentage];
}

class ConversionStats extends Equatable {
  final int totalLeads;
  final int wonLeads;
  final int lostLeads;
  final double conversionRate;

  const ConversionStats({
    this.totalLeads = 0,
    this.wonLeads = 0,
    this.lostLeads = 0,
    this.conversionRate = 0.0,
  });

  factory ConversionStats.compute({
    required int totalLeads,
    required int wonLeads,
    required int lostLeads,
  }) {
    final rate = totalLeads > 0
        ? double.parse(((wonLeads / totalLeads) * 100).toStringAsFixed(1))
        : 0.0;
    return ConversionStats(
      totalLeads: totalLeads,
      wonLeads: wonLeads,
      lostLeads: lostLeads,
      conversionRate: rate,
    );
  }

  @override
  List<Object?> get props => [totalLeads, wonLeads, lostLeads, conversionRate];
}

class LeadSourceStats extends Equatable {
  final LeadSource source;
  final int count;
  final double percentage;

  const LeadSourceStats({
    required this.source,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [source, count, percentage];
}

class FollowUpSummary extends Equatable {
  final int todayCount;
  final int upcomingCount;
  final int overdueCount;
  final int completedCount;

  const FollowUpSummary({
    this.todayCount = 0,
    this.upcomingCount = 0,
    this.overdueCount = 0,
    this.completedCount = 0,
  });

  @override
  List<Object?> get props => [
        todayCount,
        upcomingCount,
        overdueCount,
        completedCount,
      ];
}

class QuotationSummary extends Equatable {
  final int draftCount;
  final int sentCount;
  final int viewedCount;
  final int acceptedCount;
  final int rejectedCount;
  final int expiredCount;
  final int pendingCount;

  const QuotationSummary({
    this.draftCount = 0,
    this.sentCount = 0,
    this.viewedCount = 0,
    this.acceptedCount = 0,
    this.rejectedCount = 0,
    this.expiredCount = 0,
    this.pendingCount = 0,
  });

  factory QuotationSummary.fromCounts({
    int draft = 0,
    int sent = 0,
    int viewed = 0,
    int accepted = 0,
    int rejected = 0,
    int expired = 0,
  }) {
    return QuotationSummary(
      draftCount: draft,
      sentCount: sent,
      viewedCount: viewed,
      acceptedCount: accepted,
      rejectedCount: rejected,
      expiredCount: expired,
      pendingCount: draft + sent + viewed,
    );
  }

  @override
  List<Object?> get props => [
        draftCount,
        sentCount,
        viewedCount,
        acceptedCount,
        rejectedCount,
        expiredCount,
        pendingCount,
      ];
}
