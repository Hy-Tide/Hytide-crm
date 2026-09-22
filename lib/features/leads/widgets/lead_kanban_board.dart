import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_badge.dart';
import '../models/lead_model.dart';
import '../providers/lead_providers.dart';
import '../repositories/lead_repository.dart';
import 'lead_status_dialog.dart';

class LeadKanbanBoard extends ConsumerWidget {
  const LeadKanbanBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(kanbanLeadsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return leadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Error loading kanban board: $e'),
        ),
      ),
      data: (leads) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: LeadStatus.values.map((status) {
              final columnLeads = leads.where((l) => l.status == status).toList();
              final totalValue = columnLeads.fold<double>(0, (sum, l) => sum + l.estimatedValue);

              return _KanbanColumn(
                key: ValueKey(status),
                status: status,
                leads: columnLeads,
                totalValue: totalValue,
                isDark: isDark,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final LeadStatus status;
  final List<LeadModel> leads;
  final double totalValue;
  final bool isDark;

  const _KanbanColumn({
    super.key,
    required this.status,
    required this.leads,
    required this.totalValue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0);
    final valueText = totalValue > 0 ? currencyFmt.format(totalValue) : '';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    status.label,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${leads.length}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (valueText.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    valueText,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Droppable list
          DragTarget<LeadModel>(
            onWillAcceptWithDetails: (details) => details.data.status != status,
            onAcceptWithDetails: (details) => _handleDrop(context, ref, details.data, status),
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;

              return Container(
                constraints: const BoxConstraints(minHeight: 120, maxHeight: 650),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppColors.primaryBlue.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: leads.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Text(
                            'No leads',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: leads.length,
                        itemBuilder: (context, index) {
                          final lead = leads[index];
                          return _KanbanCard(lead: lead, isDark: isDark);
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleDrop(BuildContext context, WidgetRef ref, LeadModel lead, LeadStatus targetStatus) async {
    if (targetStatus == LeadStatus.lost) {
      final res = await LeadStatusDialog.showForLead(context, lead);
      if (res != null) {
        final repo = ref.read(leadRepositoryProvider);
        await repo.updateLeadStatus(
          lead.id,
          res.status,
          lostReason: res.lostReason,
          userName: 'Admin',
        );
      }
      return;
    }

    try {
      final repo = ref.read(leadRepositoryProvider);
      await repo.updateLeadStatus(
        lead.id,
        targetStatus,
        userName: 'Admin',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return AppColors.statusNew;
      case LeadStatus.contacted:
        return AppColors.statusContacted;
      case LeadStatus.followUp:
        return AppColors.statusFollowUp;
      case LeadStatus.meetingScheduled:
        return AppColors.statusMeeting;
      case LeadStatus.proposalSent:
        return AppColors.statusProposal;
      case LeadStatus.negotiation:
        return AppColors.statusNegotiation;
      case LeadStatus.won:
        return AppColors.statusWon;
      case LeadStatus.lost:
        return AppColors.statusLost;
    }
  }
}

class _KanbanCard extends StatelessWidget {
  final LeadModel lead;
  final bool isDark;

  const _KanbanCard({required this.lead, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      symbol: lead.currency.toUpperCase() == 'INR' ? '₹' : '\$',
      decimalDigits: 0,
    );
    final valueText = currencyFmt.format(lead.estimatedValue);

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.companyName.isNotEmpty ? lead.companyName : lead.contactPerson,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PriorityBadge(priority: lead.priority),
            ],
          ),
          if (lead.companyName.isNotEmpty && lead.contactPerson.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              lead.contactPerson,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (lead.estimatedValue > 0)
                Text(
                  valueText,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (lead.assignedToName.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(name: lead.assignedToName, size: 18),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        lead.assignedToName,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return LongPressDraggable<LeadModel>(
      data: lead,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 260,
          child: Opacity(opacity: 0.9, child: cardContent),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      child: InkWell(
        onTap: () => context.go('${AppRoutes.leads}/${lead.id}'),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: cardContent,
      ),
    );
  }
}
