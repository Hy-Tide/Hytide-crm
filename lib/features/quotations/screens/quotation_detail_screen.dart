// lib/features/quotations/screens/quotation_detail_screen.dart
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
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/quotation_item_model.dart';
import '../models/quotation_model.dart';
import '../providers/quotation_providers.dart';
import '../repositories/quotation_repository.dart';
import '../services/quotation_conversion_service.dart';
import '../widgets/quotation_action_dialogs.dart';
import '../widgets/quotation_pdf_dialog.dart';

class QuotationDetailScreen extends ConsumerStatefulWidget {
  final String quotationId;

  const QuotationDetailScreen({super.key, required this.quotationId});

  @override
  ConsumerState<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends ConsumerState<QuotationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _handleSend(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showSendDialog(context, q);
    if (confirmed && mounted) {
      try {
        await ref.read(quotationRepositoryProvider).markAsSent(q.id);
        ref.read(appEventBusProvider).emit(
          QuotationStatusChangedEvent(
            q.copyWith(status: QuotationStatus.sent),
            oldStatus: q.status,
            newStatus: QuotationStatus.sent,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quotation ${q.quotationNumber} sent to client'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleAccept(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showAcceptDialog(context, q);
    if (confirmed && mounted) {
      try {
        await ref.read(quotationRepositoryProvider).markAsAccepted(q.id);
        ref.read(appEventBusProvider).emit(
          QuotationStatusChangedEvent(
            q.copyWith(status: QuotationStatus.accepted),
            oldStatus: q.status,
            newStatus: QuotationStatus.accepted,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quotation ${q.quotationNumber} accepted!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleReject(QuotationModel q) async {
    final reason = await QuotationActionDialogs.showRejectDialog(context, q);
    if (reason != null && mounted) {
      try {
        await ref.read(quotationRepositoryProvider).markAsRejected(q.id, reason: reason);
        ref.read(appEventBusProvider).emit(
          QuotationStatusChangedEvent(
            q.copyWith(status: QuotationStatus.rejected),
            oldStatus: q.status,
            newStatus: QuotationStatus.rejected,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quotation ${q.quotationNumber} marked as Rejected'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleConvertToProject(QuotationModel q) async {
    final projName = await QuotationActionDialogs.showConvertToProjectDialog(context, q);
    if (projName != null && mounted) {
      try {
        final service = ref.read(quotationConversionServiceProvider);
        final newProjectId = await service.convertQuotationToProject(
          quotation: q,
          projectName: projName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project created successfully! Project ID: $newProjectId'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => context.push('${AppRoutes.projects}/$newProjectId'),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conversion failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleDuplicate(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showDuplicateDialog(context, q);
    if (confirmed && mounted) {
      try {
        final newId = await ref.read(quotationRepositoryProvider).duplicateQuotation(q.id);
        ref.read(appEventBusProvider).emit(
          QuotationCreatedEvent(q.copyWith(id: newId, status: QuotationStatus.draft)),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quotation duplicated as new Draft'),
              backgroundColor: AppColors.success,
            ),
          );
          context.push('${AppRoutes.quotations}/$newId');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to duplicate: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleCreateRevision(QuotationModel q) async {
    final confirmed = await QuotationActionDialogs.showRevisionDialog(context, q);
    if (confirmed && mounted) {
      try {
        final newId = await ref.read(quotationRepositoryProvider).createRevision(q.id);
        ref.read(appEventBusProvider).emit(
          QuotationCreatedEvent(
            q.copyWith(id: newId, revisionNumber: q.revisionNumber + 1, status: QuotationStatus.draft),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Revision ${q.revisionNumber + 1} created as Draft'),
              backgroundColor: AppColors.success,
            ),
          );
          context.push('${AppRoutes.quotations}/$newId');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create revision: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleShareMail(QuotationModel q) async {
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final subject = Uri.encodeComponent('Quotation ${q.quotationNumber} — ${q.title}');
    final body = Uri.encodeComponent(
      'Dear ${q.contactPerson.isNotEmpty ? q.contactPerson : q.clientName},\n\n'
      'Please find our quotation ${q.quotationNumber} for "${q.title}".\n'
      'Quotation Amount: ${inrFormat.format(q.grandTotal)}\n\n'
      'Best regards,\n${q.createdByName}',
    );

    final mailto = Uri.parse('mailto:${q.clientEmail}?subject=$subject&body=$body');
    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto);
    }
  }

  Future<void> _handleShareWhatsApp(QuotationModel q) async {
    final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final cleanPhone = q.clientPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final text = Uri.encodeComponent(
      'Hello ${q.contactPerson.isNotEmpty ? q.contactPerson : q.clientName},\n'
      'Here is quotation ${q.quotationNumber} for "${q.title}".\n'
      'Amount: ${inrFormat.format(q.grandTotal)}.',
    );

    final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$text');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addInternalNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingNote = true);
    try {
      await ref.read(quotationRepositoryProvider).addQuotationNote(widget.quotationId, text);
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added'), backgroundColor: AppColors.success),
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

    final quotationAsync = ref.watch(quotationDetailProvider(widget.quotationId));

    return quotationAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(title: const Text('Quotation Details')),
        body: ErrorState(
          message: 'Failed to load quotation: $err',
          onRetry: () => ref.invalidate(quotationDetailProvider(widget.quotationId)),
        ),
      ),
      data: (q) {
        if (q == null) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
            appBar: AppBar(title: const Text('Quotation Not Found')),
            body: Center(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Quotation not found',
                subtitle: 'The requested quotation may have been deleted.',
                customAction: FilledButton(
                  onPressed: () => context.go(AppRoutes.quotations),
                  child: const Text('Back to Quotations'),
                ),
              ),
            ),
          );
        }

        final dateFormat = DateFormat('dd MMM yyyy');
        final inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
        final effectiveStatus = q.effectiveStatus;
        final isExpired = q.isExpired;

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
          appBar: PlatformCapabilities.isAndroid
              ? AppBar(
                  title: Text(q.quotationNumber),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.quotations);
                      }
                    },
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'PDF & Share',
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () => QuotationPdfDialog.show(context, q),
                    ),
                    if (q.canEdit)
                      IconButton(
                        tooltip: 'Edit Quotation',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('${AppRoutes.quotations}/${q.id}/edit'),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (action) {
                        switch (action) {
                          case 'send':
                            if (q.canSend) _handleSend(q);
                            break;
                          case 'accept':
                            if (q.canAccept) _handleAccept(q);
                            break;
                          case 'reject':
                            if (q.canReject) _handleReject(q);
                            break;
                          case 'convert':
                            if (q.canConvertToProject) _handleConvertToProject(q);
                            break;
                          case 'duplicate':
                            _handleDuplicate(q);
                            break;
                          case 'revise':
                            _handleCreateRevision(q);
                            break;
                          case 'email':
                            _handleShareMail(q);
                            break;
                          case 'whatsapp':
                            _handleShareWhatsApp(q);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (q.canSend)
                          const PopupMenuItem(
                            value: 'send',
                            child: ListTile(
                              leading: Icon(Icons.send_rounded, size: 18),
                              title: Text('Send Quotation'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        if (q.canAccept)
                          const PopupMenuItem(
                            value: 'accept',
                            child: ListTile(
                              leading: Icon(Icons.check_circle_outline_rounded, size: 18),
                              title: Text('Mark Accepted'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        if (q.canReject)
                          const PopupMenuItem(
                            value: 'reject',
                            child: ListTile(
                              leading: Icon(Icons.highlight_off_rounded, size: 18),
                              title: Text('Mark Rejected'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        if (q.canConvertToProject)
                          const PopupMenuItem(
                            value: 'convert',
                            child: ListTile(
                              leading: Icon(Icons.rocket_launch_outlined, size: 18),
                              title: Text('Convert to Project'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        if (q.canRevise)
                          const PopupMenuItem(
                            value: 'revise',
                            child: ListTile(
                              leading: Icon(Icons.history_edu_rounded, size: 18),
                              title: Text('Create Revision'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: ListTile(
                            leading: Icon(Icons.copy_rounded, size: 18),
                            title: Text('Duplicate Quotation'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        if (q.clientEmail.isNotEmpty)
                          const PopupMenuItem(
                            value: 'email',
                            child: ListTile(
                              leading: Icon(Icons.email_outlined, size: 18),
                              title: Text('Compose Email'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        if (q.clientPhone.isNotEmpty)
                          const PopupMenuItem(
                            value: 'whatsapp',
                            child: ListTile(
                              leading: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              title: Text('Share on WhatsApp'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              : null,
          bottomNavigationBar: PlatformCapabilities.isAndroid && (q.canSend || q.canAccept || q.canConvertToProject)
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
                      if (q.canAccept)
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                            onPressed: () => _handleAccept(q),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Accept'),
                          ),
                        ),
                      if (q.canAccept && (q.canSend || q.canConvertToProject)) const SizedBox(width: AppSpacing.sm),
                      if (q.canSend)
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.info),
                            onPressed: () => _handleSend(q),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Send'),
                          ),
                        ),
                      if (q.canSend && q.canConvertToProject) const SizedBox(width: AppSpacing.sm),
                      if (q.canConvertToProject)
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: () => _handleConvertToProject(q),
                            icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                            label: const Text('Convert to Project'),
                          ),
                        ),
                    ],
                  ),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header Card
                Container(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!PlatformCapabilities.isAndroid) ...[
                        Breadcrumbs(
                          items: [
                            const BreadcrumbItem(label: 'Quotations', route: AppRoutes.quotations),
                            BreadcrumbItem(label: q.quotationNumber),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  q.quotationNumber,
                                  style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (q.revisionNumber > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(AppRadius.xs),
                                    ),
                                    child: Text(
                                      'Revision ${q.revisionNumber}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: effectiveStatus.backgroundColor,
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(effectiveStatus.icon, size: 14, color: effectiveStatus.color),
                                      const SizedBox(width: 4),
                                      Text(
                                        effectiveStatus.displayName,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: effectiveStatus.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isExpired && q.status != QuotationStatus.accepted && q.status != QuotationStatus.rejected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer,
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      'Expired',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Quick Action Buttons (Web only, mobile actions are in AppBar and sticky bottom bar)
                          if (!PlatformCapabilities.isAndroid)
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => QuotationPdfDialog.show(context, q),
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                  label: const Text('PDF & Share'),
                                ),
                                if (q.canEdit)
                                  FilledButton.icon(
                                    onPressed: () => context.push('${AppRoutes.quotations}/${q.id}/edit'),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit'),
                                  ),
                                if (q.canSend)
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.info),
                                    onPressed: () => _handleSend(q),
                                    icon: const Icon(Icons.send_rounded, size: 16),
                                    label: const Text('Send Quotation'),
                                  ),
                                if (q.canAccept)
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                                    onPressed: () => _handleAccept(q),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                    label: const Text('Mark Accepted'),
                                  ),
                                if (q.canReject)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                    onPressed: () => _handleReject(q),
                                    icon: const Icon(Icons.highlight_off_rounded, size: 16),
                                    label: const Text('Mark Rejected'),
                                  ),
                                if (q.canConvertToProject)
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                                    onPressed: () => _handleConvertToProject(q),
                                    icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                                    label: const Text('Convert to Project'),
                                  ),
                                if (q.convertedToProject && q.projectId != null)
                                  FilledButton.tonalIcon(
                                    onPressed: () => context.push('${AppRoutes.projects}/${q.projectId}'),
                                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                                    label: const Text('View Project'),
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'duplicate':
                                        _handleDuplicate(q);
                                        break;
                                      case 'revise':
                                        _handleCreateRevision(q);
                                        break;
                                      case 'email':
                                        _handleShareMail(q);
                                        break;
                                      case 'whatsapp':
                                        _handleShareWhatsApp(q);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (q.canRevise)
                                      const PopupMenuItem(
                                        value: 'revise',
                                        child: ListTile(
                                          leading: Icon(Icons.history_edu_rounded, size: 18),
                                          title: Text('Create Revision'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: ListTile(
                                        leading: Icon(Icons.copy_rounded, size: 18),
                                        title: Text('Duplicate Quotation'),
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                    if (q.clientEmail.isNotEmpty)
                                      const PopupMenuItem(
                                        value: 'email',
                                        child: ListTile(
                                          leading: Icon(Icons.email_outlined, size: 18),
                                          title: Text('Compose Email'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                    if (q.clientPhone.isNotEmpty)
                                      const PopupMenuItem(
                                        value: 'whatsapp',
                                        child: ListTile(
                                          leading: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                          title: Text('Share on WhatsApp'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Sub-row: Client & Subject
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.push('${AppRoutes.clients}/${q.clientId}'),
                            child: Row(
                              children: [
                                const Icon(Icons.apartment_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  q.companyName.isNotEmpty ? q.companyName : q.clientName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (q.contactPerson.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text('• Attn: ${q.contactPerson}', style: AppTypography.bodySmall),
                          ],
                          const Spacer(),
                          Text(
                            'Grand Total: ${inrFormat.format(q.grandTotal)}',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Workspace Tabs
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: const [
                          Tab(icon: Icon(Icons.info_outline_rounded, size: 16), text: 'Overview'),
                          Tab(icon: Icon(Icons.format_list_numbered_rounded, size: 16), text: 'Items'),
                          Tab(icon: Icon(Icons.history_rounded, size: 16), text: 'Activity'),
                          Tab(icon: Icon(Icons.note_alt_outlined, size: 16), text: 'Notes'),
                          Tab(icon: Icon(Icons.alt_route_rounded, size: 16), text: 'Revisions'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Overview
                      _buildOverviewTab(q, isDark, dateFormat, inrFormat),

                      // Tab 2: Items
                      _buildItemsTab(q, isDark, inrFormat),

                      // Tab 3: Activity
                      _buildActivityTab(q.id, isDark),

                      // Tab 4: Notes
                      _buildNotesTab(q.id, isDark),

                      // Tab 5: Revisions
                      _buildRevisionsTab(q, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 1: Overview ──────────────────────────────────────────────────────

  Widget _buildOverviewTab(QuotationModel q, bool isDark, DateFormat dateFormat, NumberFormat inrFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric Highlight Cards
          Row(
            children: [
              _buildMetricCard(isDark, 'Grand Total', inrFormat.format(q.grandTotal), Icons.payments_outlined, AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              _buildMetricCard(isDark, 'Subtotal', inrFormat.format(q.subtotal), Icons.receipt_outlined, AppColors.info),
              const SizedBox(width: AppSpacing.md),
              _buildMetricCard(isDark, 'Tax / GST', inrFormat.format(q.taxAmount), Icons.account_balance_outlined, AppColors.secondary),
              const SizedBox(width: AppSpacing.md),
              _buildMetricCard(isDark, 'Valid Until', dateFormat.format(q.expiryDate), Icons.timer_outlined, q.isExpired ? AppColors.error : AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Client & Metadata
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSectionContainer(
                      isDark: isDark,
                      title: 'Client & Project Summary',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Company', q.companyName.isNotEmpty ? q.companyName : q.clientName),
                          _buildDetailRow('Contact Person', q.contactPerson.isNotEmpty ? q.contactPerson : '—'),
                          _buildDetailRow('Phone', q.clientPhone.isNotEmpty ? q.clientPhone : '—'),
                          _buildDetailRow('Email', q.clientEmail.isNotEmpty ? q.clientEmail : '—'),
                          _buildDetailRow('Address', q.clientAddress.isNotEmpty ? q.clientAddress : '—'),
                          const Divider(height: 24),
                          _buildDetailRow('Subject', q.title),
                          if (q.description.isNotEmpty)
                            _buildDetailRow('Description', q.description),
                          _buildDetailRow('Assigned Staff', q.assignedToName.isNotEmpty ? q.assignedToName : 'Admin'),
                        ],
                      ),
                    ),
                    if (q.notes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildSectionContainer(
                        isDark: isDark,
                        title: 'Notes to Customer',
                        child: Text(q.notes, style: AppTypography.bodyMedium),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Right Column: Financial Breakdown & Terms
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildSectionContainer(
                      isDark: isDark,
                      title: 'Financial Breakdown',
                      child: Column(
                        children: [
                          _buildFinancialRow('Subtotal', inrFormat.format(q.subtotal)),
                          if (q.discountAmount > 0)
                            _buildFinancialRow('Discount', '- ${inrFormat.format(q.discountAmount)}', isDiscount: true),
                          _buildFinancialRow('Taxable Amount', inrFormat.format(q.subtotal - q.discountAmount)),
                          _buildFinancialRow('Tax Amount', inrFormat.format(q.taxAmount)),
                          if (q.shippingAmount > 0)
                            _buildFinancialRow('Shipping', inrFormat.format(q.shippingAmount)),
                          if (q.otherCharges > 0)
                            _buildFinancialRow('Other Charges', inrFormat.format(q.otherCharges)),
                          const Divider(height: 20),
                          _buildFinancialRow('Grand Total', inrFormat.format(q.grandTotal), isTotal: true),
                        ],
                      ),
                    ),
                    if (q.termsAndConditions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildSectionContainer(
                        isDark: isDark,
                        title: 'Terms & Conditions',
                        child: Text(q.termsAndConditions, style: AppTypography.bodySmall),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Items ─────────────────────────────────────────────────────────

  Widget _buildItemsTab(QuotationModel q, bool isDark, NumberFormat inrFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(48),
              1: FlexColumnWidth(4),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(2),
              5: FlexColumnWidth(1.8),
              6: FlexColumnWidth(1.5),
              7: FlexColumnWidth(2.2),
            },
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.surfaceVariant.withValues(alpha: 0.5),
                ),
                children: const [
                  Padding(padding: EdgeInsets.all(12), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Item Name & Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Tax %', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              // Data Rows
              for (int i = 0; i < q.items.length; i++)
                _buildItemTableRow(i, q.items[i], inrFormat),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildItemTableRow(int index, QuotationItemModel item, NumberFormat inrFormat) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text('${index + 1}')),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (item.description.isNotEmpty)
                Text(item.description, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Text(item.itemType.displayName)),
        Padding(padding: const EdgeInsets.all(12), child: Text('${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}')),
        Padding(padding: const EdgeInsets.all(12), child: Text(inrFormat.format(item.unitPrice))),
        Padding(padding: const EdgeInsets.all(12), child: Text(item.discountAmount > 0 ? inrFormat.format(item.discountAmount) : '—')),
        Padding(padding: const EdgeInsets.all(12), child: Text('${item.taxPercentage.toStringAsFixed(0)}%')),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            inrFormat.format(item.lineTotal),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ─── Tab 3: Activity Timeline ─────────────────────────────────────────────

  Widget _buildActivityTab(String quotationId, bool isDark) {
    final activitiesAsync = ref.watch(quotationActivitiesProvider(quotationId));
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading activities: $e')),
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(child: Text('No quotation activities recorded yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final act = activities[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(act.title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(act.description, style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          '${act.createdByName} • ${dateFormat.format(act.createdAt)}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Tab 4: Internal Notes ────────────────────────────────────────────────

  Widget _buildNotesTab(String quotationId, bool isDark) {
    final notesAsync = ref.watch(quotationNotesProvider(quotationId));
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Note Entry Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add an internal quotation note (visible to admins only)...',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: _isAddingNote ? null : _addInternalNote,
                icon: _isAddingNote
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_comment_rounded, size: 16),
                label: const Text('Add Note'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Notes List
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading notes: $e')),
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(child: Text('No internal notes added yet.'));
                }

                return ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final n = notes[i];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.note, style: AppTypography.bodyMedium),
                                const SizedBox(height: 4),
                                Text(
                                  '${n.createdByName} • ${dateFormat.format(n.createdAt)}',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            onPressed: () => ref.read(quotationRepositoryProvider).deleteQuotationNote(quotationId, n.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 5: Revisions ─────────────────────────────────────────────────────

  Widget _buildRevisionsTab(QuotationModel q, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                    const Icon(Icons.alt_route_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Revision History for ${q.quotationNumber}',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Current Version: Revision ${q.revisionNumber}'),
                if (q.parentQuotationId != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('${AppRoutes.quotations}/${q.parentQuotationId}'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('View Previous Revision'),
                  ),
                ] else
                  const Text('This is the original base quotation.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => _handleCreateRevision(q),
                  icon: const Icon(Icons.history_edu_rounded, size: 16),
                  label: Text('Create Revision ${q.revisionNumber + 1}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared UI Helper Components ──────────────────────────────────────────

  Widget _buildMetricCard(bool isDark, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required bool isDark, required String title, required Widget child}) {
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
          Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 13,
              color: isDiscount
                  ? AppColors.error
                  : isTotal
                      ? AppColors.primary
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
