// lib/features/leads/widgets/lead_status_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../models/lead_model.dart';

class LeadStatusDialogResult {
  final LeadStatus status;
  final String? lostReason;

  const LeadStatusDialogResult({required this.status, this.lostReason});
}

class LeadStatusDialog extends StatefulWidget {
  final LeadStatus currentStatus;
  final String companyName;

  const LeadStatusDialog({
    super.key,
    required this.currentStatus,
    required this.companyName,
  });

  static Future<LeadStatusDialogResult?> show(
    BuildContext context, {
    required LeadStatus currentStatus,
    required String companyName,
  }) {
    return showDialog<LeadStatusDialogResult>(
      context: context,
      builder: (context) => LeadStatusDialog(
        currentStatus: currentStatus,
        companyName: companyName,
      ),
    );
  }

  static Future<LeadStatusDialogResult?> showForLead(
    BuildContext context,
    LeadModel lead,
  ) {
    return show(
      context,
      currentStatus: lead.status,
      companyName: lead.companyName.isNotEmpty ? lead.companyName : (lead.contactPerson.isNotEmpty ? lead.contactPerson : 'No name provided'),
    );
  }

  @override
  State<LeadStatusDialog> createState() => _LeadStatusDialogState();
}

class _LeadStatusDialogState extends State<LeadStatusDialog> {
  late LeadStatus _selectedStatus;
  String _lostReason = 'Budget';

  static const List<String> _lostReasons = [
    'Budget',
    'Competitor',
    'Not Interested',
    'No Response',
    'Project Cancelled',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Lead Status',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.companyName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH20,

              // Status Radios / Grid
              Text(
                'Select Stage',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
              AppSpacing.gapH8,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LeadStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    selectedColor: status.color.withValues(alpha: 0.15),
                    backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    side: BorderSide(
                      color: isSelected ? status.color : AppColors.surfaceBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? status.color : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    avatar: Icon(status.icon, size: 14, color: isSelected ? status.color : AppColors.onSurfaceVariant),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = status);
                      }
                    },
                  );
                }).toList(),
              ),

              // Lost Reason requirement when status == Lost
              if (_selectedStatus == LeadStatus.lost) ...[
                AppSpacing.gapH20,
                Text(
                  'Lost Reason *',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapH8,
                DropdownButtonFormField<String>(
                  initialValue: _lostReason,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _lostReasons.map((reason) {
                    return DropdownMenuItem(value: reason, child: Text(reason));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _lostReason = val);
                  },
                ),
              ],

              AppSpacing.gapH24,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppSpacing.gapW12,
                  PrimaryButton(
                    label: 'Update Status',
                    onPressed: () {
                      Navigator.of(context).pop(
                        LeadStatusDialogResult(
                          status: _selectedStatus,
                          lostReason: _selectedStatus == LeadStatus.lost ? _lostReason : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
