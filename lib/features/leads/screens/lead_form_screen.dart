import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import '../../../core/widgets/app_searchable_dropdown.dart';
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
  final _jobTitleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _estimatedValueCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _initialNotesCtrl = TextEditingController();

  LeadStatus _status = LeadStatus.newLead;
  LeadPriority _priority = LeadPriority.medium;
  LeadSource _source = LeadSource.website;
  String _currency = 'INR';
  DateTime? _expectedCloseDate;
  String _assignedToId = '';
  String _assignedToName = '';
  String _lostReason = '';
  DateTime? _originalCreatedAt;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.leadId != null && widget.leadId!.isNotEmpty;
    if (_isEditing) {
      _loadLead();
    } else {
      // Default assignment to current user
      final auth = ref.read(authRepositoryProvider);
      if (auth.currentUser != null) {
        _assignedToId = auth.currentUserId ?? '';
        _assignedToName = auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin';
      }
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
        _jobTitleCtrl.text = lead.jobTitle;
        _emailCtrl.text = lead.email;
        _phoneCtrl.text = lead.phone;
        _whatsappCtrl.text = lead.whatsappNumber;
        _websiteCtrl.text = lead.website;
        _addressCtrl.text = lead.address;
        _cityCtrl.text = lead.city;
        _stateCtrl.text = lead.state;
        _countryCtrl.text = lead.country;
        _postalCodeCtrl.text = lead.postalCode;
        _industryCtrl.text = lead.industry;
        _estimatedValueCtrl.text = lead.estimatedValue > 0 ? lead.estimatedValue.toStringAsFixed(0) : '';
        _requirementsCtrl.text = lead.requirements;
        _tagsCtrl.text = lead.tags.join(', ');
        _initialNotesCtrl.text = lead.notes;

        _status = lead.status;
        _priority = lead.priority;
        _source = lead.leadSource;
        _currency = lead.currency.isNotEmpty ? lead.currency : 'INR';
        _expectedCloseDate = lead.expectedCloseDate;
        _assignedToId = lead.assignedToUserId;
        _assignedToName = lead.assignedToName;
        _lostReason = lead.lostReason ?? '';
        _originalCreatedAt = lead.createdAt;
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
    _companyNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _jobTitleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _postalCodeCtrl.dispose();
    _industryCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _requirementsCtrl.dispose();
    _tagsCtrl.dispose();
    _initialNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedCloseDate ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expectedCloseDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final company = _companyNameCtrl.text.trim();
    final contact = _contactPersonCtrl.text.trim();
    if (company.isEmpty && contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least a Company Name or Contact Person')),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(leadRepositoryProvider);

      // Duplicate Check (only if not editing same lead, or creating new)
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
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        industry: _industryCtrl.text.trim(),
        jobTitle: _jobTitleCtrl.text.trim(),
        leadSource: _source,
        status: _status,
        priority: _priority,
        assignedTo: _assignedToId,
        assignedToName: _assignedToName,
        estimatedValue: double.tryParse(_estimatedValueCtrl.text.trim()) ?? 0,
        expectedClosingDate: _expectedCloseDate,
        description: _requirementsCtrl.text.trim(),
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

                    // Section 1: Company & Contact
                    _buildCard(
                      title: 'Basic Information',
                      subtitle: 'Primary details for the lead or prospective client.',
                      isDark: isDark,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _companyNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Company / Organization Name',
                                  hintText: 'e.g. Acme Corp',
                                  prefixIcon: Icon(Icons.business_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _contactPersonCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Person Name',
                                  hintText: 'e.g. Rahul Sharma',
                                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: AppSearchableDropdown(
                                controller: _jobTitleCtrl,
                                label: 'Job Title / Role',
                                hintText: 'Select or search role...',
                                modalTitle: 'Select Job Title / Role',
                                prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                items: standardJobTitles,
                                popularItems: const [
                                  'Managing Director',
                                  'Chief Executive Officer (CEO)',
                                  'Head of Sales',
                                  'Procurement Director',
                                  'Project Manager',
                                  'General Manager',
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppSearchableDropdown(
                                controller: _industryCtrl,
                                label: 'Industry / Vertical',
                                hintText: 'Select or search industry...',
                                modalTitle: 'Select Industry / Vertical',
                                prefixIcon: const Icon(Icons.category_outlined, size: 18),
                                items: standardIndustries,
                                popularItems: const [
                                  'Technology & Software',
                                  'Civil Construction & Contracting',
                                  'Commercial Real Estate & Developers',
                                  'Industrial Manufacturing',
                                  'Building Materials & Hardware',
                                  'Logistics & Freight Forwarding',
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Contact Methods
                    _buildCard(
                      title: 'Contact Details',
                      subtitle: 'Phone numbers, email addresses, and website for follow-ups.',
                      isDark: isDark,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Primary Phone',
                                  hintText: '+91 98765 43210',
                                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _whatsappCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'WhatsApp Number (Optional)',
                                  hintText: '+91 98765 43210',
                                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
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
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'contact@example.com',
                                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _websiteCtrl,
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  labelText: 'Website',
                                  hintText: 'https://example.com',
                                  prefixIcon: Icon(Icons.language_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Street Address',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityCtrl,
                                decoration: const InputDecoration(labelText: 'City'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _stateCtrl,
                                decoration: const InputDecoration(labelText: 'State / Province'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _countryCtrl,
                                decoration: const InputDecoration(labelText: 'Country'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: Lead Pipeline & Value
                    _buildCard(
                      title: 'Pipeline & Value',
                      subtitle: 'Track where this lead stands in your conversion funnel.',
                      isDark: isDark,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppDropdown<LeadStatus>(
                                label: 'Pipeline Status',
                                value: _status,
                                prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 18),
                                items: LeadStatus.values.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s.label));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _status = val);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppDropdown<LeadPriority>(
                                label: 'Priority Level',
                                value: _priority,
                                prefixIcon: const Icon(Icons.flag_outlined, size: 18),
                                items: LeadPriority.values.map((p) {
                                  return DropdownMenuItem(value: p, child: Text(p.label));
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
                              child: AppDropdown<LeadSource>(
                                label: 'Acquisition Source',
                                value: _source,
                                prefixIcon: const Icon(Icons.campaign_outlined, size: 18),
                                items: LeadSource.values.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s.label));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _source = val);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _estimatedValueCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Estimated Deal Value',
                                  hintText: '50000',
                                  prefixText: _currency == 'INR' ? '₹ ' : '\$ ',
                                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Expected Close Date',
                                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                    suffixIcon: Icon(Icons.arrow_drop_down),
                                  ),
                                  child: Text(
                                    _expectedCloseDate != null
                                        ? DateFormat('dd MMM yyyy').format(_expectedCloseDate!)
                                        : 'Select expected date',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _expectedCloseDate != null
                                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 4: Assignment
                    _buildCard(
                      title: 'Staff Assignment',
                      subtitle: 'Assign this lead to an active team member for follow-ups.',
                      isDark: isDark,
                      children: [
                        usersAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, err) => const Text('Could not load staff list'),
                          data: (users) {
                            return AppDropdown<String>(
                              label: 'Assigned Staff Member',
                              value: _assignedToId.isNotEmpty ? _assignedToId : '',
                              hint: 'Select a team member (or leave unassigned)',
                              prefixIcon: const Icon(Icons.person_pin_outlined, size: 18),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Unassigned'),
                                ),
                                ...users.map((u) {
                                  final name = u.displayName.isNotEmpty ? u.displayName : u.email;
                                  return DropdownMenuItem(
                                    value: u.id,
                                    child: Text('$name (${u.email})'),
                                  );
                                }),
                              ],
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
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 5: Requirements, Tags, Notes
                    _buildCard(
                      title: 'Requirements & Notes',
                      subtitle: 'Capture project specifications and preliminary notes.',
                      isDark: isDark,
                      children: [
                        TextFormField(
                          controller: _requirementsCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Project Requirements / Inquiries',
                            hintText: 'Customer needs a mobile app with backend integration...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _tagsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tags (comma separated)',
                            hintText: 'enterprise, priority, inbound, saas',
                            prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _initialNotesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Initial Notes / Next Steps',
                            hintText: 'Called on Monday; requested pricing deck.',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Submit buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.leads),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilledButton(
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isEditing ? 'Save Changes' : 'Create Lead'),
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
