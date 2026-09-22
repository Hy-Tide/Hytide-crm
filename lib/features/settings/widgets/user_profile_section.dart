// lib/features/settings/widgets/user_profile_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';

class UserProfileSection extends ConsumerWidget {
  final UserModel user;

  const UserProfileSection({super.key, required this.user});

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(user.email);
      if (context.mounted) {
        AppToast.success(context, 'Password reset link sent to ${user.email}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to send password reset: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
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
                child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Account & Credentials', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      'Your personal authentication details and access permissions',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(name: user.displayName, photoUrl: user.photoURL, size: 72),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.displayName,
                          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        RoleBadge(role: user.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${user.createdAt.formattedDate}',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Security & Password Reset Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Password & Login Security', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    'Send a secure password reset email to update your login credentials',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _sendPasswordReset(context, ref),
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: const Text('Reset Password'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
