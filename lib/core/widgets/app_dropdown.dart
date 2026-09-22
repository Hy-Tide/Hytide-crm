// lib/core/widgets/app_dropdown.dart
import 'package:flutter/material.dart';
import '../platform/platform_capabilities.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Modern dropdown component consistent with AppTextField's label-above pattern.
/// On Android, opens a touch-friendly bottom sheet picker.
/// On Web, uses DropdownButtonFormField for native browser experience.
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final bool enabled;
  final String? helperText;
  final String? errorText;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
    this.helperText,
    this.errorText,
  });

  void _openMobileBottomSheet(BuildContext context) async {
    if (!enabled || onChanged == null) return;

    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DropdownBottomSheet<T>(
        title: label ?? hint ?? 'Select Option',
        items: items,
        currentValue: value,
      ),
    );

    if (selected != null) {
      onChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Web keeps DropdownButtonFormField baseline
    if (!PlatformCapabilities.isAndroid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTypography.labelMedium.copyWith(
                color: enabled
                    ? (isDark ? AppColors.onSurfaceDark : AppColors.onSurface)
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            validator: validator,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            ),
            icon: Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            menuMaxHeight: 320,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              helperText: helperText,
              prefixIcon: prefixIcon,
              fillColor: !enabled
                  ? (isDark
                      ? AppColors.surfaceBorderDark.withValues(alpha: 0.3)
                      : AppColors.surfaceBorderSubtle)
                  : null,
            ),
            isExpanded: true,
          ),
        ],
      );
    }

    // Dedicated Android Mobile Experience: Bottom Sheet Picker
    DropdownMenuItem<T>? currentItem;
    for (final it in items) {
      if (it.value == value) {
        currentItem = it;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: enabled
                  ? (isDark ? AppColors.onSurfaceDark : AppColors.onSurface)
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        FormField<T>(
          initialValue: value,
          validator: validator,
          builder: (state) {
            final hasError = state.hasError;
            return InkWell(
              onTap: enabled ? () => _openMobileBottomSheet(context) : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: hint,
                  errorText: hasError ? state.errorText : errorText,
                  helperText: helperText,
                  prefixIcon: prefixIcon,
                  suffixIcon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: !enabled
                      ? (isDark
                          ? AppColors.surfaceBorderDark.withValues(alpha: 0.3)
                          : AppColors.surfaceBorderSubtle)
                      : (isDark ? AppColors.surfaceDark : AppColors.surface),
                ),
                child: currentItem != null
                    ? currentItem.child
                    : Text(
                        hint ?? 'Select',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DropdownBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<DropdownMenuItem<T>> items;
  final T? currentValue;

  const _DropdownBottomSheet({
    required this.title,
    required this.items,
    this.currentValue,
  });

  @override
  State<_DropdownBottomSheet<T>> createState() => _DropdownBottomSheetState<T>();
}

class _DropdownBottomSheetState<T> extends State<_DropdownBottomSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showSearch = widget.items.length > 7;

    final filteredItems = widget.items.where((it) {
      if (_search.isEmpty) return true;
      if (it.child is Text) {
        final text = (it.child as Text).data ?? '';
        return text.toLowerCase().contains(_search.toLowerCase());
      }
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search options...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final isSelected = item.value == widget.currentValue;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    title: item.child,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () => Navigator.of(context).pop(item.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
