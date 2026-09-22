// test/features/dashboard/dashboard_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/features/dashboard/models/dashboard_models.dart';
import 'package:hytide/features/dashboard/providers/dashboard_providers.dart';
import 'package:hytide/features/dashboard/widgets/conversion_overview_card.dart';
import 'package:hytide/features/dashboard/widgets/dashboard_kpi_grid.dart';

void main() {
  testWidgets('DashboardKpiGrid renders all 8 cards with zero data safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardKpisProvider.overrideWith(
            (ref) async => const DashboardKpiData(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardKpiGrid(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Total Leads'), findsOneWidget);
    expect(find.text('New Leads'), findsOneWidget);
    expect(find.text("Today's Follow-ups"), findsOneWidget);
    expect(find.text('Overdue Follow-ups'), findsOneWidget);
    expect(find.text('Active Clients'), findsOneWidget);
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.text('Pending Quotations'), findsOneWidget);
    expect(find.text('Won Leads'), findsOneWidget);

    // Empty supporting texts
    expect(find.text('No leads yet'), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('No clients yet'), findsOneWidget);
    expect(find.text('No active projects'), findsOneWidget);
    expect(find.text('No pending quotes'), findsOneWidget);
    expect(find.text('No conversions yet'), findsOneWidget);
  });

  testWidgets('ConversionOverviewCard displays win rate and metrics', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardConversionProvider.overrideWith(
            (ref) async => const ConversionStats(
              totalLeads: 50,
              wonLeads: 12,
              lostLeads: 8,
              conversionRate: 24.0,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConversionOverviewCard(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Conversion Overview'), findsOneWidget);
    expect(find.text('24.0%'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    expect(find.text('Total Leads'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('Won'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}
