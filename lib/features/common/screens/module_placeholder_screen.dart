// lib/features/common/screens/module_placeholder_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/breadcrumbs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Breadcrumbs(
            items: [
              const BreadcrumbItem(label: 'Dashboard', route: AppRoutes.dashboard),
              BreadcrumbItem(label: title),
            ],
          ),
          PageHeader(
            title: title,
            subtitle: subtitle,
          ),
          AppCard(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: EmptyState(
              icon: icon,
              title: '$title Module',
              description:
                  'The $title module is currently queued for deployment in the next module release. All foundation infrastructure and models are ready.',
            ),
          ),
        ],
      ),
    );
  }
}
