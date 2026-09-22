// lib/features/clients/widgets/lead_conversion_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../leads/providers/lead_providers.dart';
import '../../leads/models/lead_model.dart';
import '../models/client_model.dart';
import '../services/lead_conversion_service.dart';

class LeadConversionDialog extends ConsumerStatefulWidget {
  final LeadModel lead;

  const LeadConversionDialog({
    super.key,
    required this.lead,
  });

  static Future<String?> show(BuildContext context, LeadModel lead) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LeadConversionDialog(lead: lead),
    );
  }

  @override
  ConsumerState<LeadConversionDialog> createState() => _LeadConversionDialogState();
}

class _LeadConversionDialogState extends ConsumerState<LeadConversionDialog> {
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
  late TextEditingController _pincodeController;
  late TextEditingController _notesController;

  late String _selectedIndustry;
  late ClientType _selectedType;
  late ClientPriority _selectedPriority;
  late String _selectedAssignedTo;
  late String _selectedAssignedToName;

  bool _isSubmitting = false;
  ClientModel? _duplicateMatch;
  bool _isCheckingDuplicate = false;

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    _companyController = TextEditingController(text: lead.companyName);
    _contactController = TextEditingController(text: lead.contactPerson);
    _phoneController = TextEditingController(text: lead.phone);
    _altPhoneController = TextEditingController(text: lead.alternatePhone);
    _emailController = TextEditingController(text: lead.email);
    _websiteController = TextEditingController(text: lead.website);
    _addressController = TextEditingController(text: lead.address);
    _cityController = TextEditingController(text: lead.city);
    _stateController = TextEditingController(text: lead.state);
    _pincodeController = TextEditingController(text: '');
    _notesController = TextEditingController(text: lead.notes);

    _selectedIndustry = 'Technology';
    _selectedType = ClientType.newClient;
    _selectedPriority = ClientPriority.fromString(lead.priority.name);
    _selectedAssignedTo = lead.assignedTo;
    _selectedAssignedToName = lead.assignedToName;

    _runDuplicateCheck();
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
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _runDuplicateCheck() async {
    if (!mounted) return;
    setState(() => _isCheckingDuplicate = true);
    final service = ref.read(leadConversionServiceProvider);
    final match = await service.checkForDuplicate(
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      companyName: _companyController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _duplicateMatch = match;
        _isCheckingDuplicate = false;
      });
    }
  }

  Future<void> _handleConvert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(leadConversionServiceProvider);
      final newClientId = await service.convertLeadToClient(
        lead: widget.lead,
        companyName: _companyController.text.trim(),
        contactPerson: _contactController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _altPhoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: 'India',
        pincode: _pincodeController.text.trim(),
        industry: _selectedIndustry,
        clientType: _selectedType,
        priority: _selectedPriority,
        assignedTo: _selectedAssignedTo,
        assignedToName: _selectedAssignedToName,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(newClientId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversion failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffAsync = ref.watch(activeUsersProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.how_to_reg_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convert Lead to Client',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review and confirm information to onboard ${widget.lead.companyName}.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_isCheckingDuplicate) const LinearProgressIndicator(minHeight: 2),

            // Duplicate Warning Banner (if detected)
            if (_duplicateMatch != null) ...[
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Possible Existing Client Found',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A client record already matches this lead:\n"${_duplicateMatch!.companyName}" (${_duplicateMatch!.contactPerson}, ${_duplicateMatch!.phone})',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.push('${AppRoutes.clients}/${_duplicateMatch!.id}');
                                },
                                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                label: const Text('View Existing Client'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Body Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Company & Contact
                      _buildSectionTitle('Company & Primary Contact', Icons.business_outlined),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _companyController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name *',
                                prefixIcon: Icon(Icons.apartment_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Company name is required'
                                  : null,
                              onChanged: (_) => _runDuplicateCheck(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _contactController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person *',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Contact person is required'
                                  : null,
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
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Phone number is required'
                                  : null,
                              onChanged: (_) => _runDuplicateCheck(),
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
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              onChanged: (_) => _runDuplicateCheck(),
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
                      const SizedBox(height: AppSpacing.lg),

                      // Section 2: Address
                      _buildSectionTitle('Address Details', Icons.place_outlined),
                      const SizedBox(height: AppSpacing.sm),
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
                      const SizedBox(height: AppSpacing.lg),

                      // Section 3: Classification & Assignment
                      _buildSectionTitle('Classification & Assignment', Icons.tune_rounded),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ClientType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Client Type',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: ClientType.values.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedType = v);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedIndustry,
                              decoration: const InputDecoration(
                                labelText: 'Industry',
                                prefixIcon: Icon(Icons.domain_rounded),
                              ),
                              items: clientIndustries.map((ind) {
                                return DropdownMenuItem(
                                  value: ind,
                                  child: Text(ind),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedIndustry = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ClientPriority>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: ClientPriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(p.displayName),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedPriority = v);
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
                                    labelText: 'Assigned To',
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
                      const SizedBox(height: AppSpacing.lg),

                      // Section 4: Initial Notes
                      _buildSectionTitle('Initial Notes', Icons.notes_rounded),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add initial customer preferences, commitments, or background notes...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _handleConvert,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Converting...' : 'Convert to Client'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
