import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../models/lead_model.dart';
import '../providers/lead_providers.dart';
import '../repositories/lead_repository.dart';
import '../widgets/lead_duplicate_dialog.dart';

class LeadFormScreen extends ConsumerStatefulWidget {
  final String? leadId;
  const LeadFormScreen({super.key, this.leadId});

  @override
  ConsumerState<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends ConsumerState<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitLoading = false;
  bool _isEditing = false;

  // Controllers
  final _companyNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _initialNotesCtrl = TextEditingController();

  LeadStatus _status = LeadStatus.newLead;
  LeadPriority _priority = LeadPriority.medium;
  LeadSource _source = LeadSource.website;
  String _assignedToId = '';
  String _assignedToName = '';
  String _lostReason = '';
  DateTime? _originalCreatedAt;

  bool _sameAsPhone = false;
  List<String> _interestedServices = [];

  static const _serviceOptions = [
    'Website Development',
    'Web Application',
    'Mobile App',
    'CRM',
    'Custom Software',
    'UI/UX',
    'E-commerce',
    'Maintenance / Support',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.leadId != null && widget.leadId!.isNotEmpty;
    if (_isEditing) {
      _loadLead();
    } else {
      final auth = ref.read(authRepositoryProvider);
      if (auth.currentUser != null) {
        _assignedToId = auth.currentUserId ?? '';
        _assignedToName = auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin';
      }
    }
    _phoneCtrl.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_sameAsPhone) {
      _whatsappCtrl.text = _phoneCtrl.text;
    }
  }

  Future<void> _loadLead() async {
    setState(() => _isInitLoading = true);
    try {
      final repo = ref.read(leadRepositoryProvider);
      final lead = await repo.getLeadById(widget.leadId!);
      if (lead != null && mounted) {
        _companyNameCtrl.text = lead.companyName;
        _contactPersonCtrl.text = lead.contactPerson;
        _emailCtrl.text = lead.email;
        _phoneCtrl.text = lead.phone;
        _whatsappCtrl.text = lead.alternatePhone;
        _websiteCtrl.text = lead.website;
        _cityCtrl.text = lead.city;
        _initialNotesCtrl.text = lead.notes;

        _status = lead.status;
        _priority = lead.priority;
        _source = lead.leadSource;
        _assignedToId = lead.assignedToUserId;
        _assignedToName = lead.assignedToName;
        _lostReason = lead.lostReason ?? '';
        _originalCreatedAt = lead.createdAt;
        _interestedServices = List.from(lead.interestedServices);
        
        if (lead.phone == lead.alternatePhone && lead.phone.isNotEmpty) {
          _sameAsPhone = true;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lead: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_onPhoneChanged);
    _companyNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _websiteCtrl.dispose();
    _cityCtrl.dispose();
    _initialNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_interestedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one Interested Service')),
      );
      return;
    }
    
    if (_assignedToId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign this lead to a staff member')),
      );
      return;
    }

    final company = _companyNameCtrl.text.trim();
    final contact = _contactPersonCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(leadRepositoryProvider);

      final duplicate = await repo.checkForDuplicate(
        phone: phone,
        email: email,
        companyName: company,
      );

      if (duplicate != null && duplicate.id != widget.leadId && mounted) {
        setState(() => _isLoading = false);
        final proceed = await LeadDuplicateDialog.show(context, duplicate);
        if (proceed != true) {
          return;
        }
        setState(() => _isLoading = true);
      }

      final auth = ref.read(authRepositoryProvider);
      final currentUserName = auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin';
      final currentUserId = auth.currentUserId ?? '';

      final lead = LeadModel(
        id: widget.leadId ?? '',
        companyName: company,
        contactPerson: contact,
        email: email,
        phone: phone,
        alternatePhone: _whatsappCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        leadSource: _source,
        status: _status,
        priority: _priority,
        assignedTo: _assignedToId,
        assignedToName: _assignedToName,
        interestedServices: _interestedServices,
        notes: _initialNotesCtrl.text.trim(),
        lostReason: _status == LeadStatus.lost ? _lostReason : null,
        createdBy: _isEditing ? '' : currentUserId,
        createdByName: _isEditing ? '' : currentUserName,
        createdAt: _originalCreatedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String savedId = lead.id;
      final eventBus = ref.read(appEventBusProvider);
      if (_isEditing) {
        await repo.updateLead(lead);
        eventBus.emit(LeadUpdatedEvent(lead));
      } else {
        savedId = await repo.createLead(lead);
        eventBus.emit(LeadCreatedEvent(lead.copyWith(id: savedId)));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Lead updated successfully' : 'Lead created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('${AppRoutes.leads}/$savedId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving lead: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Widget _responsiveFieldRow(BuildContext context, List<Widget> fields) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields
            .map((f) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: f))
            .toList(),
      );
    }
    
    List<Widget> rowChildren = [];
    for (int i = 0; i < fields.length; i++) {
      rowChildren.add(Expanded(child: fields[i]));
      if (i < fields.length - 1) {
        rowChildren.add(const SizedBox(width: AppSpacing.md));
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowChildren,
    );
  }

  Widget _buildLabel(String text, bool isRequired, bool isDark) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (isRequired)
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final usersAsync = ref.watch(activeUsersProvider);

    if (_isInitLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Lead' : 'Create New Lead'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.leads);
            }
          },
        ),
        actions: [
          if (!PlatformCapabilities.isAndroid)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Lead'),
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
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                    onPressed: _isLoading ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Create Lead',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!PlatformCapabilities.isAndroid) ...[
                      Breadcrumbs(
                        items: [
                          const BreadcrumbItem(label: 'Home', route: AppRoutes.dashboard),
                          const BreadcrumbItem(label: 'Leads', route: AppRoutes.leads),
                          BreadcrumbItem(label: _isEditing ? 'Edit Lead' : 'New Lead'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Section 1: Basic Information
                    _buildCard(
                      title: 'Basic Information',
                      subtitle: 'Primary details for the lead or prospective client.',
                      isDark: isDark,
                      children: [
                        _responsiveFieldRow(context, [
                          TextFormField(
                            controller: _contactPersonCtrl,
                            decoration: InputDecoration(
                              label: _buildLabel('Contact Person / Lead Name', false, isDark),
                              hintText: 'e.g. Rahul Sharma',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                            ),
                          ),
                          TextFormField(
                            controller: _companyNameCtrl,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            decoration: InputDecoration(
                              label: _buildLabel('Company / Business Name', true, isDark),
                              hintText: 'e.g. Acme Corp',
                              prefixIcon: const Icon(Icons.business_rounded, size: 18),
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _cityCtrl,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            label: _buildLabel('Location (City/Area)', false, isDark),
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 34.0),
                              child: Icon(Icons.map_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Contact Details
                    _buildCard(
                      title: 'Contact Details',
                      subtitle: 'Phone numbers, email addresses, and website for follow-ups.',
                      isDark: isDark,
                      children: [
                        _responsiveFieldRow(context, [
                          TextFormField(
                            controller: _phoneCtrl,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              label: _buildLabel('Primary Phone Number', true, isDark),
                              hintText: '+91 98765 43210',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _whatsappCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  label: _buildLabel('WhatsApp Number', false, isDark),
                                  hintText: '+91 98765 43210',
                                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _sameAsPhone,
                                    onChanged: (val) {
                                      setState(() {
                                        _sameAsPhone = val ?? false;
                                        if (_sameAsPhone) {
                                          _whatsappCtrl.text = _phoneCtrl.text;
                                        }
                                      });
                                    },
                                  ),
                                  Flexible(
                                    child: Text(
                                      'Same as primary phone',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        _responsiveFieldRow(context, [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              label: _buildLabel('Email Address', false, isDark),
                              hintText: 'contact@example.com',
                              prefixIcon: const Icon(Icons.email_outlined, size: 18),
                            ),
                          ),
                          TextFormField(
                            controller: _websiteCtrl,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              label: _buildLabel('Website', false, isDark),
                              hintText: 'https://example.com',
                              prefixIcon: const Icon(Icons.language_rounded, size: 18),
                            ),
                          ),
                        ]),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: Lead Details
                    _buildCard(
                      title: 'Lead Details',
                      subtitle: 'Source, interested services, and pipeline status.',
                      isDark: isDark,
                      children: [
                        _responsiveFieldRow(context, [
                          AppDropdown<LeadSource>(
                            label: 'Lead Source *',
                            value: _source,
                            validator: (val) => val == null ? 'Required' : null,
                            prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                            items: LeadSource.values.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s.label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _source = val);
                            },
                          ),
                          AppDropdown<LeadPriority>(
                            label: 'Priority',
                            value: _priority,
                            prefixIcon: const Icon(Icons.flag_outlined, size: 18),
                            items: LeadPriority.values.map((p) {
                              return DropdownMenuItem(value: p, child: Text(p.label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        _responsiveFieldRow(context, [
                          AppDropdown<LeadStatus>(
                            label: 'Lead Status *',
                            value: _status,
                            prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            items: LeadStatus.values.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s.label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                          const SizedBox.shrink(), // Balance the row
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Interested Service *',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _serviceOptions.map((service) {
                            final isSelected = _interestedServices.contains(service);
                            return FilterChip(
                              label: Text(service),
                              selected: isSelected,
                              showCheckmark: true,
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? AppColors.primary 
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _interestedServices.add(service);
                                  } else {
                                    _interestedServices.remove(service);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 4: Assignment & Notes
                    _buildCard(
                      title: 'Assignment & Notes',
                      subtitle: 'Assign to a team member and add initial remarks.',
                      isDark: isDark,
                      children: [
                        usersAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, err) => const Text('Could not load staff list'),
                          data: (users) {
                            return AppDropdown<String>(
                              label: 'Assigned To *',
                              value: _assignedToId.isNotEmpty ? _assignedToId : null,
                              hint: 'Select a team member',
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              prefixIcon: const Icon(Icons.person_pin_outlined, size: 18),
                              items: users.map((u) {
                                final name = u.displayName.isNotEmpty ? u.displayName : u.email;
                                return DropdownMenuItem(
                                  value: u.id,
                                  child: Text('$name (${u.email})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _assignedToId = val ?? '';
                                  final match = users.where((u) => u.id == val).toList();
                                  _assignedToName = match.isNotEmpty
                                      ? (match.first.displayName.isNotEmpty ? match.first.displayName : match.first.email)
                                      : '';
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _initialNotesCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            label: _buildLabel('Initial Notes', false, isDark),
                            hintText: 'Any additional context about this lead...',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 50.0),
                              child: Icon(Icons.description_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    const SizedBox(height: AppSpacing.xxl),
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
    required String subtitle,
    required bool isDark,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
