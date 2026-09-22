// lib/core/platform/widgets/android_notification_permission_dialog.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../platform_capabilities.dart';

class AndroidNotificationPermissionHelper {
  static const String _permissionPromptedKey = 'hytide_notif_prompted';

  /// Shows an in-app educational modal explaining why notifications are helpful,
  /// then requests the Android system permission.
  static Future<void> checkAndPromptPermission(BuildContext context) async {
    if (!PlatformCapabilities.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool(_permissionPromptedKey) ?? false;
      if (hasPrompted) return;

      if (!context.mounted) return;

      final shouldRequest = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => const _NotificationPrimerSheet(),
      );

      await prefs.setBool(_permissionPromptedKey, true);

      if (shouldRequest == true) {
        await NotificationService().requestAndroidNotificationPermission();
      }
    } catch (_) {}
  }
}

class _NotificationPrimerSheet extends StatelessWidget {
  const _NotificationPrimerSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Stay on top of your deals',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Get instant alerts for today\'s follow-ups, urgent reminders, and project milestone updates right on your device.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Enable Alerts'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
