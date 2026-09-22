// lib/features/users/widgets/user_kpi_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/user_providers.dart';

class UserKpiHeader extends ConsumerWidget {
  const UserKpiHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(userKpiProvider);
    final activeRole = ref.watch(userRoleFilterProvider);
    final activeStatus = ref.watch(userStatusFilterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

        final cards = [
          _KpiCardData(
            label: 'Total Team',
            count: kpi.totalCount,
            icon: Icons.groups_rounded,
            color: AppColors.primary,
            isSelected: activeRole == UserRoleFilter.all && activeStatus == UserStatusFilter.all,
            onTap: () {
              ref.read(userRoleFilterProvider.notifier).state = UserRoleFilter.all;
              ref.read(userStatusFilterProvider.notifier).state = UserStatusFilter.all;
            },
          ),
          _KpiCardData(
            label: 'Administrators',
            count: kpi.adminCount,
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFFDC2626),
            isSelected: activeRole == UserRoleFilter.admin,
            onTap: () {
              final cur = ref.read(userRoleFilterProvider);
              ref.read(userRoleFilterProvider.notifier).state =
                  cur == UserRoleFilter.admin ? UserRoleFilter.all : UserRoleFilter.admin;
            },
          ),
          _KpiCardData(
            label: 'Managers',
            count: kpi.managerCount,
            icon: Icons.supervisor_account_rounded,
            color: const Color(0xFFF59E0B),
            isSelected: activeRole == UserRoleFilter.manager,
            onTap: () {
              final cur = ref.read(userRoleFilterProvider);
              ref.read(userRoleFilterProvider.notifier).state =
                  cur == UserRoleFilter.manager ? UserRoleFilter.all : UserRoleFilter.manager;
            },
          ),
          _KpiCardData(
            label: 'Sales Staff',
            count: kpi.salesStaffCount,
            icon: Icons.support_agent_rounded,
            color: const Color(0xFF2563EB),
            isSelected: activeRole == UserRoleFilter.salesStaff,
            onTap: () {
              final cur = ref.read(userRoleFilterProvider);
              ref.read(userRoleFilterProvider.notifier).state =
                  cur == UserRoleFilter.salesStaff ? UserRoleFilter.all : UserRoleFilter.salesStaff;
            },
          ),
          _KpiCardData(
            label: 'Active Accounts',
            count: kpi.activeCount,
            icon: Icons.verified_user_rounded,
            color: AppColors.success,
            isSelected: activeStatus == UserStatusFilter.active,
            onTap: () {
              final cur = ref.read(userStatusFilterProvider);
              ref.read(userStatusFilterProvider.notifier).state =
                  cur == UserStatusFilter.active ? UserStatusFilter.all : UserStatusFilter.active;
            },
          ),
        ];

        if (isMobile) {
          return SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 175,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
}

class _KpiCardData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _KpiCardData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.onTap,
  });
}
