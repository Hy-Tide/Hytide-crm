// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/repositories/auth_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/app_preferences_section.dart';
import '../widgets/company_settings_form.dart';
import '../widgets/user_profile_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final companyAsync = ref.watch(companySettingsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            const Breadcrumbs(
              items: [
                BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
                BreadcrumbItem(label: 'Settings'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Page Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings & Organization',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure company invoice & quotation defaults, manage account security, and set preferences.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Navigation Tabs / Segmented Controls
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Company & Billing'),
                    icon: Icon(Icons.business_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('My Account'),
                    icon: Icon(Icons.person_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Preferences & About'),
                    icon: Icon(Icons.tune_rounded, size: 18),
                  ),
                ],
                selected: {_selectedTabIndex},
                onSelectionChanged: (set) {
                  setState(() => _selectedTabIndex = set.first);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Tab Content
            if (_selectedTabIndex == 0) ...[
              companyAsync.when(
                loading: () => const Column(
                  children: [
                    SkeletonCard(),
                    SizedBox(height: AppSpacing.md),
                    SkeletonCard(),
                  ],
                ),
                error: (e, _) => Center(child: Text('Error loading company settings: $e')),
                data: (company) => CompanySettingsForm(initialSettings: company),
              ),
            ] else if (_selectedTabIndex == 1) ...[
              if (user != null)
                UserProfileSection(user: user)
              else
                const Center(child: CircularProgressIndicator()),
            ] else if (_selectedTabIndex == 2) ...[
              const AppPreferencesSection(),
            ],
          ],
        ),
      ),
    );
  }
}
