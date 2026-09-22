// lib/core/widgets/app_dialogs.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Modern confirmation dialog with proper spacing and destructive variant.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIcon = icon ?? (isDestructive ? Icons.warning_amber_rounded : null);

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title
              Row(
                children: [
                  if (effectiveIcon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDestructive
                            ? AppColors.errorContainer
                            : AppColors.infoContainer,
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                      ),
                      child: Icon(
                        effectiveIcon,
                        size: 18,
                        color: isDestructive ? AppColors.error : AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),

              // Message
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                    ),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  if (isDestructive)
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r8),
                        ),
                      ),
                      child: Text(confirmLabel),
                    )
                  else
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r8),
                        ),
                      ),
                      child: Text(confirmLabel),
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

/// Premium toast/snackbar system with success, error, warning variants.
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color backgroundColor;
    Color foregroundColor = Colors.white;
    IconData icon;

    if (isError) {
      backgroundColor = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else if (isSuccess) {
      backgroundColor = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (isWarning) {
      backgroundColor = AppColors.warning;
      icon = Icons.warning_amber_rounded;
    } else {
      backgroundColor = AppColors.onSurface;
      icon = Icons.info_outline_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
      ),
    );
  }

  static void success(BuildContext context, String message, {SnackBarAction? action}) =>
      show(context, message: message, isSuccess: true, action: action);

  static void error(BuildContext context, String message, {SnackBarAction? action}) =>
      show(context, message: message, isError: true, action: action);

  static void warning(BuildContext context, String message, {SnackBarAction? action}) =>
      show(context, message: message, isWarning: true, action: action);

  static void info(BuildContext context, String message, {SnackBarAction? action}) =>
      show(context, message: message, action: action);
}

/// Loading dialog for async operations.
class LoadingDialog {
  static Future<T?> run<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String? message,
  }) async {
    bool isDialogShowing = false;
    T? result;

    final future = action().then((value) {
      result = value;
      if (isDialogShowing && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      return value;
    }).catchError((e) {
      if (isDialogShowing && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      throw e;
    });

    isDialogShowing = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Text(
                message ?? 'Please wait...',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await future;
    isDialogShowing = false;
    return result;
  }
}
