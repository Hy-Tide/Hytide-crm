// lib/features/projects/screens/project_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/services/timezone_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/client_select_dialog.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/models/client_model.dart';
import '../../clients/repositories/client_repository.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../services/project_status_service.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final String? initialClientId;

  const ProjectFormScreen({
    super.key,
    this.projectId,
    this.initialClientId,
  });

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSaving = false;

  // Selected Client Details
  String _clientId = '';
  String _clientName = '';
  String _companyName = '';
  String? _sourceLeadId;
  String? _sourceQuotationId;
  String _quotationNumber = '';

  // Core Project Fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  ProjectType _projectType = ProjectType.webApplication;
  ProjectStatus _status = ProjectStatus.planning;
  ProjectPriority _priority = ProjectPriority.medium;

  DateTime _startDate = TimezoneHelper.now();
  DateTime? _expectedEndDate = TimezoneHelper.now().add(const Duration(days: 30));
  DateTime? _actualEndDate;

  // Financials
  final _budgetController = TextEditingController(text: '0');
  double _quotationValue = 0.0;
  int _progress = 0;

  // Staff Assignment
  String _projectManager = '';
  String _projectManagerName = '';
  List<String> _assignedTo = [];
  List<String> _assignedToNames = [];

  ProjectModel? _existingProject;
  bool get isEdit => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final auth = ref.read(authRepositoryProvider);
    _projectManager = auth.currentUserId ?? '';
    _projectManagerName = auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin';

    if (isEdit) {
      final project = await ref.read(projectRepositoryProvider).getProjectById(widget.projectId!);
      if (project != null) {
        _existingProject = project;
        _clientId = project.clientId;
        _clientName = project.clientName;
        _companyName = project.companyName;
        _sourceLeadId = project.sourceLeadId;
        _sourceQuotationId = project.sourceQuotationId;
        _quotationNumber = project.quotationNumber ?? '';

        _titleController.text = project.title;
        _descriptionController.text = project.description;
        _notesController.text = project.notes;
        _projectType = project.projectType;
        _status = project.status;
        _priority = project.priority;
        _startDate = project.startDate ?? TimezoneHelper.now();
        _expectedEndDate = project.expectedEndDate;
        _actualEndDate = project.actualEndDate;
        _budgetController.text = project.budget > 0 ? project.budget.toStringAsFixed(0) : '';
        _quotationValue = project.quotationValue;
        _progress = project.progress;

        _projectManager = project.projectManager;
        _projectManagerName = project.projectManagerName;
        _assignedTo = project.assignedTo.isNotEmpty ? [project.assignedTo] : [];
        _assignedToNames = List.from(project.assignedToNames);
      }
    } else if (widget.initialClientId != null && widget.initialClientId!.isNotEmpty) {
      final client = await ref.read(clientRepositoryProvider).getClientById(widget.initialClientId!);
      if (client != null) {
        _onClientSelected(client);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _onClientSelected(ClientModel client) {
    setState(() {
      _clientId = client.id;
      _clientName = client.contactPerson;
      _companyName = client.companyName;
      _sourceLeadId = client.sourceLeadId;
    });
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client for this project')),
      );
      return;
    }

    // Validate dates
    final dateErr = ProjectStatusService.validateDates(_startDate, _expectedEndDate);
    if (dateErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateErr), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final budgetVal = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      final now = DateTime.now();

      // If status is completed, force progress = 100 and set actualEndDate if null
      int finalProgress = _progress;
      DateTime? finalActualEnd = _actualEndDate;
      if (_status == ProjectStatus.completed) {
        finalProgress = 100;
        finalActualEnd ??= now;
      }

      if (isEdit) {
        final updated = _existingProject!.copyWith(
          title: _titleController.text.trim(),
          name: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
          projectType: _projectType,
          status: _status,
          priority: _priority,
          startDate: _startDate,
          expectedEndDate: _expectedEndDate,
          actualEndDate: finalActualEnd,
          budget: budgetVal,
          progress: finalProgress,
          projectManager: _projectManager,
          projectManagerName: _projectManagerName,
          assignedTo: _assignedTo.isNotEmpty ? _assignedTo.first : '',
          assignedToNames: _assignedToNames,
          updatedAt: now,
        );

        await ref.read(projectRepositoryProvider).updateProject(updated);
        ref.read(appEventBusProvider).emit(ProjectUpdatedEvent(updated));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project updated successfully!'), backgroundColor: AppColors.success),
          );
          context.go('${AppRoutes.projects}/${_existingProject!.id}');
        }
      } else {
        final newProject = ProjectModel(
          id: '',
          projectNumber: '', // Generated atomically in repository
          clientId: _clientId,
          clientName: _clientName,
          companyName: _companyName,
          sourceQuotationId: _sourceQuotationId,
          sourceLeadId: _sourceLeadId,
          quotationNumber: _quotationNumber,
          title: _titleController.text.trim(),
          name: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
          projectType: _projectType,
          status: _status,
          priority: _priority,
          startDate: _startDate,
          expectedEndDate: _expectedEndDate,
          actualEndDate: finalActualEnd,
          assignedTo: _assignedTo.isNotEmpty ? _assignedTo.first : '',
          assignedToNames: _assignedToNames,
          projectManager: _projectManager,
          projectManagerName: _projectManagerName,
          estimatedValue: budgetVal,
          quotationValue: _quotationValue,
          budget: budgetVal,
          progress: finalProgress,
          createdBy: ref.read(authRepositoryProvider).currentUserId ?? '',
          createdByName: ref.read(authRepositoryProvider).currentUser?.displayName ?? 'Admin',
          createdAt: now,
          updatedAt: now,
        );

        final newId = await ref.read(projectRepositoryProvider).createProject(newProject);
        ref.read(appEventBusProvider).emit(ProjectCreatedEvent(newProject.copyWith(id: newId)));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project created successfully!'), backgroundColor: AppColors.success),
          );
          context.go('${AppRoutes.projects}/$newId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving project: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffAsync = ref.watch(activeUsersProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Project' : 'New Project'),
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
        ),
        body: const Center(child: CircularProgressIndicator()),
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
        title: Text(isEdit ? 'Edit Project (${_existingProject?.projectNumber})' : 'New Project'),
        actions: PlatformCapabilities.isAndroid
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProject,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Project')),
                  ),
                ),
              ],
      ),
      bottomNavigationBar: PlatformCapabilities.isAndroid
          ? Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProject,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_isSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Project')),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!PlatformCapabilities.isAndroid) ...[
                      Breadcrumbs(
                        items: [
                          const BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                          const BreadcrumbItem(label: 'Projects', route: AppRoutes.projects),
                          if (isEdit && _existingProject != null)
                            BreadcrumbItem(label: _existingProject!.projectNumber, route: '${AppRoutes.projects}/${_existingProject!.id}'),
                          BreadcrumbItem(label: isEdit ? 'Edit' : 'New'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Section 1: Client Selection
                    _buildCard(
                      title: 'Client Information',
                      icon: Icons.business_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_clientId.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _companyName.isNotEmpty ? _companyName : _clientName,
                                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      if (_companyName.isNotEmpty && _clientName.isNotEmpty)
                                        Text('Contact: $_clientName', style: AppTypography.bodySmall),
                                    ],
                                  ),
                                  if (!isEdit)
                                    TextButton.icon(
                                      onPressed: () => _showClientPicker(context),
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                      label: const Text('Change Client'),
                                    ),
                                ],
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () => _showClientPicker(context),
                              icon: const Icon(Icons.person_search_rounded),
                              label: const Text('Select Client *'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Project Identification
                    _buildCard(
                      title: 'Project Details',
                      icon: Icons.assignment_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Project Title *',
                              hintText: 'e.g. Modern E-commerce Platform Redesign',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a project title' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<ProjectType>(
                                  value: _projectType,
                                  decoration: const InputDecoration(labelText: 'Project Type'),
                                  items: ProjectType.values.map((t) {
                                    return DropdownMenuItem(value: t, child: Text(t.displayName));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _projectType = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: DropdownButtonFormField<ProjectPriority>(
                                  value: _priority,
                                  decoration: const InputDecoration(labelText: 'Priority'),
                                  items: ProjectPriority.values.map((p) {
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Icon(Icons.flag_rounded, size: 16, color: p.color),
                                          const SizedBox(width: 8),
                                          Text(p.displayName),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _priority = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<ProjectStatus>(
                                  value: _status,
                                  decoration: const InputDecoration(labelText: 'Status'),
                                  items: ProjectStatus.values.map((s) {
                                    return DropdownMenuItem(
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
                                      setState(() {
                                        _status = val;
                                        if (val == ProjectStatus.completed) {
                                          _progress = 100;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        Text('$_progress%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                    Slider(
                                      value: _progress.toDouble(),
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      onChanged: (v) => setState(() => _progress = v.toInt()),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: Schedule & Timeline
                    _buildCard(
                      title: 'Schedule & Timeline',
                      icon: Icons.calendar_today_rounded,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Start Date', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  subtitle: Text(dateFormat.format(_startDate), style: AppTypography.titleSmall),
                                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Expected End Date', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  subtitle: Text(
                                    _expectedEndDate != null ? dateFormat.format(_expectedEndDate!) : 'Not set',
                                    style: AppTypography.titleSmall,
                                  ),
                                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _expectedEndDate ?? _startDate.add(const Duration(days: 30)),
                                      firstDate: _startDate,
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() => _expectedEndDate = picked);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 4: Budget & Financials
                    _buildCard(
                      title: 'Budget & Financials',
                      icon: Icons.account_balance_wallet_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Project Budget (₹)',
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                          if (_quotationValue > 0) ...[
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quotation Value', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                    Text('₹${_quotationValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 5: Team & Management
                    _buildCard(
                      title: 'Team & Manager',
                      icon: Icons.group_outlined,
                      child: Column(
                        children: [
                          staffAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, stack) => const SizedBox.shrink(),
                            data: (staff) {
                              return DropdownButtonFormField<String>(
                                value: _projectManager.isNotEmpty ? _projectManager : null,
                                decoration: const InputDecoration(labelText: 'Project Manager'),
                                items: staff.map((s) {
                                  return DropdownMenuItem(value: s.uid, child: Text(s.displayName));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final selectedUser = staff.firstWhere((s) => s.uid == val);
                                    setState(() {
                                      _projectManager = val;
                                      _projectManagerName = selectedUser.displayName;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 6: Scope & Notes
                    _buildCard(
                      title: 'Scope Description & Notes',
                      icon: Icons.notes_rounded,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Scope & Deliverables Description',
                              hintText: 'Describe project objectives, key requirements, technical stack and deliverables...',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Internal Notes',
                              hintText: 'Internal considerations, stakeholder details, confidential notes...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Save Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProject,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_isSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Project')),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
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
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _showClientPicker(BuildContext context) async {
    final client = await ClientSelectDialog.show(
      context,
      selectedClientId: _clientId.isNotEmpty ? _clientId : null,
    );
    if (client != null) {
      _onClientSelected(client);
    }
  }
}
