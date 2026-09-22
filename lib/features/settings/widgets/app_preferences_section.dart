// lib/features/settings/widgets/app_preferences_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/repositories/auth_repository.dart';

class AppPreferencesSection extends ConsumerStatefulWidget {
  const AppPreferencesSection({super.key});

  @override
  ConsumerState<AppPreferencesSection> createState() => _AppPreferencesSectionState();
}

class _AppPreferencesSectionState extends ConsumerState<AppPreferencesSection> {
  bool _emailAlerts = true;
  bool _followupReminders = true;
  bool _quotationStatusUpdates = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme & Display
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.palette_outlined, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme & Interface', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          'Customize the visual presentation of HyTide CRM',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isDark ? 'Dark theme active (reduced eye strain in low-light environments)' : 'Light theme active',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  ),
                ),
                value: isDark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Notifications Preferences
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: AppColors.info, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications & Alerts', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          'Choose which notifications and system reminders you receive',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Follow-up Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Receive alerts when lead follow-ups or meetings are due', style: AppTypography.caption),
                value: _followupReminders,
                onChanged: (val) => setState(() => _followupReminders = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lead Assignment Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Notify me when a new deal or client is assigned to my account', style: AppTypography.caption),
                value: _emailAlerts,
                onChanged: (val) => setState(() => _emailAlerts = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Quotation Status Updates', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Get notified when quotations are accepted, rejected, or expired', style: AppTypography.caption),
                value: _quotationStatusUpdates,
                onChanged: (val) => setState(() => _quotationStatusUpdates = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // System & About
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About HyTide CRM', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text('System architecture and session controls', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Application Version', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text('v1.0.0+1 (Production)', style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cloud Backend', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text('Firebase Cloud Firestore · Firebase Auth', style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.lg),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Sign Out',
                      message: 'Are you sure you want to end your session and sign out of HyTide CRM?',
                      confirmLabel: 'Sign Out',
                      isDestructive: true,
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  label: const Text('Sign Out of Account', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
