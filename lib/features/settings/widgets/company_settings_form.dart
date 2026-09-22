// lib/features/settings/widgets/company_settings_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../quotations/providers/quotation_providers.dart';
import '../models/company_settings_model.dart';
import '../repositories/settings_repository.dart';

class CompanySettingsForm extends ConsumerStatefulWidget {
  final CompanySettingsModel initialSettings;

  const CompanySettingsForm({super.key, required this.initialSettings});

  @override
  ConsumerState<CompanySettingsForm> createState() => _CompanySettingsFormState();
}

class _CompanySettingsFormState extends ConsumerState<CompanySettingsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;

  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _pincodeController;

  late final TextEditingController _gstController;
  late final TextEditingController _panController;

  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  late final TextEditingController _branchController;

  late final TextEditingController _termsController;
  late final TextEditingController _notesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSettings;
    _companyNameController = TextEditingController(text: s.companyName);
    _emailController = TextEditingController(text: s.email);
    _phoneController = TextEditingController(text: s.phone);
    _websiteController = TextEditingController(text: s.website);

    _addressController = TextEditingController(text: s.address);
    _cityController = TextEditingController(text: s.city);
    _stateController = TextEditingController(text: s.state);
    _countryController = TextEditingController(text: s.country);
    _pincodeController = TextEditingController(text: s.pincode);

    _gstController = TextEditingController(text: s.gstNumber);
    _panController = TextEditingController(text: s.panNumber);

    _bankNameController = TextEditingController(text: s.bankName);
    _accountNumberController = TextEditingController(text: s.accountNumber);
    _ifscController = TextEditingController(text: s.ifscCode);
    _branchController = TextEditingController(text: s.branch);

    _termsController = TextEditingController(text: s.defaultTerms);
    _notesController = TextEditingController(text: s.defaultNotes);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();

    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();

    _gstController.dispose();
    _panController.dispose();

    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();

    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = CompanySettingsModel(
        companyName: _companyNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gstNumber: _gstController.text.trim(),
        panNumber: _panController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        branch: _branchController.text.trim(),
        defaultTerms: _termsController.text.trim(),
        defaultNotes: _notesController.text.trim(),
        currency: 'INR',
        currencySymbol: '₹',
      );

      await ref.read(settingsRepositoryProvider).updateCompanySettings(updated);
      ref.invalidate(companySettingsProvider);

      if (mounted) {
        AppToast.success(context, 'Company profile & billing settings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Basic Company Information
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'Company & Business Details',
                  subtitle: 'This information appears in PDF quotations, invoices, and proposals.',
                  icon: Icons.business_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _companyNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Company Name *',
                                  prefixIcon: Icon(Icons.corporate_fare_rounded, size: 20),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Company name is required' : null,
                              ),
                            ),
                            if (!isNarrow) ...[
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Billing / Support Email *',
                                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Email is required' : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isNarrow) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Billing / Support Email *',
                              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Email is required' : null,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                ),
                              ),
                            ),
                            if (!isNarrow) ...[
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _websiteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Website URL',
                                    prefixIcon: Icon(Icons.language_rounded, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isNarrow) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _websiteController,
                            decoration: const InputDecoration(
                              labelText: 'Website URL',
                              prefixIcon: Icon(Icons.language_rounded, size: 20),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Registered Address
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'Registered Office Address',
                  subtitle: 'Official company address for correspondence and tax invoices.',
                  icon: Icons.location_on_outlined,
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    hintText: 'e.g. 402, High-Tech Tower, Baner Road',
                    prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'State'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'Country'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        decoration: const InputDecoration(labelText: 'Postal / Pincode'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Tax Identification & Banking Details
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'Tax & Banking Credentials',
                  subtitle: 'Bank account and tax numbers for client wire transfers and invoices.',
                  icon: Icons.account_balance_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN / Tax ID',
                          hintText: '27AABCH1234F1Z5',
                          prefixIcon: Icon(Icons.receipt_long_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _panController,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                          hintText: 'AABCH1234F',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
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
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name',
                          hintText: 'e.g. HDFC Bank Ltd',
                          prefixIcon: Icon(Icons.account_balance_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _accountNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Account Number',
                          prefixIcon: Icon(Icons.tag_rounded, size: 20),
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
                        controller: _ifscController,
                        decoration: const InputDecoration(
                          labelText: 'IFSC / SWIFT Code',
                          hintText: 'HDFC0001234',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _branchController,
                        decoration: const InputDecoration(
                          labelText: 'Branch Name',
                          hintText: 'Baner Branch, Pune',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Quotation Terms & Notes
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'Default Quotation Terms & Notes',
                  subtitle: 'Standard clauses automatically pre-filled when creating new quotations.',
                  icon: Icons.gavel_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _termsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Default Terms & Conditions',
                    hintText: '1. Quotation is valid for 15 days...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Default Quotation Note',
                    hintText: 'Thank you for your business. We look forward to working with your team.',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving Changes...' : 'Save Company Profile'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
