// lib/features/dashboard/widgets/active_clients_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../clients/models/client_model.dart';
import '../providers/dashboard_providers.dart';
import 'section_error_card.dart';

class ActiveClientsCard extends ConsumerWidget {
  const ActiveClientsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(activeClientsProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Active Clients',
            subtitle: 'Recently onboarded customer accounts',
            trailing: TextButton(
              onPressed: () => context.go(AppRoutes.clients),
              child: const Text('View all clients'),
            ),
          ),
          AppSpacing.gapH20,
          clientsAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => SectionErrorCard(
              title: 'Active Clients',
              message: 'Failed to load clients: $err',
              onRetry: () => ref.invalidate(activeClientsProvider),
            ),
            data: (clients) {
              if (clients.isEmpty) {
                return const EmptyState(
                  icon: Icons.business_outlined,
                  title: 'No active clients',
                  description:
                      'Converted leads and onboarded client accounts will appear here.',
                  iconSize: 40,
                );
              }

              return ListView.separated(
                itemCount: clients.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, index) => const Divider(
                  height: AppSpacing.s16,
                  color: AppColors.surfaceBorder,
                ),
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return _buildClientRow(context, client);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow(BuildContext context, ClientModel client) {
    return InkWell(
      onTap: () => context.go('${AppRoutes.clients}/${client.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            UserAvatar(
              name: client.companyName.isNotEmpty ? client.companyName : 'C',
              size: 36,
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.companyName.isNotEmpty ? client.companyName : 'Untitled Client',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (client.contactPerson.isNotEmpty) ...[
                        Text(
                          client.contactPerson,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(' • ', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      ],
                      Text(
                        client.assignedToName.isNotEmpty
                            ? client.assignedToName
                            : 'Assigned to team',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              SkeletonBox(width: 36, height: 36, borderRadius: 18),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 140),
                    SizedBox(height: 6),
                    SkeletonBox(height: 10, width: 100),
                  ],
                ),
              ),
              SkeletonBox(width: 16, height: 16, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
