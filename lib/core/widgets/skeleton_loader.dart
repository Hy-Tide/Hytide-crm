// lib/core/widgets/skeleton_loader.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, borderRadius: borderRadius);
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFE2E8F0),
      highlightColor: isDark ? AppColors.surfaceBorderDark : const Color(0xFFF1F5F9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(height: 14),
                      const SizedBox(height: 6),
                      SkeletonBox(width: MediaQuery.of(context).size.width * 0.3, height: 12),
                    ],
                  ),
                ),
                const SkeletonBox(width: 60, height: 24, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(height: 12),
            const SizedBox(height: 8),
            SkeletonBox(width: MediaQuery.of(context).size.width * 0.6, height: 12),
            const SizedBox(height: 16),
            Row(
              children: [
                const SkeletonBox(width: 80, height: 24, borderRadius: 6),
                const SizedBox(width: 8),
                const SkeletonBox(width: 60, height: 24, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonListView extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const SkeletonListView({
    super.key,
    this.count = 6,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) => itemBuilder(),
    );
  }
}

class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(
                  child: SkeletonBox(height: 14),
                ),
                SizedBox(width: 8),
                SkeletonBox(width: 36, height: 36, borderRadius: 8),
              ],
            ),
            const Spacer(),
            const SkeletonBox(width: 64, height: 26),
          ],
        ),
      ),
    );
  }
}

class SkeletonTableRow extends StatelessWidget {
  final int columns;

  const SkeletonTableRow({super.key, this.columns = 6});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SkeletonBox(width: 32, height: 32, borderRadius: 16),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 13),
                const SizedBox(height: 4),
                SkeletonBox(
                  width: 80,
                  height: 11,
                ),
              ],
            ),
          ),
          ...List.generate(
            columns - 1,
            (_) => Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SkeletonBox(height: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
