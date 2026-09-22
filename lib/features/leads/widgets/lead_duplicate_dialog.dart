// lib/features/leads/widgets/lead_duplicate_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../models/lead_model.dart';

class LeadDuplicateDialog extends StatelessWidget {
  final LeadModel existingLead;

  const LeadDuplicateDialog({
    super.key,
    required this.existingLead,
  });

  static Future<bool> show(
    BuildContext context, [
    LeadModel? existingLeadPositional,
  ]) async {
    final lead = existingLeadPositional;
    if (lead == null) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => LeadDuplicateDialog(existingLead: lead),
    );
    return result ?? false;
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
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Text(
                      'Possible Duplicate Lead',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              Text(
                'An existing active lead matching this company, phone number, or email address already exists in your CRM.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapH16,

              // Matching lead card
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingLead.companyName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contact: ${existingLead.contactPerson}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (existingLead.phone.isNotEmpty)
                      Text(
                        'Phone: ${existingLead.phone}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (existingLead.email.isNotEmpty)
                      Text(
                        'Email: ${existingLead.email}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${existingLead.status.displayName} • Assigned: ${existingLead.assignedToName.isNotEmpty ? existingLead.assignedToName : "Unassigned"}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  AppSpacing.gapW12,
                  PrimaryButton(
                    label: 'Create Anyway',
                    onPressed: () => Navigator.of(context).pop(true),
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
