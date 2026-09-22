// lib/core/widgets/client_select_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/clients/repositories/client_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Interactive client selector dialog with live search, filter chips,
/// and rich client details — matching the modern search modal pattern.
class ClientSelectDialog extends ConsumerStatefulWidget {
  final String? selectedClientId;

  const ClientSelectDialog({super.key, this.selectedClientId});

  static Future<ClientModel?> show(
    BuildContext context, {
    String? selectedClientId,
  }) {
    return showDialog<ClientModel>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ClientSelectDialog(selectedClientId: selectedClientId),
    );
  }

  @override
  ConsumerState<ClientSelectDialog> createState() => _ClientSelectDialogState();
}

class _ClientSelectDialogState extends ConsumerState<ClientSelectDialog> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedChip = 'All';

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
    final clientsAsync = ref.watch(clientsStreamProvider);

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
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ──────────────────────────────────────────────────────────
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
                      Icons.business_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Client',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Search by company, contact person, phone, or email',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

            // ─── Search Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search client by company, name, phone...',
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

            // ─── Client List ─────────────────────────────────────────────────────
            Expanded(
              child: clientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Failed to load clients: $err',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (clients) {
                  if (clients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 40,
                            color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No clients found',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Convert leads to clients or create a new client first.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Extract popular / distinct industries for quick chips
                  final industries = <String>{'All'};
                  for (final c in clients) {
                    if (c.industry.isNotEmpty) industries.add(c.industry);
                  }
                  final filterChips = industries.take(6).toList();

                  // Filter clients by search query & selected chip
                  final filtered = clients.where((c) {
                    if (_selectedChip != 'All' && c.industry.toLowerCase() != _selectedChip.toLowerCase()) {
                      return false;
                    }
                    if (_searchQuery.isEmpty) return true;
                    return c.companyName.toLowerCase().contains(_searchQuery) ||
                        c.contactPerson.toLowerCase().contains(_searchQuery) ||
                        c.phone.toLowerCase().contains(_searchQuery) ||
                        c.email.toLowerCase().contains(_searchQuery) ||
                        c.city.toLowerCase().contains(_searchQuery);
                  }).toList();

                  return Column(
                    children: [
                      // Quick filter chips
                      if (_searchQuery.isEmpty && filterChips.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: filterChips.map((chip) {
                                final isSelected = _selectedChip == chip;
                                return ActionChip(
                                  label: Text(
                                    chip,
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
                                  onPressed: () {
                                    setState(() => _selectedChip = chip);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                      const Divider(height: 1),

                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching clients for "$_searchQuery"',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: filtered.length,
                                separatorBuilder: (_, index) => const Divider(height: 1),
                                itemBuilder: (ctx, index) {
                                  final client = filtered[index];
                                  final isSelected = widget.selectedClientId == client.id;
                                  final displayName = client.companyName.isNotEmpty
                                      ? client.companyName
                                      : client.contactPerson;
                                  final initial = displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'C';

                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isSelected
                                          ? AppColors.primary
                                          : AppColors.primary.withValues(alpha: 0.12),
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (client.industry.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              client.industry,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${client.contactPerson.isNotEmpty ? client.contactPerson : "No Contact"} · ${client.phone.isNotEmpty ? client.phone : client.email}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant),
                                    ),
                                    tileColor: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : null,
                                    onTap: () => Navigator.of(context).pop(client),
                                  );
                                },
                              ),
                      ),
                    ],
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
