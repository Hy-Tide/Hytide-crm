// lib/features/dashboard/widgets/active_projects_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/project_status_badge.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../projects/models/project_model.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class ActiveProjectsCard extends ConsumerWidget {
  const ActiveProjectsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(activeProjectsProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      onTap: () => context.go('${AppRoutes.projects}?status=active'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Active Projects',
            subtitle: 'Deliverables currently in planning or execution',
          ),
          AppSpacing.gapH20,
          projectsAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Active Projects',
              message: 'Failed to load projects: $err',
              onRetry: () => ref.invalidate(activeProjectsProvider),
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return const EmptyState(
                  icon: Icons.folder_outlined,
                  title: 'No active projects',
                  description:
                      'Active deliverables and milestones will be tracked here once started.',
                  iconSize: 40,
                );
              }

              return ListView.separated(
                itemCount: projects.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, index) => const Divider(
                  height: AppSpacing.s16,
                  color: AppColors.surfaceBorder,
                ),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _buildProjectRow(context, project);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, ProjectModel project) {
    final dateStr = project.expectedEndDate != null
        ? 'Due ${DateFormat('MMM d, yyyy').format(project.expectedEndDate!)}'
        : 'No due date';

    return InkWell(
      onTap: () => context.go('${AppRoutes.projects}/${project.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: project.status.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 18,
                color: project.status.color,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          project.name.isNotEmpty
                              ? project.name
                              : 'Untitled Project',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (project.clientName.isNotEmpty) ...[
                        Text(
                          project.clientName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      Text(
                        dateStr,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              SkeletonBox(width: 36, height: 36, borderRadius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 150),
                    SizedBox(height: 6),
                    SkeletonBox(height: 10, width: 110),
                  ],
                ),
              ),
              SkeletonBox(width: 60, height: 22, borderRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
