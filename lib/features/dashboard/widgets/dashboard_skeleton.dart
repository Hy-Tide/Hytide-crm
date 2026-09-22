// lib/features/dashboard/widgets/dashboard_skeleton.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_loader.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final kpiCols = width >= 1024 ? 4 : (width >= 640 ? 2 : 1);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 220, height: 28, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 320, height: 16, borderRadius: 4),
                ],
              ),
              Row(
                children: const [
                  SkeletonBox(width: 130, height: 44, borderRadius: 8),
                  SizedBox(width: 12),
                  SkeletonBox(width: 44, height: 44, borderRadius: 8),
                ],
              ),
            ],
          ),
          AppSpacing.gapH32,

          // KPI Cards Skeleton
          GridView.builder(
            itemCount: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kpiCols,
              crossAxisSpacing: AppSpacing.s16,
              mainAxisSpacing: AppSpacing.s16,
              mainAxisExtent: 116,
            ),
            itemBuilder: (_, index) => const SkeletonStatCard(),
          ),
          AppSpacing.gapH24,

          // Main Content Skeleton
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 7, child: _SkeletonCardBox(height: 280)),
                SizedBox(width: 24),
                Expanded(flex: 5, child: _SkeletonCardBox(height: 280)),
              ],
            ),
            AppSpacing.gapH24,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 7, child: _SkeletonCardBox(height: 240)),
                SizedBox(width: 24),
                Expanded(flex: 5, child: _SkeletonCardBox(height: 240)),
              ],
            ),
            AppSpacing.gapH24,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 6, child: _SkeletonCardBox(height: 260)),
                SizedBox(width: 24),
                Expanded(flex: 6, child: _SkeletonCardBox(height: 260)),
              ],
            ),
          ] else ...[
            const _SkeletonCardBox(height: 240),
            AppSpacing.gapH16,
            const _SkeletonCardBox(height: 200),
            AppSpacing.gapH16,
            const _SkeletonCardBox(height: 220),
            AppSpacing.gapH16,
            const _SkeletonCardBox(height: 220),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCardBox extends StatelessWidget {
  final double height;

  const _SkeletonCardBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 160, height: 18, borderRadius: 4),
                SkeletonBox(width: 70, height: 16, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 8),
            const SkeletonBox(width: 220, height: 12, borderRadius: 4),
            const Spacer(),
            Center(
              child: SkeletonBox(
                width: double.infinity,
                height: height * 0.5,
                borderRadius: 8,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
