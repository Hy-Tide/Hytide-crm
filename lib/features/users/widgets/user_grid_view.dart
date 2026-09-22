// lib/features/users/widgets/user_grid_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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

class UserGridView extends ConsumerWidget {
  final List<UserModel> users;

  const UserGridView({super.key, required this.users});

  Future<void> _changeRole(BuildContext context, WidgetRef ref, UserModel user, UserRole newRole) async {
    if (user.isSuperAdmin) {
      AppToast.error(context, 'Primary Administrator role cannot be modified.');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).updateUserRole(user.uid, newRole);
      if (context.mounted) {
        AppToast.success(context, 'Role updated to ${newRole.displayName} for ${user.displayName}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to update role: $e');
      }
    }
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, UserModel user) async {
    if (user.isSuperAdmin) {
      AppToast.error(context, 'Primary Administrator account cannot be deactivated or deleted.');
      return;
    }
    final willActivate = !user.isActive;
    final confirmed = await ConfirmDialog.show(
      context,
      title: willActivate ? 'Activate Account' : 'Deactivate Account',
      message: willActivate
          ? 'Enable login access for ${user.displayName}?'
          : 'Are you sure you want to deactivate ${user.displayName}? They will lose access to HyTide CRM.',
      confirmLabel: willActivate ? 'Activate' : 'Deactivate',
      isDestructive: !willActivate,
    );

    if (confirmed == true) {
      try {
        await ref.read(authRepositoryProvider).toggleUserStatus(user.uid, willActivate);
        if (context.mounted) {
          AppToast.success(context, 'Account ${willActivate ? "activated" : "deactivated"}');
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Failed to update status: $e');
        }
      }
    }
  }

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref, UserModel user) async {
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(user.email);
      if (context.mounted) {
        AppToast.info(context, 'Password reset email sent to ${user.email}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to send reset email: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 850) {
          crossAxisCount = 3;
        } else if (width >= 550) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(context, ref, user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserRole = ref.watch(currentUserRoleProvider);
    final isAdmin = currentUserRole == UserRole.admin;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar + Name + Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(name: user.displayName, photoUrl: user.photoURL, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                padding: EdgeInsets.zero,
                tooltip: 'Member options',
                onSelected: (action) {
                  if (action.startsWith('role:')) {
                    final roleStr = action.replaceFirst('role:', '');
                    final newRole = UserRole.fromString(roleStr);
                    _changeRole(context, ref, user, newRole);
                  } else if (action == 'toggle_status') {
                    _toggleStatus(context, ref, user);
                  } else if (action == 'reset_password') {
                    _sendPasswordReset(context, ref, user);
                  }
                },
                itemBuilder: (context) => [
                  if (isAdmin && !user.isSuperAdmin) ...[
                    PopupMenuItem(
                      enabled: false,
                      child: Text('Change Role', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ...UserRole.values.map((role) {
                      return PopupMenuItem(
                        value: 'role:${role.name}',
                        child: Row(
                          children: [
                            Icon(
                              user.role == role ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: user.role == role ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(role.displayName),
                          ],
                        ),
                      );
                    }),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: user.isActive ? AppColors.error : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isActive ? 'Deactivate Account' : 'Activate Account'),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Send Password Reset'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Middle row: Role Badge + Super Admin Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoleBadge(role: user.role),
              if (user.isSuperAdmin) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 11, color: Color(0xFF6D28D9)),
                      SizedBox(width: 3),
                      Text(
                        'Primary',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom row: Status badge + Joined date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: user.isActive ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: user.isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Joined ${user.createdAt.formattedDate}',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
