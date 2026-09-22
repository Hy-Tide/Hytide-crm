// lib/features/projects/widgets/project_action_dialogs.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../models/project_model.dart';
import '../services/project_status_service.dart';

class ProjectStatusChangeResult {
  final ProjectStatus newStatus;
  final String? reason;

  const ProjectStatusChangeResult({required this.newStatus, this.reason});
}

class ProjectActionDialogs {
  /// 1. Change Status Dialog with transition enforcement
  static Future<ProjectStatusChangeResult?> showStatusChangeDialog(
    BuildContext context,
    ProjectModel project,
  ) async {
    final allowed = ProjectStatusService.getAllowedTransitions(project.status);
    if (allowed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No further status transitions allowed for this project.')),
      );
      return null;
    }

    ProjectStatus selected = allowed.first;
    final reasonController = TextEditingController();

    final result = await showDialog<ProjectStatusChangeResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Update Project Status'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change status of ${project.projectNumber} - ${project.title}:',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Text('Current: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(project.status.displayName, style: TextStyle(color: project.status.color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Select New Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<ProjectStatus>(
                      value: selected,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: allowed.map((s) {
                        return DropdownMenuItem<ProjectStatus>(
                          value: s,
                          child: Row(
                            children: [
                              Icon(s.icon, size: 16, color: s.color),
                              const SizedBox(width: 8),
                              Text(s.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selected = val);
                        }
                      },
                    ),
                    if (selected == ProjectStatus.completed) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.success),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Marking as completed will automatically set progress to 100% and record completion date.',
                                style: TextStyle(fontSize: 12, color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Note (optional)',
                        hintText: 'e.g. Scope completed, client requested pause...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ProjectStatusChangeResult(
                        newStatus: selected,
                        reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
                      ),
                    );
                  },
                  child: const Text('Update Status'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  /// 2. Update Progress Dialog
  static Future<int?> showProgressDialog(BuildContext context, ProjectModel project) async {
    double currentVal = project.progress.toDouble();

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Icons.timelapse_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Update Progress'),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Set completion percentage for ${project.title}:', style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${currentVal.toInt()}%',
                      style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Slider(
                      value: currentVal,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${currentVal.toInt()}%',
                      onChanged: (val) {
                        setDialogState(() => currentVal = val);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(onPressed: () => setDialogState(() => currentVal = 0), child: const Text('0%')),
                        TextButton(onPressed: () => setDialogState(() => currentVal = 25), child: const Text('25%')),
                        TextButton(onPressed: () => setDialogState(() => currentVal = 50), child: const Text('50%')),
                        TextButton(onPressed: () => setDialogState(() => currentVal = 75), child: const Text('75%')),
                        TextButton(onPressed: () => setDialogState(() => currentVal = 100), child: const Text('100%')),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(currentVal.toInt()),
                  child: const Text('Save Progress'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  /// 3. Archive / Restore Dialog
  static Future<bool> showArchiveDialog(BuildContext context, ProjectModel project) async {
    final isArchived = project.isArchived;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              Icon(
                isArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
                color: isArchived ? AppColors.success : AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(isArchived ? 'Restore Project' : 'Archive Project'),
            ],
          ),
          content: Text(
            isArchived
                ? 'Restore ${project.projectNumber} to active projects list?'
                : 'Archive project ${project.projectNumber}? It will be hidden from default active views.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isArchived ? 'Restore' : 'Archive'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  /// 4. Delete Confirmation Dialog
  static Future<bool> showDeleteDialog(BuildContext context, ProjectModel project) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: const [
              Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 24),
              SizedBox(width: AppSpacing.sm),
              Text('Delete Project'),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete project ${project.projectNumber} (${project.title})? This action cannot be undone.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }
}
