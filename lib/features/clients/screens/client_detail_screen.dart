// lib/features/clients/screens/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/services/timezone_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../followups/widgets/followup_card_item.dart';
import '../models/client_model.dart';
import '../providers/client_providers.dart';
import '../repositories/client_repository.dart';
import '../../quotations/providers/quotation_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../../../core/widgets/app_badge.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _newNoteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _launchCall(String phone) async {
    if (phone.trim().isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.trim().isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.trim().isEmpty) return;
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _changeStatus(ClientModel client) async {
    final selectedStatus = await showDialog<ClientStatus>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Client Status'),
        children: ClientStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(status),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(status.displayName),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selectedStatus != null && selectedStatus != client.status) {
      final repo = ref.read(clientRepositoryProvider);
      await repo.updateClientStatus(
        client.id,
        selectedStatus,
        userId: '',
        userName: 'Admin',
      );
      ref.read(paginatedClientsProvider.notifier).refresh();
    }
  }

  Future<void> _toggleArchive(ClientModel client) async {
    final repo = ref.read(clientRepositoryProvider);
    final bus = ref.read(appEventBusProvider);
    if (client.isArchived) {
      await repo.restoreClient(client.id, userId: '', userName: 'Admin');
      bus.emit(ClientRestoredEvent(client.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client restored')),
        );
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Archive Client'),
          content: Text(
            'Are you sure you want to archive "${client.companyName}"? All history will be preserved.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Archive'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await repo.archiveClient(client.id, userId: '', userName: 'Admin');
        bus.emit(ClientArchivedEvent(client.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client moved to archive')),
          );
        }
      }
    }
  }

  Future<void> _handleAddNote(String clientId) async {
    final noteText = _newNoteController.text.trim();
    if (noteText.isEmpty) return;

    setState(() => _isAddingNote = true);
    try {
      final repo = ref.read(clientRepositoryProvider);
      await repo.addClientNote(
        clientId,
        note: noteText,
        userId: '',
        userName: 'Admin',
      );
      _newNoteController.clear();
    } finally {
      if (mounted) setState(() => _isAddingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: ErrorState(message: 'Failed to load client: $err'),
        ),
        data: (client) {
          if (client == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.business_outlined,
                title: 'Client Not Found',
                subtitle: 'The client document does not exist or has been deleted.',
              ),
            );
          }

          final hasFollowUp = client.nextFollowUpAt != null;
          final isOverdue = hasFollowUp && client.nextFollowUpAt!.isBefore(DateTime.now());

          return CustomScrollView(
            slivers: [
              // Top Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumbs (Web only)
                      if (!PlatformCapabilities.isAndroid) ...[
                        Breadcrumbs(
                          items: [
                            const BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                            const BreadcrumbItem(label: 'Clients', route: AppRoutes.clients),
                            BreadcrumbItem(label: client.companyName),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Source Lead Banner
                      if (client.sourceLeadId != null && client.sourceLeadId!.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Converted from Lead: ${client.companyName}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  context.push('${AppRoutes.leads}/${client.sourceLeadId}');
                                },
                                icon: const Icon(Icons.arrow_outward_rounded, size: 14),
                                label: const Text('View Original Lead'),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Profile Header Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppAvatar(name: client.companyName, size: 56),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              client.companyName,
                                              style: AppTypography.headlineSmall.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: client.status.backgroundColor,
                                              borderRadius: BorderRadius.circular(AppRadius.xs),
                                            ),
                                            child: Text(
                                              client.status.displayName,
                                              style: AppTypography.caption.copyWith(
                                                color: client.status.color,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: client.priority.backgroundColor,
                                              borderRadius: BorderRadius.circular(AppRadius.xs),
                                            ),
                                            child: Text(
                                              client.priority.displayName,
                                              style: AppTypography.caption.copyWith(
                                                color: client.priority.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        client.contactPerson.isNotEmpty
                                            ? '${client.contactPerson} • Assigned to ${client.assignedToName.isNotEmpty ? client.assignedToName : "Unassigned"}'
                                            : 'Assigned to ${client.assignedToName.isNotEmpty ? client.assignedToName : "Unassigned"}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.md),

                            // Action Buttons Row
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (client.phone.isNotEmpty) ...[
                                  OutlinedButton.icon(
                                    onPressed: () => _launchCall(client.phone),
                                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.success),
                                    label: const Text('Call'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _launchWhatsApp(client.phone),
                                    icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF25D366)),
                                    label: const Text('WhatsApp'),
                                  ),
                                ],
                                if (client.email.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: () => _launchEmail(client.email),
                                    icon: const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.info),
                                    label: const Text('Email'),
                                  ),
                                FilledButton.icon(
                                  onPressed: () {
                                    context.push('${AppRoutes.followups}/create?clientId=${client.id}&clientName=${Uri.encodeComponent(client.companyName)}');
                                  },
                                  icon: const Icon(Icons.add_alert_rounded, size: 16),
                                  label: const Text('Schedule Follow-up'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => context.push('${AppRoutes.clients}/${client.id}/edit'),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                ),
                                PopupMenuButton<String>(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('More', style: AppTypography.labelMedium),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_drop_down_rounded, size: 18),
                                      ],
                                    ),
                                  ),
                                  onSelected: (action) {
                                    if (action == 'status') {
                                      _changeStatus(client);
                                    } else if (action == 'archive') {
                                      _toggleArchive(client);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'status',
                                      child: Row(
                                        children: [
                                          Icon(Icons.swap_horiz_rounded, size: 16),
                                          SizedBox(width: 8),
                                          Text('Change Status'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(
                                            client.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                            size: 16,
                                            color: client.isArchived ? AppColors.success : AppColors.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            client.isArchived ? 'Restore Client' : 'Archive Client',
                                            style: TextStyle(
                                              color: client.isArchived ? AppColors.success : AppColors.error,
                                            ),
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

                      // KPI Metrics Row
                      _buildSummaryCards(context, client, hasFollowUp, isOverdue, isDark),
                      const SizedBox(height: AppSpacing.lg),

                      // Tabs Bar
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Activities'),
                          Tab(text: 'Follow-ups'),
                          Tab(text: 'Quotations'),
                          Tab(text: 'Projects'),
                          Tab(text: 'Notes'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Views
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 600,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(client, isDark),
                        _buildActivitiesTab(client.id, isDark),
                        _buildFollowUpsTab(client, isDark),
                        _buildQuotationsTab(client, isDark),
                        _buildProjectsTab(client, isDark),
                        _buildNotesTab(client.id, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    ClientModel client,
    bool hasFollowUp,
    bool isOverdue,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        final items = [
          _SummaryMetric(
            title: 'Client Since',
            value: DateFormat('MMM d, yyyy').format(client.clientSince),
            icon: Icons.calendar_today_rounded,
            color: AppColors.primary,
          ),
          _SummaryMetric(
            title: 'Next Follow-up',
            value: hasFollowUp ? TimezoneHelper.formatIST(client.nextFollowUpAt!) : 'None',
            icon: Icons.alarm_rounded,
            color: isOverdue ? AppColors.error : AppColors.info,
          ),
          _SummaryMetric(
            title: 'Total Quotations',
            value: currencyFmt.format(client.totalQuotationValue),
            icon: Icons.receipt_long_rounded,
            color: AppColors.secondary,
          ),
          _SummaryMetric(
            title: 'Business Value',
            value: currencyFmt.format(client.totalProjectValue),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
        ];

        if (isMobile) {
          return SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (ctx, idx) => SizedBox(width: 170, child: _buildMetricTile(items[idx], isDark)),
            ),
          );
        }

        return Row(
          children: items.map((it) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _buildMetricTile(it, isDark),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricTile(_SummaryMetric item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 14, color: item.color),
              const SizedBox(width: 6),
              Text(
                item.title,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab(ClientModel client, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Contact Information',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
                rows: [
                  _InfoPair('Contact Person', client.contactPerson),
                  _InfoPair('Phone', client.phone),
                  _InfoPair('Alternate Phone', client.alternatePhone),
                  _InfoPair('Email', client.email),
                  _InfoPair('Website', client.website),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildInfoCard(
                title: 'Business Classification',
                icon: Icons.business_center_outlined,
                isDark: isDark,
                rows: [
                  _InfoPair('Industry', client.industry),
                  _InfoPair('Client Type', client.clientType.displayName),
                  _InfoPair('Status', client.status.displayName),
                  _InfoPair('Priority', client.priority.displayName),
                  _InfoPair('Assigned Staff', client.assignedToName),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoCard(
          title: 'Address & Billing Location',
          icon: Icons.place_outlined,
          isDark: isDark,
          rows: [
            _InfoPair('Street Address', client.address),
            _InfoPair('City', client.city),
            _InfoPair('State', client.state),
            _InfoPair('Country', client.country),
            _InfoPair('Pincode', client.pincode),
          ],
        ),
        if (client.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildInfoCard(
            title: 'Account Notes',
            icon: Icons.notes_rounded,
            isDark: isDark,
            rows: [
              _InfoPair('Notes', client.notes),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<_InfoPair> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        r.label,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value.isNotEmpty ? r.value : '—',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // 2. Activities Tab
  Widget _buildActivitiesTab(String clientId, bool isDark) {
    final activitiesAsync = ref.watch(clientActivitiesProvider(clientId));

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load activities: $e')),
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.history_rounded,
              title: 'No activities yet',
              subtitle: 'Client activities and status changes will be logged here.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final act = activities[index];
            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
              ),
              title: Text(act.title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (act.description.isNotEmpty) Text(act.description, style: AppTypography.bodySmall),
                  Text(
                    '${act.createdByName.isNotEmpty ? act.createdByName : "Admin"} • ${DateFormat("MMM d, yyyy h:mm a").format(act.createdAt)}',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
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

  // 3. Follow-ups Tab
  Widget _buildFollowUpsTab(ClientModel client, bool isDark) {
    final followupsAsync = ref.watch(clientFollowUpsProvider((client.id, client.sourceLeadId)));

    return followupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load follow-ups: $e')),
      data: (followups) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    '${followups.length} Follow-ups',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('${AppRoutes.followups}/create?clientId=${client.id}&clientName=${Uri.encodeComponent(client.companyName)}');
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Schedule Follow-up'),
                  ),
                ],
              ),
            ),
            if (followups.isEmpty)
              const Expanded(
                child: Center(
                  child: EmptyState(
                    icon: Icons.alarm_rounded,
                    title: 'No follow-ups scheduled',
                    subtitle: 'Schedule upcoming meetings, calls, or reviews with this client.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: followups.length,
                  itemBuilder: (context, index) {
                    return FollowUpCardItem(followup: followups[index]);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // 4. Quotations Tab
  Widget _buildQuotationsTab(ClientModel client, bool isDark) {
    final quotationsAsync = ref.watch(clientQuotationsProvider(client.id));

    return quotationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load quotations: $e')),
      data: (quotations) {
        final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
        final dateFmt = DateFormat('MMM d, yyyy');

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    '${quotations.length} Quotation${quotations.length == 1 ? '' : 's'}',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('${AppRoutes.quotations}/new?clientId=${client.id}');
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create Quotation'),
                  ),
                ],
              ),
            ),
            if (quotations.isEmpty)
              Expanded(
                child: Center(
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No quotations created yet',
                    subtitle: 'Create formal sales proposals, estimates, and quotations for ${client.companyName}.',
                    actionLabel: 'Create Quotation',
                    onAction: () {
                      context.push('${AppRoutes.quotations}/new?clientId=${client.id}');
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: quotations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final q = quotations[index];
                    final effStatus = q.effectiveStatus;

                    return InkWell(
                      onTap: () => context.push('${AppRoutes.quotations}/${q.id}'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: effStatus.backgroundColor,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(effStatus.icon, color: effStatus.color, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        q.quotationNumber,
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: effStatus.backgroundColor,
                                          borderRadius: BorderRadius.circular(AppRadius.xs),
                                        ),
                                        child: Text(
                                          effStatus.displayName,
                                          style: AppTypography.caption.copyWith(
                                            color: effStatus.color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (q.convertedToProject) ...[
                                        const SizedBox(width: AppSpacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(AppRadius.xs),
                                          ),
                                          child: Text(
                                            'Project Created',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    q.title.isNotEmpty ? q.title : 'No title',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Valid until: ${dateFmt.format(q.expiryDate)}',
                                    style: AppTypography.caption.copyWith(
                                      color: q.isExpired ? AppColors.error : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                                      fontWeight: q.isExpired ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFmt.format(q.grandTotal),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${q.items.length} item${q.items.length == 1 ? '' : 's'}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
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

  // 5. Projects Tab
  Widget _buildProjectsTab(ClientModel client, bool isDark) {
    final projectsAsync = ref.watch(clientProjectsProvider(client.id));

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load projects: $e')),
      data: (projects) {
        final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
        final dateFmt = DateFormat('MMM d, yyyy');

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    '${projects.length} Project${projects.length == 1 ? '' : 's'}',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('${AppRoutes.projects}/new?clientId=${client.id}');
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create Project'),
                  ),
                ],
              ),
            ),
            if (projects.isEmpty)
              Expanded(
                child: Center(
                  child: EmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'No projects created yet',
                    subtitle: 'Create deliverables, track milestones and project progress for ${client.companyName}.',
                    actionLabel: 'Create Project',
                    onAction: () {
                      context.push('${AppRoutes.projects}/new?clientId=${client.id}');
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: projects.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final p = projects[index];

                    return InkWell(
                      onTap: () => context.push('${AppRoutes.projects}/${p.id}'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: p.status.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(p.status.icon, color: p.status.color, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        p.projectNumber,
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      ProjectStatusBadge(status: p.status),
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.priority.containerColor,
                                          borderRadius: BorderRadius.circular(AppRadius.xs),
                                        ),
                                        child: Text(
                                          p.priority.displayName,
                                          style: AppTypography.caption.copyWith(
                                            color: p.priority.color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.title,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.progress}% completed • Due: ${p.expectedEndDate != null ? dateFmt.format(p.expectedEndDate!) : "No deadline"}',
                                    style: AppTypography.caption.copyWith(
                                      color: p.isOverdue ? AppColors.error : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                                      fontWeight: p.isOverdue ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFmt.format(p.budget > 0 ? p.budget : p.quotationValue),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.projectType.displayName,
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
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


  // 6. Notes Tab
  Widget _buildNotesTab(String clientId, bool isDark) {
    final notesAsync = ref.watch(clientNotesProvider(clientId));

    return Column(
      children: [
        // Composer
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _newNoteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add an internal note about this client...',
                  border: InputBorder.none,
                ),
              ),
              FilledButton.icon(
                onPressed: _isAddingNote ? null : () => _handleAddNote(clientId),
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Post Note'),
              ),
            ],
          ),
        ),

        // Notes List
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load notes: $e')),
            data: (notes) {
              if (notes.isEmpty) {
                return const Center(
                  child: EmptyState(
                    icon: Icons.note_alt_outlined,
                    title: 'No notes yet',
                    subtitle: 'Add internal comments, call logs, or meeting summaries.',
                  ),
                );
              }

              return ListView.separated(
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final n = notes[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              n.createdByName.isNotEmpty ? n.createdByName : 'Admin',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy • h:mm a').format(n.createdAt),
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                              onPressed: () async {
                                final repo = ref.read(clientRepositoryProvider);
                                await repo.deleteClientNote(clientId, n.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(n.note, style: AppTypography.bodyMedium),
                      ],
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
}

class _SummaryMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _InfoPair {
  final String label;
  final String value;
  const _InfoPair(this.label, this.value);
}
