// lib/features/users/widgets/user_table_view.dart
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

class UserTableView extends ConsumerWidget {
  final List<UserModel> users;

  const UserTableView({super.key, required this.users});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserRole = ref.watch(currentUserRoleProvider);
    final isAdmin = currentUserRole == UserRole.admin;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: AppSpacing.lg,
              columnSpacing: AppSpacing.xl,
              columns: const [
                DataColumn(label: Text('TEAM MEMBER', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('EMAIL ADDRESS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('JOINED DATE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              ],
              rows: users.map((user) {
                return DataRow(
                  cells: [
                    // Member Avatar + Name
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAvatar(name: user.displayName, photoUrl: user.photoURL, size: 36),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            user.displayName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Email Address
                    DataCell(
                      Text(
                        user.email,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Role Badge
                    DataCell(
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
                    ),

                    // Status Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: user.isActive
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: user.isActive ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: user.isActive ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Joined Date
                    DataCell(
                      Text(
                        user.createdAt.formattedDate,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Actions
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
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
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
