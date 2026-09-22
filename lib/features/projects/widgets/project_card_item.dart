// lib/features/projects/widgets/project_card_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_badge.dart';
import '../models/project_model.dart';

class ProjectCardItem extends ConsumerWidget {
  final ProjectModel project;
  final void Function(ProjectModel) onStatusChange;
  final void Function(ProjectModel) onProgressUpdate;
  final void Function(ProjectModel) onArchive;
  final void Function(ProjectModel) onDelete;

  const ProjectCardItem({
    super.key,
    required this.project,
    required this.onStatusChange,
    required this.onProgressUpdate,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final isOverdue = project.isOverdue;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.projects}/${project.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Project Number + Priority + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        project.projectNumber,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: project.priority.containerColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          project.priority.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: project.priority.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ProjectStatusBadge(status: project.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                project.title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Client / Company
              Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.companyName.isNotEmpty
                          ? '${project.companyName} (${project.clientName})'
                          : project.clientName,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${project.progress}%',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: project.progress / 100.0,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        project.progress == 100
                            ? AppColors.success
                            : (project.progress > 50
                                  ? AppColors.primary
                                  : AppColors.warning),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Bottom Row: Dates + Budget
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start: ${dateFormat.format(project.startDate ?? project.createdAt)}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.calendar_today_outlined,
                            size: 13,
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            project.expectedEndDate != null
                                ? 'Due: ${dateFormat.format(project.expectedEndDate!)}'
                                : 'No deadline',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isOverdue ? AppColors.error : null,
                              fontWeight: isOverdue ? FontWeight.w700 : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    inrFormat.format(
                      project.budget > 0
                          ? project.budget
                          : project.quotationValue,
                    ),
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('${AppRoutes.projects}/${project.id}'),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    onPressed: () => onProgressUpdate(project),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    tooltip: 'Update Progress',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.outlined(
                    onPressed: () => onStatusChange(project),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    tooltip: 'Change Status',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    tooltip: 'More',
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          context.push(
                            '${AppRoutes.projects}/${project.id}/edit',
                          );
                          break;
                        case 'archive':
                          onArchive(project);
                          break;
                        case 'delete':
                          onDelete(project);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined, size: 18),
                          title: Text('Edit Project'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: ListTile(
                          leading: Icon(
                            project.isArchived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                            size: 18,
                          ),
                          title: Text(
                            project.isArchived ? 'Restore' : 'Archive',
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
