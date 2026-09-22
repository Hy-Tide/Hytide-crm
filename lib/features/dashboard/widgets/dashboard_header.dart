// lib/features/dashboard/widgets/dashboard_header.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'date_range_picker_dialog.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final displayName = (user?.displayName != null && user!.displayName.isNotEmpty)
        ? user.displayName
        : 'Admin';
    final greeting = '${_getGreeting()}, $displayName';

    final selectedRange = ref.watch(selectedDateRangeProvider);
    final activeRange = ref.watch(activeDateRangeProvider);
    final isRefreshing = ref.watch(isDashboardRefreshingProvider);

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline connectivity indicator banner
        StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            final isOffline = snapshot.hasData &&
                snapshot.data!.every((r) => r == ConnectivityResult.none);
            if (!isOffline) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.s16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.warning),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Text(
                      "You're offline. Showing available data.",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Main Header Row / Column
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              AppSpacing.gapH4,
              Text(
                "Here's what's happening with your sales pipeline.",
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapH16,
              Row(
                children: [
                  Expanded(
                    child: _buildDateRangeSelector(context, ref, selectedRange, activeRange),
                  ),
                  AppSpacing.gapW12,
                  _buildRefreshButton(ref, isRefreshing),
                ],
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Text(
                      "Here's what's happening with your sales pipeline.",
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW16,
              _buildDateRangeSelector(context, ref, selectedRange, activeRange),
              AppSpacing.gapW12,
              _buildRefreshButton(ref, isRefreshing),
            ],
          ),
      ],
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    WidgetRef ref,
    DashboardDateRange selectedRange,
    DateRangeValue activeRange,
  ) {
    return PopupMenuButton<DashboardDateRange>(
      initialValue: selectedRange,
      tooltip: 'Select date filter',
      onSelected: (range) async {
        if (range == DashboardDateRange.custom) {
          final custom = await CustomDateRangePickerDialog.show(
            context,
            initialRange: activeRange,
          );
          if (custom != null) {
            ref.read(customDateRangeProvider.notifier).state = custom;
            ref.read(selectedDateRangeProvider.notifier).state = DashboardDateRange.custom;
          }
        } else {
          ref.read(selectedDateRangeProvider.notifier).state = range;
        }
      },
      itemBuilder: (context) => [
        for (final r in DashboardDateRange.values)
          PopupMenuItem<DashboardDateRange>(
            value: r,
            child: Row(
              children: [
                Icon(
                  r == selectedRange ? Icons.check_rounded : Icons.circle_outlined,
                  size: 16,
                  color: r == selectedRange ? AppColors.primary : Colors.transparent,
                ),
                AppSpacing.gapW8,
                Text(
                  r.displayName,
                  style: TextStyle(
                    fontWeight: r == selectedRange ? FontWeight.w600 : FontWeight.normal,
                    color: r == selectedRange ? AppColors.primary : null,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.onSurfaceVariant),
            AppSpacing.gapW8,
            Text(
              selectedRange == DashboardDateRange.custom
                  ? activeRange.label
                  : selectedRange.displayName,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            AppSpacing.gapW8,
            const Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(WidgetRef ref, bool isRefreshing) {
    return SizedBox(
      height: 44,
      width: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRefreshing ? null : () => triggerDashboardRefresh(ref),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}
