// lib/features/dashboard/widgets/android_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/repositories/auth_repository.dart';
import '../providers/dashboard_providers.dart';
import 'active_projects_card.dart';
import 'lead_pipeline_card.dart';
import 'recent_activity_card.dart';
import 'todays_followups_card.dart';
import '../../expenses/widgets/dashboard_expense_card.dart';

class AndroidDashboardView extends ConsumerWidget {
  const AndroidDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserModelProvider).valueOrNull;
    var firstName = currentUser?.displayName.split(' ').first ?? 'User';
    if (firstName.isNotEmpty) {
      firstName = '${firstName[0].toUpperCase()}${firstName.substring(1)}';
    }
    final kpisAsync = ref.watch(dashboardKpisProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => triggerDashboardRefresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Gradient Hero Header
            SliverToBoxAdapter(
              child: _GradientHeroHeader(
                firstName: firstName,
                isDark: isDark,
                onRefresh: () => triggerDashboardRefresh(ref),
                kpisAsync: kpisAsync,
                onLeadsTap: () => context.go(AppRoutes.leads),
                onProjectsTap: () => context.go(AppRoutes.projects),
                onFollowupsTap: () => context.go(AppRoutes.followups),
              ),
            ),
            
            // Section padding
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Quick Actions',
                    style: AppTypography.heading3.copyWith(
                      color: isDark ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildQuickActionsGrid(context, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Other existing cards
                  const TodaysFollowupsCard(),
                  const SizedBox(height: AppSpacing.lg),
                  const DashboardExpenseCard(),
                  const SizedBox(height: AppSpacing.lg),
                  const LeadPipelineCard(),
                  const SizedBox(height: AppSpacing.lg),
                  const ActiveProjectsCard(),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Recent Activity',
                    style: AppTypography.heading3.copyWith(
                      color: isDark ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const RecentActivityCard(),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.person_add_alt_1_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
            onTap: () => context.go('${AppRoutes.leads}/create'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.event_available_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () => context.push(AppRoutes.followupCreate),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.create_new_folder_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () => context.push(AppRoutes.projectCreate),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientHeroHeader extends StatelessWidget {
  final String firstName;
  final bool isDark;
  final VoidCallback onRefresh;
  final AsyncValue<dynamic> kpisAsync;
  final VoidCallback onLeadsTap;
  final VoidCallback onProjectsTap;
  final VoidCallback onFollowupsTap;

  const _GradientHeroHeader({
    required this.firstName,
    required this.isDark,
    required this.onRefresh,
    required this.kpisAsync,
    required this.onLeadsTap,
    required this.onProjectsTap,
    required this.onFollowupsTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topPadding + AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getGreetingIcon(),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getGreeting(),
                              style: AppTypography.heading3.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          firstName,
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                      onPressed: onRefresh,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                kpisAsync.when(
                  data: (data) => _buildGrid(context, data),
                  loading: () => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, dynamic data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassKpiStat(
                label: 'Leads',
                value: '${data.totalLeads}',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF60A5FA),
                onTap: onLeadsTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassKpiStat(
                label: 'Projects',
                value: '${data.activeProjects}',
                icon: Icons.folder_rounded,
                color: const Color(0xFF34D399),
                onTap: onProjectsTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassKpiStat(
                label: 'Today\'s',
                value: '${data.todaysFollowups}',
                icon: Icons.event_note_rounded,
                color: const Color(0xFFFBBF24),
                onTap: onFollowupsTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GlassKpiStat(
                label: 'Won',
                value: '${data.wonLeads}',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFA78BFA),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassKpiStat(
                label: 'Quotes',
                value: '${data.pendingQuotations}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF38BDF8),
                onTap: () => context.go(AppRoutes.quotations),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassKpiStat(
                label: 'Clients',
                value: '${data.activeClients}',
                icon: Icons.domain_rounded,
                color: const Color(0xFFF472B6),
                onTap: () => context.go(AppRoutes.clients),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassKpiStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlassKpiStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
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
