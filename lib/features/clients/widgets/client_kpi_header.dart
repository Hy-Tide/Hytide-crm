// lib/features/clients/widgets/client_kpi_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/client_filter_model.dart';
import '../providers/client_providers.dart';

class ClientKpiHeader extends ConsumerWidget {
  const ClientKpiHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(clientKpiCountsProvider);
    final filter = ref.watch(clientFilterProvider);

    return countsAsync.when(
      loading: () => _buildSkeleton(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (counts) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

            final cards = [
              _KpiCardData(
                label: 'Total Clients',
                count: counts.total,
                icon: Icons.business_rounded,
                color: AppColors.primary,
                isSelected: !filter.hasActiveFilters,
                onTap: () {
                  ref.read(clientFilterProvider.notifier).state = const ClientFilter();
                },
              ),
              _KpiCardData(
                label: 'Active Clients',
                count: counts.active,
                icon: Icons.verified_rounded,
                color: AppColors.success,
                isSelected: filter.status == ClientStatus.active && !filter.showArchived,
                onTap: () {
                  final cur = ref.read(clientFilterProvider);
                  if (cur.status == ClientStatus.active) {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(status: () => null);
                  } else {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(status: () => ClientStatus.active, showArchived: false);
                  }
                },
              ),
              _KpiCardData(
                label: 'New Clients',
                count: counts.newClients,
                icon: Icons.fiber_new_rounded,
                color: AppColors.info,
                isSelected: filter.clientType == ClientType.newClient,
                onTap: () {
                  final cur = ref.read(clientFilterProvider);
                  if (cur.clientType == ClientType.newClient) {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(clientType: () => null);
                  } else {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(clientType: () => ClientType.newClient);
                  }
                },
              ),
              _KpiCardData(
                label: 'Inactive Clients',
                count: counts.inactive,
                icon: Icons.pause_circle_outline_rounded,
                color: AppColors.warning,
                isSelected: filter.status == ClientStatus.inactive,
                onTap: () {
                  final cur = ref.read(clientFilterProvider);
                  if (cur.status == ClientStatus.inactive) {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(status: () => null);
                  } else {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(status: () => ClientStatus.inactive);
                  }
                },
              ),
              _KpiCardData(
                label: 'Repeat Clients',
                count: counts.repeat,
                icon: Icons.replay_rounded,
                color: AppColors.secondary,
                isSelected: filter.clientType == ClientType.repeatClient,
                onTap: () {
                  final cur = ref.read(clientFilterProvider);
                  if (cur.clientType == ClientType.repeatClient) {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(clientType: () => null);
                  } else {
                    ref.read(clientFilterProvider.notifier).state =
                        cur.copyWith(clientType: () => ClientType.repeatClient);
                  }
                },
              ),
            ];

            if (isMobile) {
              return SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 170,
                      child: _buildCard(context, cards[index]),
                    );
                  },
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 5,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: isTablet ? 2.2 : 2.0,
              ),
              itemBuilder: (context, index) {
                return _buildCard(context, cards[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, _KpiCardData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: data.isSelected
              ? data.color.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: data.isSelected
                ? data.color
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: data.isSelected ? 1.5 : 1,
          ),
          boxShadow: data.isSelected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.count}',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.label,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final count = isMobile ? 3 : 5;
        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, __) => Container(
              width: 170,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KpiCardData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiCardData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
}
