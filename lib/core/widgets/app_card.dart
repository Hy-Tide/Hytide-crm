// lib/core/widgets/app_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Premium card widget with hover elevation, theme-aware surface, and
/// interactive tap states.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.shadows,
    this.width,
    this.height,
    this.borderRadius = AppRadius.r12,
    this.elevated = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        widget.color ?? (isDark ? AppColors.surfaceDark : AppColors.surface);
    final borderColor =
        widget.borderColor ??
        (isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder);

    List<BoxShadow> shadows;
    if (widget.shadows != null) {
      shadows = widget.shadows!;
    } else if (widget.elevated || (widget.onTap != null && _isHovered)) {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      shadows = const [];
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? AppSpacing.cardPadding,
      transform: widget.onTap != null && _isHovered
          ? (Matrix4.identity()..translate(0.0, -1.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(onTap: widget.onTap, child: content),
      );
    }

    return content;
  }
}
