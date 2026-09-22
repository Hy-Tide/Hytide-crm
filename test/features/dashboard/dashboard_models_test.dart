// test/features/dashboard/dashboard_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/features/dashboard/models/activity_model.dart';
import 'package:hytide/features/dashboard/models/dashboard_models.dart';
import 'package:hytide/core/constants/app_constants.dart';

void main() {
  group('DashboardDateRange calculations', () {
    final fixedNow = DateTime(2026, 9, 4, 15, 30); // Friday, Sep 4, 2026

    test('Today date range', () {
      final range = DashboardDateRange.today.calculateRange(now: fixedNow);
      expect(range.label, 'Today');
      expect(range.start, DateTime(2026, 9, 4));
      expect(range.end, DateTime(2026, 9, 4, 23, 59, 59, 999));
      expect(range.previousStart, DateTime(2026, 9, 3));
      expect(range.previousEnd, DateTime(2026, 9, 3, 23, 59, 59, 999));
    });

    test('This Week date range (Monday-Sunday)', () {
      final range = DashboardDateRange.thisWeek.calculateRange(now: fixedNow);
      expect(range.label, 'This Week');
      // Sep 4, 2026 is Friday (weekday 5). Monday is Aug 31, 2026.
      expect(range.start, DateTime(2026, 8, 31));
      expect(range.end, DateTime(2026, 9, 6, 23, 59, 59, 999));
    });

    test('This Month date range', () {
      final range = DashboardDateRange.thisMonth.calculateRange(now: fixedNow);
      expect(range.label, 'This Month');
      expect(range.start, DateTime(2026, 9, 1));
      expect(range.previousStart, DateTime(2026, 8, 1));
    });

    test('This Quarter date range (Q3)', () {
      final range = DashboardDateRange.thisQuarter.calculateRange(now: fixedNow);
      expect(range.label, 'This Quarter (Q3)');
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.previousStart, DateTime(2026, 4, 1));
    });

    test('This Year date range', () {
      final range = DashboardDateRange.thisYear.calculateRange(now: fixedNow);
      expect(range.label, 'This Year (2026)');
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.previousStart, DateTime(2025, 1, 1));
    });

    test('Custom date range', () {
      final customStart = DateTime(2026, 8, 1);
      final customEnd = DateTime(2026, 8, 15, 23, 59, 59);
      final range = DashboardDateRange.custom.calculateRange(
        customStart: customStart,
        customEnd: customEnd,
      );
      expect(range.label, 'Custom Range');
      expect(range.start, customStart);
      expect(range.end, customEnd);
    });
  });

  group('ConversionStats computations', () {
    test('Handles 0 leads safely without division by zero', () {
      final stats = ConversionStats.compute(
        totalLeads: 0,
        wonLeads: 0,
        lostLeads: 0,
      );
      expect(stats.conversionRate, 0.0);
      expect(stats.totalLeads, 0);
      expect(stats.wonLeads, 0);
      expect(stats.lostLeads, 0);
    });

    test('Computes conversion rate accurately', () {
      final stats = ConversionStats.compute(
        totalLeads: 75,
        wonLeads: 15,
        lostLeads: 10,
      );
      expect(stats.conversionRate, 20.0);
    });

    test('Rounds conversion rate to 1 decimal place', () {
      final stats = ConversionStats.compute(
        totalLeads: 3,
        wonLeads: 1,
        lostLeads: 0,
      );
      expect(stats.conversionRate, 33.3);
    });
  });

  group('DashboardKpiData growth calculations', () {
    test('Zero leads in previous period returns 100% when new leads exist', () {
      const kpi = DashboardKpiData(
        totalLeads: 10,
        newLeads: 5,
        newLeadsPreviousPeriod: 0,
      );
      expect(kpi.newLeadsGrowthPercentage, 100.0);
    });

    test('Zero leads in both periods returns 0.0%', () {
      const kpi = DashboardKpiData(
        totalLeads: 0,
        newLeads: 0,
        newLeadsPreviousPeriod: 0,
      );
      expect(kpi.newLeadsGrowthPercentage, 0.0);
    });

    test('Calculates positive and negative percentage changes', () {
      const positiveKpi = DashboardKpiData(
        newLeads: 150,
        newLeadsPreviousPeriod: 100,
      );
      expect(positiveKpi.newLeadsGrowthPercentage, 50.0);

      const negativeKpi = DashboardKpiData(
        newLeads: 80,
        newLeadsPreviousPeriod: 100,
      );
      expect(negativeKpi.newLeadsGrowthPercentage, -20.0);
    });
  });

  group('QuotationSummary computations', () {
    test('Computes pendingCount as draft + sent + viewed', () {
      final summary = QuotationSummary.fromCounts(
        draft: 4,
        sent: 6,
        viewed: 3,
        accepted: 5,
        rejected: 2,
        expired: 1,
      );
      expect(summary.pendingCount, 13);
      expect(summary.acceptedCount, 5);
      expect(summary.rejectedCount, 2);
      expect(summary.expiredCount, 1);
    });
  });

  group('ActivityModel relative timestamps', () {
    test('Just now for recent timestamp', () {
      final activity = ActivityModel(
        id: '1',
        type: ActivityType.leadCreated,
        description: 'New lead added',
        userName: 'Admin',
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(activity.relativeTime, 'Just now');
    });

    test('Minutes ago formatting', () {
      final activity = ActivityModel(
        id: '2',
        type: ActivityType.statusChanged,
        description: 'Status changed',
        userName: 'Admin',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(activity.relativeTime, '15 mins ago');
    });

    test('Hours ago formatting', () {
      final activity = ActivityModel(
        id: '3',
        type: ActivityType.followUpCompleted,
        description: 'Call completed',
        userName: 'Admin',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(activity.relativeTime, '3 hours ago');
    });

    test('Yesterday formatting', () {
      final activity = ActivityModel(
        id: '4',
        type: ActivityType.quotationCreated,
        description: 'Quotation generated',
        userName: 'Admin',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(activity.relativeTime, 'Yesterday');
    });
  });
}
