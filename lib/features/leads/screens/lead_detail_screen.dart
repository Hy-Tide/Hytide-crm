import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/lead_model.dart';
import '../providers/lead_providers.dart';
import '../repositories/lead_repository.dart';
import '../utils/lead_launcher_utils.dart';
import '../widgets/lead_activity_timeline.dart';
import '../widgets/lead_notes_view.dart';
import '../widgets/lead_status_dialog.dart';
import '../../clients/services/lead_conversion_service.dart';
import '../../clients/widgets/lead_conversion_dialog.dart';
import '../../followups/repositories/followup_repository.dart';
import '../../followups/widgets/followup_card_item.dart';
import '../../documents/repositories/document_repository.dart';
import '../../documents/widgets/document_table_view.dart';
import '../../documents/widgets/upload_document_dialog.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailStreamProvider(leadId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        top: false, // The CustomScrollView handles the top area
        child: leadAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(leadDetailStreamProvider(leadId)),
          ),
          data: (lead) {
            if (lead == null) {
              return EmptyState(
                icon: Icons.person_off_rounded,
                title: 'Lead not found',
                subtitle: 'This lead may have been deleted or archived.',
                actionLabel: 'Back to Leads',
                onAction: () => context.go(AppRoutes.leads),
              );
            }

            return _LeadDetailContent(lead: lead);
          },
        ),
      ),
    );
  }
}

class _LeadDetailContent extends ConsumerWidget {
  final LeadModel lead;
  const _LeadDetailContent({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final currencyFmt = NumberFormat.currency(
      symbol: lead.currency.toUpperCase() == 'INR' ? '₹' : '\$',
      decimalDigits: 0,
    );
    final valueText = currencyFmt.format(lead.estimatedValue);
    final displayName = lead.companyName.isNotEmpty ? lead.companyName : lead.contactPerson;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 1,
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          surfaceTintColor: Colors.transparent,
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
          title: Text(
            displayName,
            style: AppTypography.heading4.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          actions: [
            if (lead.phone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: AppColors.primaryBlue),
                onPressed: () => LeadLauncherUtils.launchPhone(context, lead.phone),
              ),
            if (lead.phone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.success),
                onPressed: () => LeadLauncherUtils.launchWhatsApp(context, lead.phone),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Lead',
              onPressed: () => context.go('${AppRoutes.leads}/${lead.id}/edit'),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Breadcrumbs (Web only)
                    if (!PlatformCapabilities.isAndroid) ...[
                      Breadcrumbs(
                        items: [
                          const BreadcrumbItem(
                            label: 'Home',
                            route: AppRoutes.dashboard,
                          ),
                          const BreadcrumbItem(
                            label: 'Leads',
                            route: AppRoutes.leads,
                          ),
                          BreadcrumbItem(
                            label: displayName,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Strip (Now directly at the top)
                          _buildSummaryStrip(isDark, valueText),

                          if (lead.status == LeadStatus.lost &&
                              lead.lostReason != null &&
                              lead.lostReason!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lost Reason: ${lead.lostReason}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),

                          // Action Buttons Grouped
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.md,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Primary Horizontal Row (Icons only)
                              if (lead.phone.isNotEmpty)
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                                  onPressed: () => LeadLauncherUtils.launchPhone(context, lead.phone),
                                  icon: const Icon(Icons.phone_rounded, size: 20),
                                ),
                              if (lead.phone.isNotEmpty)
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: AppColors.success),
                                  onPressed: () => LeadLauncherUtils.launchWhatsApp(context, lead.phone),
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                                ),
                              if (lead.email.isNotEmpty)
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: AppColors.info),
                                  onPressed: () => LeadLauncherUtils.launchEmail(context, lead.email),
                                  icon: const Icon(Icons.email_rounded, size: 20),
                                ),

                              const SizedBox(width: AppSpacing.xs),

                              // Secondary actions
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  context.push(
                                    '${AppRoutes.followupCreate}?leadId=${lead.id}&companyName=${Uri.encodeComponent(lead.companyName)}',
                                  );
                                },
                                icon: const Icon(Icons.add_alarm_rounded, size: 16),
                                label: const Text('Follow-up'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  final res = await LeadStatusDialog.showForLead(context, lead);
                                  if (res != null && res.status != lead.status) {
                                    final repo = ref.read(leadRepositoryProvider);
                                    await repo.updateLeadStatus(
                                      lead.id,
                                      res.status,
                                      lostReason: res.lostReason,
                                      userName: 'Admin',
                                    );
                                    ref.read(appEventBusProvider).emit(
                                      LeadStatusChangedEvent(
                                        lead.copyWith(
                                          status: res.status,
                                          lostReason: res.lostReason,
                                        ),
                                        oldStatus: lead.status,
                                        newStatus: res.status,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text('Status'),
                              ),
                              PopupMenuButton<String>(
                                offset: const Offset(0, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.more_horiz_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'More',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: isDark
                                              ? AppColors.onSurfaceDark
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: (action) =>
                                    _handleMoreAction(context, ref, action),
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'convert',
                                    child: Row(
                                      children: [
                                        Icon(Icons.how_to_reg_rounded, size: 16, color: AppColors.success),
                                        const SizedBox(width: 8),
                                        const Text('Convert to Client'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: lead.isArchived ? 'unarchive' : 'archive',
                                    child: Row(
                                      children: [
                                        Icon(
                                          lead.isArchived
                                              ? Icons.unarchive_outlined
                                              : Icons.archive_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          lead.isArchived ? 'Unarchive' : 'Archive',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Lead',
                                          style: TextStyle(color: AppColors.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Two Column layout on desktop: Left is Overview Details, Right is Activity / Notes Tabs
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 380, child: _buildDetailsPanel(isDark)),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(child: _buildTabsCard(context, ref, isDark)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDetailsPanel(isDark),
                              const SizedBox(height: AppSpacing.lg),
                              _buildTabsCard(context, ref, isDark),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip(bool isDark, String valueText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          // Value
          _buildSummaryItem(
            icon: Icons.payments_rounded,
            color: const Color(0xFF10B981), // Emerald
            label: 'Deal Value',
            value: valueText,
            isDark: isDark,
          ),
          // Status
          _buildSummaryItem(
            icon: Icons.flag_circle_rounded,
            color: const Color(0xFF3B82F6), // Blue
            label: 'Status',
            value: lead.status.name.toUpperCase(),
            isDark: isDark,
          ),
          // Priority
          _buildSummaryItem(
            icon: Icons.priority_high_rounded,
            color: lead.priority == LeadPriority.high
                ? AppColors.error
                : lead.priority == LeadPriority.medium
                    ? AppColors.warning
                    : AppColors.info,
            label: 'Priority',
            value: lead.priority.name.toUpperCase(),
            isDark: isDark,
          ),
          // Probability
          _buildSummaryItem(
            icon: Icons.analytics_rounded,
            color: lead.probability > 70
                ? const Color(0xFF10B981) // Green for high
                : lead.probability < 30
                    ? const Color(0xFFEF4444) // Red for low
                    : const Color(0xFFF59E0B), // Orange for mid
            label: 'Probability',
            value: '${lead.probability}%',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lead Overview',
            style: AppTypography.heading4.copyWith(
              color: isDark ? Colors.white : AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // 2-Column Layout Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildGridItem(
                icon: Icons.person_pin_outlined,
                label: 'Assigned To',
                value: lead.assignedToName.isNotEmpty ? lead.assignedToName : 'Unassigned',
                isDark: isDark,
              ),
              if (lead.phone.isNotEmpty)
                _buildGridItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: lead.phone,
                  isDark: isDark,
                ),
              if (lead.whatsappNumber.isNotEmpty)
                _buildGridItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  value: lead.whatsappNumber,
                  isDark: isDark,
                ),
              if (lead.email.isNotEmpty)
                _buildGridItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: lead.email,
                  isDark: isDark,
                ),
              if (lead.website.isNotEmpty)
                _buildGridItem(
                  icon: Icons.language_rounded,
                  label: 'Website',
                  value: lead.website,
                  isDark: isDark,
                ),
              if (lead.industry.isNotEmpty)
                _buildGridItem(
                  icon: Icons.category_outlined,
                  label: 'Industry',
                  value: lead.industry,
                  isDark: isDark,
                ),
              if (lead.address.isNotEmpty || lead.city.isNotEmpty)
                _buildGridItem(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: [lead.address, lead.city, lead.state, lead.country]
                      .where((e) => e.isNotEmpty)
                      .join(', '),
                  isDark: isDark,
                ),
              if (lead.expectedCloseDate != null)
                _buildGridItem(
                  icon: Icons.event_available_outlined,
                  label: 'Expected Close',
                  value: DateFormat('dd MMM yyyy').format(lead.expectedCloseDate!),
                  isDark: isDark,
                ),
              _buildGridItem(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: DateFormat('dd MMM yyyy, h:mm a').format(lead.createdAt),
                isDark: isDark,
              ),
            ],
          ),

          // Requirements
          if (lead.requirements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Requirements',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lead.requirements,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],

          // Tags
          if (lead.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tags',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: lead.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Tab _buildBadgeTab(String text, IconData icon, int count) {
    return Tab(
      height: 44, // Make tabs a bit taller for modern pill style
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabsCard(BuildContext context, WidgetRef ref, bool isDark) {
    final activitiesCount = ref.watch(leadActivitiesStreamProvider(lead.id)).maybeWhen(
      data: (data) => data.length,
      orElse: () => 0,
    );
    final notesCount = ref.watch(leadNotesStreamProvider(lead.id)).maybeWhen(
      data: (data) => data.length,
      orElse: () => 0,
    );
    final followupsCount = ref.watch(leadFollowUpsStreamProvider(lead.id)).maybeWhen(
      data: (data) => data.length,
      orElse: () => 0,
    );
    final docsCount = ref.watch(documentsByLeadProvider(lead.id)).maybeWhen(
      data: (data) => data.length,
      orElse: () => 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
              ),
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                _buildBadgeTab('Activity', Icons.history_rounded, activitiesCount),
                _buildBadgeTab('Notes', Icons.notes_rounded, notesCount),
                _buildBadgeTab('Follow-ups', Icons.alarm_rounded, followupsCount),
                _buildBadgeTab('Documents', Icons.description_outlined, docsCount),
                _buildBadgeTab('Quotations', Icons.request_quote_outlined, 0),
              ],
            ),
            const Divider(height: 1),
            SizedBox(
              height: 520,
              child: TabBarView(
                children: [
                  LeadActivityTimeline(leadId: lead.id),
                  LeadNotesView(leadId: lead.id),
                  _LeadFollowUpsTab(lead: lead),
                  _LeadDocumentsTab(lead: lead),
                  _buildPlaceholderTab(
                    icon: Icons.request_quote_outlined,
                    title: 'Quotations Module',
                    subtitle:
                        'Price quotes and invoices linked to this lead will appear here.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.heading4.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMoreAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repo = ref.read(leadRepositoryProvider);
    switch (action) {
      case 'convert':
        final eligibility = ref
            .read(leadConversionServiceProvider)
            .checkEligibility(lead);

        if (!eligibility.isEligible) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.warning,
                size: 36,
              ),
              title: const Text(
                'Not Ready for Conversion',
              ),
              content: Text(
                eligibility.message ??
                    'Mark the lead as Won before converting it to a client.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        final newClientId =
            await LeadConversionDialog.show(
              context,
              lead,
            );
        if (newClientId != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lead converted successfully.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.push(
            '${AppRoutes.clients}/$newClientId',
          );
        }
        break;
      case 'archive':
      case 'unarchive':
        final willArchive = action == 'archive';
        await repo.toggleArchiveLead(lead.id, willArchive);
        ref
            .read(appEventBusProvider)
            .emit(LeadUpdatedEvent(lead.copyWith(isArchived: willArchive)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willArchive ? 'Lead archived' : 'Lead unarchived'),
            ),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Lead'),
            content: Text(
              'Are you sure you want to delete "${lead.companyName}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await repo.deleteLead(lead.id);
          ref.read(appEventBusProvider).emit(LeadDeletedEvent(lead.id));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Lead deleted')));
            context.go(AppRoutes.leads);
          }
        }
        break;
    }
  }
}

class _LeadFollowUpsTab extends ConsumerWidget {
  final LeadModel lead;

  const _LeadFollowUpsTab({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final followupsAsync = ref.watch(leadFollowUpsStreamProvider(lead.id));

    return followupsAsync.when(
      data: (followups) {
        if (followups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.alarm_add_rounded,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No follow-ups scheduled for this lead',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Set a reminder or call schedule to keep this opportunity active.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    context.push(
                      '${AppRoutes.followupCreate}?leadId=${lead.id}&companyName=${Uri.encodeComponent(lead.companyName)}',
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Schedule Follow-up'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Scheduled Follow-ups (${followups.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      '${AppRoutes.followupCreate}?leadId=${lead.id}&companyName=${Uri.encodeComponent(lead.companyName)}',
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Follow-up'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...followups.map((f) => FollowUpCardItem(followup: f)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading follow-ups: $err')),
    );
  }
}

class _LeadDocumentsTab extends ConsumerWidget {
  final LeadModel lead;
  const _LeadDocumentsTab({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsByLeadProvider(lead.id));

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (docs) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${docs.length} ${docs.length == 1 ? "Document" : "Documents"}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => UploadDocumentDialog.show(
                      context,
                      initialLeadId: lead.id,
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload Document'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (docs.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No documents for this lead',
                  subtitle:
                      'Upload agreements, requirements, proposals, or contracts.',
                  customAction: FilledButton.icon(
                    onPressed: () => UploadDocumentDialog.show(
                      context,
                      initialLeadId: lead.id,
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload Document'),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: DocumentTableView(documents: docs),
                ),
              ),
          ],
        );
      },
    );
  }
}
