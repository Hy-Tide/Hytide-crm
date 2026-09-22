// lib/features/quotations/screens/quotation_form_screen.dart
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
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/client_select_dialog.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/models/client_model.dart';
import '../../clients/repositories/client_repository.dart';
import '../../leads/providers/lead_providers.dart';
import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';
import '../providers/quotation_providers.dart';
import '../repositories/quotation_repository.dart';
import '../services/quotation_calculation_service.dart';
import '../widgets/quotation_pdf_dialog.dart';

class QuotationFormScreen extends ConsumerStatefulWidget {
  final String? quotationId;
  final String? initialClientId;

  const QuotationFormScreen({
    super.key,
    this.quotationId,
    this.initialClientId,
  });

  @override
  ConsumerState<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calcService = const QuotationCalculationService();

  bool _isLoading = false;
  bool _isSaving = false;

  // Selected Client Details
  String _clientId = '';
  String _clientName = '';
  String _companyName = '';
  String _contactPerson = '';
  String _clientEmail = '';
  String _clientPhone = '';
  String _clientAddress = '';
  String? _sourceLeadId;

  // Quotation Meta
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _issueDate = TimezoneHelper.now();
  DateTime _expiryDate = TimezoneHelper.now().add(const Duration(days: 15));
  String _currency = 'INR';

  // Staff Assignment
  String _assignedTo = '';
  String _assignedToName = '';

  // Line Items
  final List<QuotationItemModel> _items = [];

  // Quotation-Level Modifiers
  DiscountType _discountType = DiscountType.percentage;
  final _discountValueController = TextEditingController(text: '0');
  TaxType _taxType = TaxType.gst;
  final _taxPercentageController = TextEditingController(text: '18');
  final _shippingController = TextEditingController(text: '0');
  final _otherChargesController = TextEditingController(text: '0');

  // Notes & Terms
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  // Existing quotation metadata if editing
  QuotationModel? _existingQuotation;
  bool get isEdit => widget.quotationId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _taxPercentageController.dispose();
    _shippingController.dispose();
    _otherChargesController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final auth = ref.read(authRepositoryProvider);
    _assignedTo = auth.currentUserId ?? '';
    _assignedToName = auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Admin';

    // Load company default terms if new
    if (!isEdit) {
      final company = await ref.read(companySettingsProvider.future);
      _termsController.text = company.defaultTerms;
      _notesController.text = company.defaultNotes;

      // Add 1 default line item
      _items.add(
        QuotationItemModel(
          id: 'temp-1',
          name: '',
          description: '',
          itemType: QuotationItemType.service,
          quantity: 1.0,
          unit: 'Units',
          unitPrice: 0.0,
          discountType: DiscountType.percentage,
          discountValue: 0.0,
          discountAmount: 0.0,
          taxPercentage: 18.0,
          taxAmount: 0.0,
          lineSubtotal: 0.0,
          lineTotal: 0.0,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    // If initialClientId provided (e.g. from Client Details tab)
    if (widget.initialClientId != null && widget.initialClientId!.isNotEmpty) {
      try {
        final client = await ref.read(clientRepositoryProvider).getClientById(widget.initialClientId!);
        if (client != null) _selectClient(client);
      } catch (_) {}
    }

    // If editing existing quotation
    if (isEdit) {
      try {
        final q = await ref.read(quotationRepositoryProvider).getQuotationById(widget.quotationId!);
        if (q != null) {
          _existingQuotation = q;
          _clientId = q.clientId;
          _clientName = q.clientName;
          _companyName = q.companyName;
          _contactPerson = q.contactPerson;
          _clientEmail = q.clientEmail;
          _clientPhone = q.clientPhone;
          _clientAddress = q.clientAddress;
          _sourceLeadId = q.sourceLeadId;

          _titleController.text = q.title;
          _descriptionController.text = q.description;
          _issueDate = q.issueDate;
          _expiryDate = q.expiryDate;
          _currency = q.currency;
          _assignedTo = q.assignedTo;
          _assignedToName = q.assignedToName;

          _discountType = q.discountType;
          _discountValueController.text = q.discountValue.toString();
          _taxType = q.taxType;
          _taxPercentageController.text = q.taxPercentage.toString();
          _shippingController.text = q.shippingAmount.toString();
          _otherChargesController.text = q.otherCharges.toString();

          _notesController.text = q.notes;
          _termsController.text = q.termsAndConditions;

          _items.clear();
          _items.addAll(q.items);
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _selectClient(ClientModel client) {
    setState(() {
      _clientId = client.id;
      _clientName = client.companyName;
      _companyName = client.companyName;
      _contactPerson = client.contactPerson;
      _clientEmail = client.email;
      _clientPhone = client.phone;
      _clientAddress = client.formattedAddress;
      _sourceLeadId = client.sourceLeadId;
    });
  }

  // ─── Calculation Getters ──────────────────────────────────────────────────

  QuotationTotalsResult get _currentTotals {
    final discVal = double.tryParse(_discountValueController.text.trim()) ?? 0.0;
    final taxPct = double.tryParse(_taxPercentageController.text.trim()) ?? 0.0;
    final shipping = double.tryParse(_shippingController.text.trim()) ?? 0.0;
    final other = double.tryParse(_otherChargesController.text.trim()) ?? 0.0;

    return _calcService.calculateQuotationTotals(
      items: _items,
      discountType: _discountType,
      discountValue: discVal,
      taxType: _taxType,
      quotationTaxPercentage: taxPct,
      shippingAmount: shipping,
      otherCharges: other,
    );
  }

  QuotationModel _buildModel({QuotationStatus status = QuotationStatus.draft}) {
    final totals = _currentTotals;
    final now = DateTime.now();

    return QuotationModel(
      id: widget.quotationId ?? '',
      quotationNumber: _existingQuotation?.quotationNumber ?? '',
      revisionNumber: _existingQuotation?.revisionNumber ?? 1,
      parentQuotationId: _existingQuotation?.parentQuotationId,
      clientId: _clientId,
      clientName: _clientName,
      companyName: _companyName,
      contactPerson: _contactPerson,
      clientEmail: _clientEmail,
      clientPhone: _clientPhone,
      clientAddress: _clientAddress,
      sourceLeadId: _sourceLeadId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: status,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      currency: _currency,
      items: _items,
      subtotal: totals.subtotal,
      discountType: _discountType,
      discountValue: double.tryParse(_discountValueController.text.trim()) ?? 0.0,
      discountAmount: totals.discountAmount,
      taxType: _taxType,
      taxPercentage: double.tryParse(_taxPercentageController.text.trim()) ?? 0.0,
      taxAmount: totals.taxAmount,
      shippingAmount: totals.shippingAmount,
      otherCharges: totals.otherCharges,
      grandTotal: totals.grandTotal,
      notes: _notesController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      assignedTo: _assignedTo,
      assignedToName: _assignedToName,
      createdBy: _existingQuotation?.createdBy ?? _assignedTo,
      createdByName: _existingQuotation?.createdByName ?? _assignedToName,
      createdAt: _existingQuotation?.createdAt ?? now,
      updatedAt: now,
      sentAt: status == QuotationStatus.sent ? now : _existingQuotation?.sentAt,
      viewedAt: _existingQuotation?.viewedAt,
      acceptedAt: _existingQuotation?.acceptedAt,
      rejectedAt: _existingQuotation?.rejectedAt,
      rejectionReason: _existingQuotation?.rejectionReason,
      convertedToProject: _existingQuotation?.convertedToProject ?? false,
      projectId: _existingQuotation?.projectId,
      isArchived: _existingQuotation?.isArchived ?? false,
      pdfUrl: _existingQuotation?.pdfUrl,
      pdfStoragePath: _existingQuotation?.pdfStoragePath,
      pdfGeneratedAt: _existingQuotation?.pdfGeneratedAt,
      pdfVersion: _existingQuotation?.pdfVersion ?? 1,
    );
  }

  // ─── Save & Workflow Actions ──────────────────────────────────────────────

  Future<void> _handleSave({bool andSend = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client for this quotation'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item'), backgroundColor: AppColors.error),
      );
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      if (_items[i].name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${i + 1} must have a name'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    if (_expiryDate.isBefore(_issueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry date cannot be earlier than the issue date'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final model = _buildModel(status: andSend ? QuotationStatus.sent : QuotationStatus.draft);

      String resultId;
      final bus = ref.read(appEventBusProvider);
      if (isEdit) {
        await repo.updateQuotation(quotation: model, items: _items);
        resultId = widget.quotationId!;
        bus.emit(QuotationUpdatedEvent(model));
      } else {
        resultId = await repo.createQuotation(quotation: model, items: _items);
        bus.emit(QuotationCreatedEvent(model.copyWith(id: resultId)));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Quotation updated successfully'
                  : andSend
                      ? 'Quotation created and marked as Sent!'
                      : 'Quotation saved as Draft',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('${AppRoutes.quotations}/$resultId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quotation: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handlePreview() {
    final model = _buildModel();
    QuotationPdfDialog.show(context, model);
  }

  // ─── Item List Modifications ──────────────────────────────────────────────

  void _addItem() {
    setState(() {
      _items.add(
        QuotationItemModel(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          name: '',
          description: '',
          itemType: QuotationItemType.service,
          quantity: 1.0,
          unit: 'Units',
          unitPrice: 0.0,
          discountType: DiscountType.percentage,
          discountValue: 0.0,
          discountAmount: 0.0,
          taxPercentage: 18.0,
          taxAmount: 0.0,
          lineSubtotal: 0.0,
          lineTotal: 0.0,
          sortOrder: _items.length,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required')),
      );
      return;
    }
    setState(() => _items.removeAt(index));
  }

  void _updateItem(int index, QuotationItemModel updated) {
    setState(() {
      _items[index] = _calcService.calculateLineItem(item: updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffAsync = ref.watch(activeUsersProvider);

    final dateFormat = DateFormat('dd MMM yyyy');
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final totals = _currentTotals;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Quotation' : 'New Quotation'),
          leading: PlatformCapabilities.isAndroid
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.quotations);
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
                    context.go(AppRoutes.quotations);
                  }
                },
              )
            : null,
        title: Text(isEdit ? 'Edit Quotation (${_existingQuotation?.quotationNumber})' : 'Create Quotation'),
        actions: PlatformCapabilities.isAndroid
            ? [
                IconButton(
                  onPressed: _handlePreview,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'PDF Preview',
                ),
                const SizedBox(width: AppSpacing.xs),
              ]
            : [
                TextButton.icon(
                  onPressed: _handlePreview,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF Preview'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _isSaving ? null : () => _handleSave(andSend: false),
                  child: const Text('Save Draft'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : () => _handleSave(andSend: true),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Save & Send'),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _handleSave(andSend: false),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : () => _handleSave(andSend: true),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Save & Send'),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs (Web only)
                if (!PlatformCapabilities.isAndroid) ...[
                  Breadcrumbs(
                    items: [
                      const BreadcrumbItem(label: 'Quotations', route: AppRoutes.quotations),
                      BreadcrumbItem(label: isEdit ? 'Edit Quotation' : 'New Quotation'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Section 1: Client Selection
                _buildCard(
                  isDark: isDark,
                  title: 'Client Information',
                  subtitle: 'Select the client for whom this commercial quotation is prepared.',
                  icon: Icons.business_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_clientId.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  _companyName.isNotEmpty ? _companyName[0].toUpperCase() : 'C',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _companyName.isNotEmpty ? _companyName : _contactPerson,
                                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Contact: $_contactPerson · Phone: $_clientPhone · Email: $_clientEmail',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text('Change Client'),
                                onPressed: () async {
                                  final selected = await ClientSelectDialog.show(
                                    context,
                                    selectedClientId: _clientId.isNotEmpty ? _clientId : null,
                                  );
                                  if (selected != null) _selectClient(selected);
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        InkWell(
                          onTap: () async {
                            final selected = await ClientSelectDialog.show(
                              context,
                              selectedClientId: _clientId.isNotEmpty ? _clientId : null,
                            );
                            if (selected != null) _selectClient(selected);
                          },
                          borderRadius: BorderRadius.circular(AppRadius.r8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.r8),
                              border: Border.all(
                                color: isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.apartment_rounded, size: 20, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'Select Client *',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_drop_down_rounded, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section 2: Quotation Details
                _buildCard(
                  isDark: isDark,
                  title: 'Quotation Meta & Terms',
                  subtitle: 'Title, dates, currency, and staff assignment.',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Quotation Title / Subject *',
                                hintText: 'e.g. Mobile App & Cloud Backend Development',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: staffAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, stack) => const SizedBox.shrink(),
                              data: (staff) {
                                return DropdownButtonFormField<String>(
                                  initialValue: staff.any((s) => s.uid == _assignedTo)
                                      ? _assignedTo
                                      : (staff.isNotEmpty ? staff.first.uid : null),
                                  decoration: const InputDecoration(
                                    labelText: 'Assigned Staff',
                                    prefixIcon: Icon(Icons.person_pin_outlined),
                                  ),
                                  items: staff.map((s) => DropdownMenuItem(value: s.uid, child: Text(s.displayName))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final selected = staff.firstWhere((s) => s.uid == val);
                                      setState(() {
                                        _assignedTo = selected.uid;
                                        _assignedToName = selected.displayName;
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          // Issue Date Picker
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _issueDate,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _issueDate = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Issue Date *',
                                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                ),
                                child: Text(dateFormat.format(_issueDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Expiry Date Picker
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _expiryDate,
                                  firstDate: _issueDate,
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _expiryDate = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date *',
                                  prefixIcon: Icon(Icons.timer_outlined, size: 18),
                                ),
                                child: Text(dateFormat.format(_expiryDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Currency
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _currency,
                              decoration: const InputDecoration(
                                labelText: 'Currency',
                                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _currency = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section 3: Dynamic Line Items
                _buildCard(
                  isDark: isDark,
                  title: 'Line Items',
                  subtitle: 'Products, services, rates, quantities, item-level discounts and taxes.',
                  icon: Icons.format_list_numbered_rounded,
                  trailing: FilledButton.tonalIcon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Item'),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _items.length; i++)
                        _buildItemRow(i, _items[i], isDark, inrFormat),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section 4: Pricing & Taxes Summary
                _buildCard(
                  isDark: isDark,
                  title: 'Totals & Additional Charges',
                  subtitle: 'Quotation-wide discounts, shipping, and grand total.',
                  icon: Icons.calculate_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<DiscountType>(
                              initialValue: _discountType,
                              decoration: const InputDecoration(labelText: 'Overall Discount Type'),
                              items: DiscountType.values.map(
                                (d) => DropdownMenuItem(value: d, child: Text(d.displayName)),
                              ).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _discountType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _discountValueController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Discount Value'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _shippingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Shipping / Logistics (₹)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _otherChargesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Other Charges (₹)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Grand Total Breakout Box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariant.withValues(alpha: 0.1) : AppColors.surfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            _buildBreakoutRow('Items Subtotal', inrFormat.format(totals.subtotal)),
                            if (totals.discountAmount > 0)
                              _buildBreakoutRow('Quotation Discount', '- ${inrFormat.format(totals.discountAmount)}', isNegative: true),
                            _buildBreakoutRow('Taxable Amount', inrFormat.format(totals.taxableAmount)),
                            _buildBreakoutRow('Taxes', inrFormat.format(totals.taxAmount)),
                            if (totals.shippingAmount > 0)
                              _buildBreakoutRow('Shipping', inrFormat.format(totals.shippingAmount)),
                            if (totals.otherCharges > 0)
                              _buildBreakoutRow('Other Charges', inrFormat.format(totals.otherCharges)),
                            const Divider(height: 16),
                            _buildBreakoutRow('Grand Total', inrFormat.format(totals.grandTotal), isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section 5: Notes & Terms
                _buildCard(
                  isDark: isDark,
                  title: 'Notes & Terms and Conditions',
                  subtitle: 'Additional instructions, delivery schedule, and legal terms.',
                  icon: Icons.description_outlined,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Customer Notes',
                          hintText: 'e.g. Payment schedule will be discussed before kickoff.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _termsController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Terms & Conditions',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Row Builders ─────────────────────────────────────────────────────────

  Widget _buildItemRow(int index, QuotationItemModel item, bool isDark, NumberFormat inrFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item #${index + 1}',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'Remove Item',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.name,
                  decoration: const InputDecoration(labelText: 'Item Name *'),
                  onChanged: (val) => _updateItem(index, item.copyWith(name: val)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Type
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<QuotationItemType>(
                  initialValue: item.itemType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: QuotationItemType.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.displayName)),
                  ).toList(),
                  onChanged: (val) {
                    if (val != null) _updateItem(index, item.copyWith(itemType: val));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Qty
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed != null) _updateItem(index, item.copyWith(quantity: parsed));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Unit Price
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.unitPrice.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (₹)'),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed != null) _updateItem(index, item.copyWith(unitPrice: parsed));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Tax %
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: item.taxPercentage.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tax %'),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed != null) _updateItem(index, item.copyWith(taxPercentage: parsed));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Line Total
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariant.withValues(alpha: 0.1) : AppColors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  inrFormat.format(item.lineTotal),
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: item.description,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Scope, deliverables, or specifications',
            ),
            onChanged: (val) => _updateItem(index, item.copyWith(description: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakoutRow(String label, String value, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? AppColors.error
                  : isBold
                      ? AppColors.primary
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
