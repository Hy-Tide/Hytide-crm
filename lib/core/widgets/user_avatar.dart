// lib/core/widgets/user_avatar.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final double size;
  final bool showStatus;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.name,
    String? photoUrl,
    String? photoURL,
    this.size = 36,
    this.showStatus = false,
    this.isOnline = true,
  }) : photoUrl = photoUrl ?? photoURL;

  String get _initials {
    if (name == null || name!.trim().isEmpty) return 'U';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(),
        ),
      );
    } else {
      avatar = _buildInitials();
    }

    if (!showStatus) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.onSurfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.onPrimaryContainer,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
