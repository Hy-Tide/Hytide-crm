// lib/features/projects/screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/project_milestone_model.dart';
import '../models/project_model.dart';
import '../models/project_requirement_model.dart';
import '../models/project_task_model.dart';
import '../providers/project_providers.dart';
import '../repositories/project_repository.dart';
import '../widgets/project_action_dialogs.dart';
import '../../expenses/widgets/expense_project_tab.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleStatusChange(ProjectModel project) async {
    final result = await ProjectActionDialogs.showStatusChangeDialog(context, project);
    if (result != null && mounted) {
      try {
        await ref.read(projectRepositoryProvider).updateProjectStatus(
          project.id,
          result.newStatus,
          reason: result.reason,
        );
        ref.read(appEventBusProvider).emit(
          ProjectStatusChangedEvent(
            project.copyWith(status: result.newStatus),
            oldStatus: project.status,
            newStatus: result.newStatus,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project status updated to ${result.newStatus.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleProgressUpdate(ProjectModel project) async {
    final progress = await ProjectActionDialogs.showProgressDialog(context, project);
    if (progress != null && mounted) {
      try {
        await ref.read(projectRepositoryProvider).updateProjectProgress(project.id, progress);
        ref.read(appEventBusProvider).emit(
          ProjectUpdatedEvent(project.copyWith(progress: progress)),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progress updated to $progress%'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update progress: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleArchive(ProjectModel project) async {
    final confirmed = await ProjectActionDialogs.showArchiveDialog(context, project);
    if (confirmed && mounted) {
      try {
        final bus = ref.read(appEventBusProvider);
        if (project.isArchived) {
          await ref.read(projectRepositoryProvider).restoreProject(project.id);
          bus.emit(ProjectRestoredEvent(project.id));
        } else {
          await ref.read(projectRepositoryProvider).archiveProject(project.id);
          bus.emit(ProjectArchivedEvent(project.id));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(project.isArchived ? 'Project restored' : 'Project moved to archive'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update archive: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleAddNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingNote = true);
    try {
      await ref.read(projectRepositoryProvider).addProjectNote(widget.projectId, text);
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internal note added'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add note: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectAsync = ref.watch(projectDetailStreamProvider(widget.projectId));

    return projectAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: ErrorState(message: 'Error loading project: $e'),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
            body: const EmptyState(icon: Icons.folder_off_rounded, title: 'Project not found'),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
          appBar: AppBar(
            leading: PlatformCapabilities.isAndroid
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.projects);
                      }
                    },
                  )
                : null,
            title: Text('${project.projectNumber} — ${project.title}'),
            actions: [
              IconButton(
                onPressed: () => _handleProgressUpdate(project),
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Update Progress',
              ),
              IconButton(
                onPressed: () => _handleStatusChange(project),
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'Change Status',
              ),
              IconButton(
                onPressed: () => context.push('${AppRoutes.projects}/${project.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Project',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More',
                onSelected: (action) {
                  if (action == 'archive') {
                    _handleArchive(project);
                  } else if (action == 'client') {
                    context.push('${AppRoutes.clients}/${project.clientId}');
                  } else if (action == 'quotation' && project.sourceQuotationId != null) {
                    context.push('${AppRoutes.quotations}/${project.sourceQuotationId}');
                  }
                },
                itemBuilder: (context) => [
                  if (project.clientId.isNotEmpty)
                    const PopupMenuItem(
                      value: 'client',
                      child: ListTile(
                        leading: Icon(Icons.business_rounded, size: 18),
                        title: Text('View Client'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  if (project.sourceQuotationId != null && project.sourceQuotationId!.isNotEmpty)
                    const PopupMenuItem(
                      value: 'quotation',
                      child: ListTile(
                        leading: Icon(Icons.receipt_long_outlined, size: 18),
                        title: Text('View Source Quotation'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(
                        project.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        size: 18,
                      ),
                      title: Text(project.isArchived ? 'Restore Project' : 'Archive Project'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Requirements'),
                Tab(text: 'Tasks'),
                Tab(text: 'Milestones'),
                Tab(text: 'Documents'),
                Tab(text: 'Payments'),
                Tab(text: 'Expenses'),
                Tab(text: 'Activity'),
                Tab(text: 'Notes'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(project),
              _buildRequirementsTab(project),
              _buildTasksTab(project),
              _buildMilestonesTab(project),
              _buildDocumentsTab(project),
              _buildPaymentsTab(project),
              ExpenseProjectTab(project: project),
              _buildActivityTab(project),
              _buildNotesTab(project),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 1: OVERVIEW ───────────────────────────────────────────────────────
  Widget _buildOverviewTab(ProjectModel project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isOverdue = project.isOverdue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!PlatformCapabilities.isAndroid) ...[
                Breadcrumbs(
                  items: [
                    const BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                    const BreadcrumbItem(label: 'Projects', route: AppRoutes.projects),
                    BreadcrumbItem(label: project.projectNumber),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Hero Status Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(
                    color: isOverdue ? AppColors.error.withValues(alpha: 0.5) : (isDark ? AppColors.borderDark : AppColors.border),
                  ),
                ),
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                project.projectNumber,
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: project.priority.containerColor,
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  project.priority.displayName,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: project.priority.color,
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
                      Text(project.title, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        onTap: () => context.push('${AppRoutes.clients}/${project.clientId}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              project.companyName.isNotEmpty
                                  ? '${project.companyName} (${project.clientName})'
                                  : project.clientName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Overall Completion', style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
                              Text('${project.progress}%', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: LinearProgressIndicator(
                              value: project.progress / 100.0,
                              minHeight: 10,
                              backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                project.progress == 100
                                    ? AppColors.success
                                    : (project.progress > 50 ? AppColors.primary : AppColors.warning),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Budget',
                      value: inrFormat.format(project.budget > 0 ? project.budget : project.quotationValue),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Start Date',
                      value: dateFormat.format(project.startDate ?? project.createdAt),
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Deadline',
                      value: project.expectedEndDate != null
                          ? dateFormat.format(project.expectedEndDate!)
                          : 'No deadline',
                      icon: isOverdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      color: isOverdue ? AppColors.error : AppColors.success,
                      subtitle: isOverdue ? 'Overdue' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project Specifications', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.md),
                      _buildDetailRow('Project Type', project.projectType.displayName),
                      _buildDetailRow('Project Manager', project.projectManagerName.isNotEmpty ? project.projectManagerName : 'Unassigned'),
                      if (project.sourceQuotationId != null && project.sourceQuotationId!.isNotEmpty)
                        _buildDetailRow(
                          'Source Quotation',
                          (project.quotationNumber != null && project.quotationNumber!.isNotEmpty)
                              ? project.quotationNumber!
                              : project.sourceQuotationId!,
                          onTap: () => context.push('${AppRoutes.quotations}/${project.sourceQuotationId}'),
                        ),
                      if (project.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Scope Description', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(project.description, style: AppTypography.bodyMedium),
                      ],
                      if (project.notes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Text('Internal Notes', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(project.notes, style: AppTypography.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB 2: REQUIREMENTS ───────────────────────────────────────────────────
  Widget _buildRequirementsTab(ProjectModel project) {
    final reqsAsync = ref.watch(projectRequirementsProvider(project.id));

    return reqsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: 'Failed to load requirements: $e'),
      data: (requirements) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${requirements.length} ${requirements.length == 1 ? "Requirement" : "Requirements"}',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddRequirementDialog(project.id),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Requirement'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (requirements.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.checklist_rounded,
                  title: 'No requirements recorded yet',
                  subtitle: 'Define functional, UI/UX, or technical requirements for this project.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: requirements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final r = requirements[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(r.description),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(r.category, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                Text('Status: ${r.status}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          onPressed: () => ref.read(projectRepositoryProvider).deleteProjectRequirement(project.id, r.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── TAB 3: TASKS ──────────────────────────────────────────────────────────
  Widget _buildTasksTab(ProjectModel project) {
    final tasksAsync = ref.watch(projectTasksProvider(project.id));
    final dateFormat = DateFormat('dd MMM yyyy');

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: 'Failed to load tasks: $e'),
      data: (tasks) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tasks.where((t) => t.isCompleted).length}/${tasks.length} Completed',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddTaskDialog(project.id),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (tasks.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'No tasks yet',
                  subtitle: 'Create deliverables and action items for your team.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return Card(
                      child: CheckboxListTile(
                        value: t.isCompleted,
                        onChanged: (val) {
                          final newStatus = (val == true) ? 'completed' : 'todo';
                          final updated = ProjectTaskModel(
                            id: t.id,
                            title: t.title,
                            description: t.description,
                            status: newStatus,
                            priority: t.priority,
                            assignedTo: t.assignedTo,
                            assignedToName: t.assignedToName,
                            dueDate: t.dueDate,
                            completedAt: (val == true) ? DateTime.now() : null,
                            createdBy: t.createdBy,
                            createdAt: t.createdAt,
                          );
                          ref.read(projectRepositoryProvider).updateProjectTask(project.id, updated);
                        },
                        title: Text(
                          t.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.description.isNotEmpty) Text(t.description, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (t.assignedToName.isNotEmpty) ...[
                                  Text('Assignee: ${t.assignedToName}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                  const SizedBox(width: 8),
                                ],
                                if (t.dueDate != null)
                                  Text('Due: ${dateFormat.format(t.dueDate!)}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          onPressed: () => ref.read(projectRepositoryProvider).deleteProjectTask(project.id, t.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── TAB 4: MILESTONES ─────────────────────────────────────────────────────
  Widget _buildMilestonesTab(ProjectModel project) {
    final milestonesAsync = ref.watch(projectMilestonesProvider(project.id));
    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return milestonesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: 'Failed to load milestones: $e'),
      data: (milestones) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${milestones.length} ${milestones.length == 1 ? "Milestone" : "Milestones"}',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddMilestoneDialog(project.id),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Milestone'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (milestones.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.flag_circle_outlined,
                  title: 'No milestones set',
                  subtitle: 'Set critical phases, deliverable targets, and progress checkpoints.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: milestones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final m = milestones[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: m.isCompleted ? AppColors.successContainer : AppColors.primaryContainer,
                              child: Icon(
                                m.isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
                                color: m.isCompleted ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (m.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(m.description, style: const TextStyle(fontSize: 12)),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Target Date: ${dateFormat.format(m.targetDate)} • Progress: ${m.progressPercentage}%'
                                    '${m.amount > 0 ? " • Billing: ${inrFormat.format(m.amount)}" : ""}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              onPressed: () => ref.read(projectRepositoryProvider).deleteProjectMilestone(project.id, m.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── TAB 5: DOCUMENTS ──────────────────────────────────────────────────────
  Widget _buildDocumentsTab(ProjectModel project) {
    final linksAsync = ref.watch(projectLinksProvider(project.id));

    return linksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (links) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${links.length} ${links.length == 1 ? "Link" : "Links"}',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddLinkDialog(project.id),
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text('Add Document Link'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (links.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.link_rounded,
                  title: 'No document links yet',
                  subtitle: 'Connect Figma designs, GitHub repos, Google Drive folders, or contracts.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final link = links[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                          child: Icon(link.icon, size: 20, color: AppColors.primary),
                        ),
                        title: Text(link.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(link.type, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              onPressed: () async {
                                final uri = Uri.tryParse(link.url);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              onPressed: () => ref.read(projectRepositoryProvider).deleteProjectLink(project.id, link.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── TAB 6: PAYMENTS ───────────────────────────────────────────────────────
  Widget _buildPaymentsTab(ProjectModel project) {
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Financial Overview', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Project Budget',
                      value: inrFormat.format(project.budget),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Quotation Amount',
                      value: inrFormat.format(project.quotationValue),
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const Icon(Icons.payment_rounded, size: 40, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.md),
                      Text('Payment Tracking Foundation', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Project invoices and payment collections will sync automatically in the upcoming Payments module. Budget and quotation baselines are fully established for ${project.projectNumber}.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB 7: ACTIVITY ───────────────────────────────────────────────────────
  Widget _buildActivityTab(ProjectModel project) {
    final activitiesAsync = ref.watch(projectActivitiesProvider(project.id));
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: 'Failed to load activity: $e'),
      data: (activities) {
        if (activities.isEmpty) {
          return const EmptyState(icon: Icons.history_rounded, title: 'No project activity recorded yet');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = activities[i];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.history_edu_rounded, size: 18, color: AppColors.primary),
              ),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(a.description),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${a.createdByName} • ${dateFormat.format(a.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── TAB 8: NOTES ──────────────────────────────────────────────────────────
  Widget _buildNotesTab(ProjectModel project) {
    final notesAsync = ref.watch(projectNotesProvider(project.id));
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      children: [
        // Note composer
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add an internal project note...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: _isAddingNote ? null : _handleAddNote,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Note'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Notes list
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(message: 'Failed to load notes: $e'),
            data: (notes) {
              if (notes.isEmpty) {
                return const EmptyState(
                  icon: Icons.note_alt_outlined,
                  title: 'No internal notes',
                  subtitle: 'Add internal discussions, team notes, or client requests.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final n = notes[i];
                  return Card(
                    child: ListTile(
                      title: Text(n.note),
                      subtitle: Text(
                        '${n.createdByName} • ${dateFormat.format(n.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () => ref.read(projectRepositoryProvider).deleteProjectNote(project.id, n.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Helpers & Dialogs ─────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
          Expanded(
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  )
                : Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddRequirementDialog(String projectId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Functional';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Requirement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Requirement Title *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Functional', 'Non-Functional', 'UI/UX Design', 'Technical / Architecture', 'Security', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setSt(() => category = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final now = DateTime.now();
                await ref.read(projectRepositoryProvider).addProjectRequirement(
                  projectId,
                  ProjectRequirementModel(
                    id: '',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: category,
                    createdBy: '',
                    createdByName: 'Admin',
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(String projectId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task Title *')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date'),
                subtitle: Text(dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate!) : 'Not set'),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setSt(() => dueDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final now = DateTime.now();
                await ref.read(projectRepositoryProvider).addProjectTask(
                  projectId,
                  ProjectTaskModel(
                    id: '',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    dueDate: dueDate,
                    createdBy: '',
                    createdAt: now,
                  ),
                );
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(String projectId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 14));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Milestone Title *')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Billing Amount (₹)')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(targetDate)),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setSt(() => targetDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final now = DateTime.now();
                await ref.read(projectRepositoryProvider).addProjectMilestone(
                  projectId,
                  ProjectMilestoneModel(
                    id: '',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    targetDate: targetDate,
                    amount: double.tryParse(amountCtrl.text.trim()) ?? 0.0,
                    createdBy: '',
                    createdAt: now,
                  ),
                );
              },
              child: const Text('Add Milestone'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLinkDialog(String projectId) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'Link';
    final types = ['Link', 'Figma', 'GitHub', 'Google Drive', 'Notion', 'PDF', 'Contract', 'Proposal', 'API Documentation', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Document Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Document Name *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setSt(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL *')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final now = DateTime.now();
                await ref.read(projectRepositoryProvider).addProjectLink(
                  projectId,
                  ProjectLink(
                    id: '',
                    name: nameCtrl.text.trim(),
                    type: type,
                    url: urlCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    addedBy: '',
                    addedByName: 'Admin',
                    addedAt: now,
                  ),
                );
              },
              child: const Text('Add Link'),
            ),
          ],
        ),
      ),
    );
  }
}
