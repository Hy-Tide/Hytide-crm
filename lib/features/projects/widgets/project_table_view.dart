// lib/features/projects/widgets/project_table_view.dart
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

class ProjectTableView extends ConsumerWidget {
  final List<ProjectModel> projects;
  final void Function(ProjectModel) onStatusChange;
  final void Function(ProjectModel) onProgressUpdate;
  final void Function(ProjectModel) onArchive;
  final void Function(ProjectModel) onDelete;

  const ProjectTableView({
    super.key,
    required this.projects,
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
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1150),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.backgroundDark : AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 68,
              horizontalMargin: AppSpacing.lg,
              columnSpacing: AppSpacing.lg,
              columns: const [
                DataColumn(label: Text('Project #', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Project Title & Type', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Progress', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Start Date', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Deadline', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Budget', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Manager', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: projects.map((p) {
                final isOverdue = p.isOverdue;

                return DataRow(
                  onSelectChanged: (_) => context.push('${AppRoutes.projects}/${p.id}'),
                  cells: [
                    // 1. Project #
                    DataCell(
                      Text(
                        p.projectNumber,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    // 2. Title & Type
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.projectType.displayName,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Client
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.companyName.isNotEmpty ? p.companyName : p.clientName,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.companyName.isNotEmpty && p.clientName.isNotEmpty)
                              Text(
                                p.clientName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 4. Status Badge
                    DataCell(ProjectStatusBadge(status: p.status)),

                    // 5. Priority
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.priority.containerColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          p.priority.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: p.priority.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 6. Progress
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${p.progress}%', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              child: LinearProgressIndicator(
                                value: p.progress / 100.0,
                                minHeight: 6,
                                backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  p.progress == 100
                                      ? AppColors.success
                                      : (p.progress > 50 ? AppColors.primary : AppColors.warning),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 7. Start Date
                    DataCell(
                      Text(dateFormat.format(p.startDate ?? p.createdAt), style: AppTypography.bodySmall),
                    ),

                    // 8. Deadline
                    DataCell(
                      p.expectedEndDate != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(p.expectedEndDate!),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isOverdue ? AppColors.error : null,
                                    fontWeight: isOverdue ? FontWeight.w700 : null,
                                  ),
                                ),
                                if (isOverdue)
                                  Text(
                                    'Overdue',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            )
                          : const Text('—', style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ),

                    // 9. Budget
                    DataCell(
                      Text(
                        inrFormat.format(p.budget > 0 ? p.budget : p.quotationValue),
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                        ),
                      ),
                    ),

                    // 10. Manager
                    DataCell(
                      Text(
                        p.projectManagerName.isNotEmpty ? p.projectManagerName : 'Unassigned',
                        style: AppTypography.bodySmall,
                      ),
                    ),

                    // 11. Actions Menu
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        tooltip: 'Actions',
                        onSelected: (action) {
                          switch (action) {
                            case 'view':
                              context.push('${AppRoutes.projects}/${p.id}');
                              break;
                            case 'edit':
                              context.push('${AppRoutes.projects}/${p.id}/edit');
                              break;
                            case 'status':
                              onStatusChange(p);
                              break;
                            case 'progress':
                              onProgressUpdate(p);
                              break;
                            case 'archive':
                              onArchive(p);
                              break;
                            case 'delete':
                              onDelete(p);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: ListTile(
                              leading: Icon(Icons.visibility_outlined, size: 18),
                              title: Text('View Details'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined, size: 18),
                              title: Text('Edit Project'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'progress',
                            child: ListTile(
                              leading: Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                              title: Text('Update Progress'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'status',
                            child: ListTile(
                              leading: Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.info),
                              title: Text('Change Status'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: ListTile(
                              leading: Icon(
                                p.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                size: 18,
                              ),
                              title: Text(p.isArchived ? 'Restore' : 'Archive'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              title: Text('Delete', style: TextStyle(color: AppColors.error)),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
