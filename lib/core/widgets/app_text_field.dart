// lib/core/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Premium, modern text field for Hytide CRM.
/// Features: label above, clear button, password toggle, helper/error text,
/// character counter, animated focus ring, read-only mode.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool showClearButton;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? Function(String?)? onSaved;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.showClearButton = false,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onSaved,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _currentValue = widget.controller?.text ?? widget.initialValue ?? '';

    widget.controller?.addListener(() {
      if (mounted) setState(() => _currentValue = widget.controller!.text);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  Widget? _buildSuffixIcon() {
    // Password toggle takes priority
    if (widget.showPasswordToggle || widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 18,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }

    // User-provided suffix
    if (widget.suffixIcon != null) return widget.suffixIcon;

    // Clear button
    if (widget.showClearButton && _currentValue.isNotEmpty && widget.enabled && !widget.readOnly) {
      return IconButton(
        icon: const Icon(Icons.close_rounded, size: 16),
        onPressed: () {
          widget.controller?.clear();
          setState(() => _currentValue = '');
          widget.onChanged?.call('');
        },
        tooltip: 'Clear',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: widget.enabled
                  ? (isDark ? AppColors.onSurfaceDark : AppColors.onSurface)
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Field
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: (val) {
            setState(() => _currentValue = val);
            widget.onChanged?.call(val);
          },
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
          maxLines: (_obscureText || (widget.showPasswordToggle && _obscureText)) ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          focusNode: _focusNode,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            counterText: widget.maxLength != null ? null : '',
            // Fill color adapts to state
            fillColor: !widget.enabled
                ? (isDark
                    ? AppColors.surfaceBorderDark.withValues(alpha: 0.3)
                    : AppColors.surfaceBorderSubtle)
                : widget.readOnly
                    ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
                    : null, // falls back to theme
          ),
        ),

        // Helper text (shown when no error — Flutter handles this in InputDecoration)
      ],
    );
  }
}
