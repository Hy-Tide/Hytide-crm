// lib/core/widgets/app_searchable_dropdown.dart
import 'package:flutter/material.dart';
import '../platform/platform_capabilities.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A modern searchable dropdown form field with prefilled options, live search,
/// quick-select chips, and custom value entry support.
class AppSearchableDropdown extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController controller;
  final List<String> items;
  final List<String>? popularItems;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool allowCustom;
  final String modalTitle;

  const AppSearchableDropdown({
    super.key,
    this.label,
    this.hintText,
    required this.controller,
    required this.items,
    this.popularItems,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.allowCustom = true,
    this.modalTitle = 'Select Option',
  });

  @override
  State<AppSearchableDropdown> createState() => _AppSearchableDropdownState();
}

class _AppSearchableDropdownState extends State<AppSearchableDropdown> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _openSelectionDialog() async {
    if (!widget.enabled) return;

    final String? selected;
    if (PlatformCapabilities.isAndroid) {
      selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _SearchableSelectionBottomSheet(
          title: widget.modalTitle,
          items: widget.items,
          popularItems: widget.popularItems,
          currentValue: widget.controller.text.trim(),
          allowCustom: widget.allowCustom,
        ),
      );
    } else {
      selected = await showDialog<String>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => _SearchableSelectionDialog(
          title: widget.modalTitle,
          items: widget.items,
          popularItems: widget.popularItems,
          currentValue: widget.controller.text.trim(),
          allowCustom: widget.allowCustom,
        ),
      );
    }

    if (selected != null) {
      widget.controller.text = selected;
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        InkWell(
          onTap: widget.enabled ? _openSelectionDialog : null,
          borderRadius: BorderRadius.circular(AppRadius.r8),
          child: IgnorePointer(
            child: TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              enabled: widget.enabled,
              readOnly: true,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Select an option...',
                prefixIcon: widget.prefixIcon,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasValue && widget.enabled)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariant,
                        onPressed: () {
                          widget.controller.clear();
                          widget.onChanged?.call('');
                        },
                        tooltip: 'Clear selection',
                        visualDensity: VisualDensity.compact,
                      ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 24,
                      color: isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                fillColor: !widget.enabled
                    ? (isDark
                        ? AppColors.surfaceBorderDark.withValues(alpha: 0.3)
                        : AppColors.surfaceBorderSubtle)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableSelectionDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String>? popularItems;
  final String currentValue;
  final bool allowCustom;

  const _SearchableSelectionDialog({
    required this.title,
    required this.items,
    this.popularItems,
    required this.currentValue,
    required this.allowCustom,
  });

  @override
  State<_SearchableSelectionDialog> createState() =>
      _SearchableSelectionDialogState();
}

class _SearchableSelectionDialogState
    extends State<_SearchableSelectionDialog> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.toLowerCase().contains(_searchQuery);
    }).toList();

    final hasExactMatch = widget.items.any(
      (item) => item.toLowerCase() == _searchQuery,
    );

    final showCustomOption = widget.allowCustom &&
        _searchQuery.isNotEmpty &&
        !hasExactMatch;

    final popularList = widget.popularItems ??
        (widget.items.length > 5 ? widget.items.take(5).toList() : const <String>[]);

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        side: BorderSide(
          color: isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder,
        ),
      ),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search or type custom...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                ),
              ),
            ),

            // Quick select chips
            if (popularList.isNotEmpty && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: popularList.map((pop) {
                    final isSelected = widget.currentValue.toLowerCase() == pop.toLowerCase();
                    return ActionChip(
                      label: Text(
                        pop,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                        ),
                      ),
                      backgroundColor: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(pop),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 4),
            const Divider(height: 1),

            // List of items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: (showCustomOption ? 1 : 0) + filteredItems.length,
                itemBuilder: (ctx, index) {
                  // Custom option at the top if typed
                  if (showCustomOption && index == 0) {
                    final customVal = _searchCtrl.text.trim();
                    return ListTile(
                      leading: const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                      title: Text(
                        'Use custom: "$customVal"',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text('Add this as a custom value'),
                      onTap: () => Navigator.of(context).pop(customVal),
                    );
                  }

                  final itemIndex = showCustomOption ? index - 1 : index;
                  final item = filteredItems[itemIndex];
                  final isSelected = widget.currentValue.toLowerCase() == item.toLowerCase();

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                      ),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    onTap: () => Navigator.of(context).pop(item),
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

class _SearchableSelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String>? popularItems;
  final String currentValue;
  final bool allowCustom;

  const _SearchableSelectionBottomSheet({
    required this.title,
    required this.items,
    this.popularItems,
    required this.currentValue,
    required this.allowCustom,
  });

  @override
  State<_SearchableSelectionBottomSheet> createState() =>
      _SearchableSelectionBottomSheetState();
}

class _SearchableSelectionBottomSheetState
    extends State<_SearchableSelectionBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.toLowerCase().contains(_searchQuery);
    }).toList();

    final hasExactMatch = widget.items.any(
      (item) => item.toLowerCase() == _searchQuery,
    );

    final showCustomOption = widget.allowCustom &&
        _searchQuery.isNotEmpty &&
        !hasExactMatch;

    final popularList = widget.popularItems ??
        (widget.items.length > 5 ? widget.items.take(5).toList() : const <String>[]);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search or type custom...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            if (popularList.isNotEmpty && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: popularList.map((pop) {
                        final isSel = widget.currentValue.toLowerCase() == pop.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(pop, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: isSel
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorderSubtle),
                            side: BorderSide(
                              color: isSel ? AppColors.primary : Colors.transparent,
                            ),
                            onPressed: () => Navigator.of(context).pop(pop),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: filteredItems.length + (showCustomOption ? 1 : 0),
                itemBuilder: (context, index) {
                  if (showCustomOption && index == 0) {
                    final customVal = _searchCtrl.text.trim();
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                      title: Text(
                        'Use custom: "$customVal"',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text('Add this as a custom value'),
                      onTap: () => Navigator.of(context).pop(customVal),
                    );
                  }

                  final itemIndex = showCustomOption ? index - 1 : index;
                  final item = filteredItems[itemIndex];
                  final isSelected = widget.currentValue.toLowerCase() == item.toLowerCase();

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                      ),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    onTap: () => Navigator.of(context).pop(item),
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

