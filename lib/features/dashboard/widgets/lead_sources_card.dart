// lib/features/dashboard/widgets/lead_sources_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class LeadSourcesCard extends ConsumerWidget {
  const LeadSourcesCard({super.key});

  Color _getSourceColor(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return const Color(0xFF2563EB); // Blue
      case LeadSource.googleMaps:
        return const Color(0xFFEA4335); // Google Red
      case LeadSource.referral:
        return const Color(0xFF10B981); // Emerald
      case LeadSource.instagram:
        return const Color(0xFFE1306C); // Insta Pink
      case LeadSource.facebook:
        return const Color(0xFF1877F2); // FB Blue
      case LeadSource.linkedin:
        return const Color(0xFF0A66C2); // LinkedIn Blue
      case LeadSource.whatsapp:
        return const Color(0xFF25D366); // WhatsApp Green
      case LeadSource.coldCall:
        return const Color(0xFFD97706); // Amber
      case LeadSource.email:
        return const Color(0xFF0284C7); // Sky Blue
      case LeadSource.direct:
        return const Color(0xFF8B5CF6); // Purple
      case LeadSource.freelancer:
        return const Color(0xFF9333EA); // Purple
      case LeadSource.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getSourceIcon(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return Icons.language_rounded;
      case LeadSource.googleMaps:
        return Icons.place_rounded;
      case LeadSource.referral:
        return Icons.people_outline_rounded;
      case LeadSource.instagram:
        return Icons.camera_alt_outlined;
      case LeadSource.facebook:
        return Icons.thumb_up_alt_outlined;
      case LeadSource.linkedin:
        return Icons.business_center_outlined;
      case LeadSource.whatsapp:
        return Icons.chat_bubble_outline_rounded;
      case LeadSource.coldCall:
        return Icons.phone_forwarded_rounded;
      case LeadSource.email:
        return Icons.alternate_email_rounded;
      case LeadSource.direct:
        return Icons.call_made_rounded;
      case LeadSource.freelancer:
        return Icons.work_outline_rounded;
      case LeadSource.other:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(dashboardSourcesProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Lead Sources',
            subtitle: 'Acquisition channels driving incoming inquiries',
          ),
          AppSpacing.gapH20,
          sourcesAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Lead Sources',
              message: 'Failed to load source analytics: $err',
              onRetry: () => ref.invalidate(dashboardSourcesProvider),
            ),
            data: (sources) {
              final total = sources.fold<int>(0, (sum, s) => sum + s.count);
              if (total == 0) {
                return const EmptyState(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No lead source data yet',
                  description: 'Track where your prospects find you to optimize marketing spend.',
                  iconSize: 40,
                );
              }

              return Column(
                children: [
                  // Segmented Bar Visual
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: sources.where((s) => s.count > 0).map((s) {
                          return Expanded(
                            flex: (s.percentage * 10).round().clamp(1, 1000),
                            child: Container(
                              color: _getSourceColor(s.source),
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  AppSpacing.gapH20,
                  // Grid / List of sources
                  ...sources.map((item) => _buildSourceRow(context, item, total)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSourceRow(BuildContext context, LeadSourceStats item, int total) {
    final color = _getSourceColor(item.source);
    final icon = _getSourceIcon(item.source);
    final ratio = total > 0 ? (item.count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: InkWell(
        onTap: () => context.go('${AppRoutes.leads}?source=${item.source.name}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Text(
                      item.source.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapW12,
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${item.percentage}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  AppSpacing.gapW4,
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              AppSpacing.gapH4,
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: Row(
            children: const [
              SkeletonBox(width: 16, height: 16, borderRadius: 8),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 14)),
              SizedBox(width: 16),
              SkeletonBox(width: 28, height: 14),
              SizedBox(width: 8),
              SkeletonBox(width: 36, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
