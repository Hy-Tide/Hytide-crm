// lib/features/clients/screens/client_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _pincodeController;
  late TextEditingController _notesController;

  late String _selectedIndustry;
  late ClientType _selectedType;
  late ClientStatus _selectedStatus;
  late ClientPriority _selectedPriority;
  String? _selectedAssignedTo;
  String? _selectedAssignedToName;

  bool _isLoading = true;
  bool _isSaving = false;
  ClientModel? _existingClient;
  ClientModel? _duplicateMatch;

  bool get isEdit => widget.clientId != null && widget.clientId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController();
    _contactController = TextEditingController();
    _phoneController = TextEditingController();
    _altPhoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController(text: 'India');
    _pincodeController = TextEditingController();
    _notesController = TextEditingController();

    _selectedIndustry = clientIndustries.first;
    _selectedType = ClientType.newClient;
    _selectedStatus = ClientStatus.active;
    _selectedPriority = ClientPriority.medium;

    _loadInitialData();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (isEdit) {
      final client = await ref.read(clientRepositoryProvider).getClient(widget.clientId!);
      if (client != null && mounted) {
        _existingClient = client;
        _companyController.text = client.companyName;
        _contactController.text = client.contactPerson;
        _phoneController.text = client.phone;
        _altPhoneController.text = client.alternatePhone;
        _emailController.text = client.email;
        _websiteController.text = client.website;
        _addressController.text = client.address;
        _cityController.text = client.city;
        _stateController.text = client.state;
        _countryController.text = client.country;
        _pincodeController.text = client.pincode;
        _notesController.text = client.notes;

        _selectedIndustry = clientIndustries.contains(client.industry)
            ? client.industry
            : clientIndustries.first;
        _selectedType = client.clientType;
        _selectedStatus = client.status;
        _selectedPriority = client.priority;
        _selectedAssignedTo = client.assignedTo;
        _selectedAssignedToName = client.assignedToName;
      }
    } else {
      final auth = ref.read(authRepositoryProvider);
      _selectedAssignedTo = auth.currentUserId ?? '';
      _selectedAssignedToName = auth.currentUser?.displayName ?? 'Admin';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkDuplicate() async {
    if (isEdit || !mounted) return;
    final match = await ref.read(clientRepositoryProvider).checkDuplicateClient(
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          companyName: _companyController.text.trim(),
        );
    if (mounted) {
      setState(() => _duplicateMatch = match);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(clientRepositoryProvider);
      final auth = ref.read(authRepositoryProvider);
      final authorUid = auth.currentUserId ?? '';
      final authorName = auth.currentUser?.displayName ?? 'Admin';

      final clientModel = ClientModel(
        id: isEdit ? widget.clientId! : '',
        companyName: _companyController.text.trim(),
        contactPerson: _contactController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _altPhoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        pincode: _pincodeController.text.trim(),
        industry: _selectedIndustry,
        clientType: _selectedType,
        status: _selectedStatus,
        priority: _selectedPriority,
        sourceLeadId: _existingClient?.sourceLeadId,
        assignedTo: _selectedAssignedTo ?? authorUid,
        assignedToName: _selectedAssignedToName ?? authorName,
        createdBy: isEdit ? _existingClient!.createdBy : authorUid,
        createdByName: isEdit ? _existingClient!.createdByName : authorName,
        clientSince: isEdit ? _existingClient!.clientSince : DateTime.now(),
        createdAt: isEdit ? _existingClient!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        lastContactedAt: _existingClient?.lastContactedAt,
        nextFollowUpAt: _existingClient?.nextFollowUpAt,
        totalQuotationValue: _existingClient?.totalQuotationValue ?? 0.0,
        totalProjectValue: _existingClient?.totalProjectValue ?? 0.0,
        totalPaidAmount: _existingClient?.totalPaidAmount ?? 0.0,
        notes: _notesController.text.trim(),
        isArchived: _selectedStatus == ClientStatus.archived,
      );

      String resultId;
      final bus = ref.read(appEventBusProvider);
      if (isEdit) {
        await repo.updateClient(clientModel);
        resultId = widget.clientId!;
        bus.emit(ClientUpdatedEvent(clientModel));
      } else {
        resultId = await repo.createClient(clientModel);
        bus.emit(ClientCreatedEvent(clientModel.copyWith(id: resultId)));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Client updated successfully' : 'Client created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('${AppRoutes.clients}/$resultId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save client: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffAsync = ref.watch(activeUsersProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Client' : 'New Client')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Client' : 'Create New Client'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.clients);
            }
          },
        ),
        actions: [
          if (!PlatformCapabilities.isAndroid)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(isEdit ? 'Save Changes' : 'Create Client'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: PlatformCapabilities.isAndroid
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Create Client',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs (Web only)
                  if (!PlatformCapabilities.isAndroid) ...[
                    Breadcrumbs(
                      items: [
                        const BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                        const BreadcrumbItem(label: 'Clients', route: AppRoutes.clients),
                        BreadcrumbItem(label: isEdit ? 'Edit' : 'Create'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Duplicate match warning
                  if (_duplicateMatch != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Possible existing client found: "${_duplicateMatch!.companyName}" (${_duplicateMatch!.phone})',
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('${AppRoutes.clients}/${_duplicateMatch!.id}'),
                            child: const Text('View Client'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Section 1: Company Information
                  _buildSectionCard(
                    title: 'Company Information',
                    icon: Icons.business_rounded,
                    isDark: isDark,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _companyController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name *',
                                prefixIcon: Icon(Icons.apartment_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                              onChanged: (_) => _checkDuplicate(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                prefixIcon: Icon(Icons.language_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedIndustry,
                              decoration: const InputDecoration(
                                labelText: 'Industry',
                                prefixIcon: Icon(Icons.domain_rounded),
                              ),
                              items: clientIndustries.map((ind) {
                                return DropdownMenuItem(value: ind, child: Text(ind));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedIndustry = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<ClientType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Client Type',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: ClientType.values.map((t) {
                                return DropdownMenuItem(value: t, child: Text(t.displayName));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Contact Information
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person *',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact person is required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              onChanged: (_) => _checkDuplicate(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone *',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                              onChanged: (_) => _checkDuplicate(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _altPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Alternate Phone',
                                prefixIcon: Icon(Icons.phone_iphone_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 3: Address Details
                  _buildSectionCard(
                    title: 'Address & Billing Location',
                    icon: Icons.place_outlined,
                    isDark: isDark,
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Street Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                prefixIcon: Icon(Icons.location_city_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                                prefixIcon: Icon(Icons.pin_drop_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 4: Assignment & Priority
                  _buildSectionCard(
                    title: 'Assignment & Status',
                    icon: Icons.tune_rounded,
                    isDark: isDark,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ClientStatus>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: ClientStatus.values.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s.displayName));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<ClientPriority>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                prefixIcon: Icon(Icons.priority_high_rounded),
                              ),
                              items: ClientPriority.values.map((p) {
                                return DropdownMenuItem(value: p, child: Text(p.displayName));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPriority = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: staffAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (staff) {
                                return DropdownButtonFormField<String>(
                                  value: staff.any((s) => s.uid == _selectedAssignedTo)
                                      ? _selectedAssignedTo
                                      : (staff.isNotEmpty ? staff.first.uid : null),
                                  decoration: const InputDecoration(
                                    labelText: 'Assigned Staff',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  items: staff.map((s) {
                                    return DropdownMenuItem(
                                      value: s.uid,
                                      child: Text(s.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final selected = staff.firstWhere((s) => s.uid == val);
                                      setState(() {
                                        _selectedAssignedTo = selected.uid;
                                        _selectedAssignedToName = selected.displayName;
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 5: Notes
                  _buildSectionCard(
                    title: 'Account Notes',
                    icon: Icons.notes_rounded,
                    isDark: isDark,
                    children: [
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Add client background details, customer preferences, or key requirements...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save Button Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(isEdit ? 'Save Changes' : 'Create Client'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
