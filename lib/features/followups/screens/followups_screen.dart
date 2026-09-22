// lib/features/followups/screens/followups_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/followup_filter_model.dart';
import '../providers/followup_providers.dart';
import '../repositories/followup_repository.dart';
import '../widgets/followup_calendar_view.dart';
import '../widgets/followup_card_item.dart';
import '../widgets/followup_filter_drawer.dart';
import '../widgets/followup_kpi_header.dart';

class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _mobileAgendaFilter = 'all'; // 'all', 'today', 'tomorrow', 'upcoming', 'overdue'

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(followUpSearchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewMode = ref.watch(followUpViewModeProvider);
    final filter = ref.watch(followUpFilterProvider);
    final groupedAsync = ref.watch(groupedFollowUpsProvider);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const FollowUpFilterDrawer(),
      // Android: FAB for thumb-friendly follow-up creation
      floatingActionButton: PlatformCapabilities.isAndroid
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.followupCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Follow-up'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(followUpCountsProvider);
          ref.invalidate(filteredFollowUpsStreamProvider);
          ref.invalidate(calendarEventsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Screen Header & Action Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title, Subtitle and New Follow-up action
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Follow-ups',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your sales activities, reminders and upcoming tasks.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // New Follow-up Button — hidden on Android (uses FAB)
                        if (!PlatformCapabilities.isAndroid)
                          FilledButton.icon(
                            onPressed: () => context.push(AppRoutes.followupCreate),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Follow-up'),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Top KPI Header Cards
                    const FollowUpKpiHeader(),

                    const SizedBox(height: AppSpacing.lg),
                    // Toolbar: Search + Filter button + View Mode Toggle
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 640;
                        final searchField = TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search by company, lead, title, or assignee...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(followUpSearchQueryProvider.notifier)
                                          .state = '';
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        );

                        final filterButton = Badge(
                          isLabelVisible: filter.activeFiltersCount > 0,
                          label: Text('${filter.activeFiltersCount}'),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Filters'),
                            onPressed: () {
                              if (PlatformCapabilities.isAndroid) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => const FollowUpFilterDrawer(),
                                );
                              } else {
                                _scaffoldKey.currentState?.openEndDrawer();
                              }
                            },
                          ),
                        );

                        final viewModeToggle = SegmentedButton<FollowUpViewMode>(
                          segments: const [
                            ButtonSegment(
                              value: FollowUpViewMode.list,
                              icon: Icon(Icons.view_agenda_outlined, size: 18),
                              label: Text('List'),
                            ),
                            ButtonSegment(
                              value: FollowUpViewMode.calendar,
                              icon: Icon(Icons.calendar_month_rounded, size: 18),
                              label: Text('Calendar'),
                            ),
                          ],
                          selected: {viewMode},
                          onSelectionChanged: (val) {
                            ref.read(followUpViewModeProvider.notifier).state =
                                val.first;
                          },
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  filterButton,
                                  const Spacer(),
                                  viewModeToggle,
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: AppSpacing.sm),
                            filterButton,
                            const SizedBox(width: AppSpacing.sm),
                            viewModeToggle,
                          ],
                        );
                      },
                    ),

                    // Mobile-first Agenda Filter Chips on Android
                    if (PlatformCapabilities.isAndroid) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildAgendaFilterChip('All', 'all'),
                            const SizedBox(width: 6),
                            _buildAgendaFilterChip('Today', 'today'),
                            const SizedBox(width: 6),
                            _buildAgendaFilterChip('Tomorrow', 'tomorrow'),
                            const SizedBox(width: 6),
                            _buildAgendaFilterChip('Upcoming', 'upcoming'),
                            const SizedBox(width: 6),
                            _buildAgendaFilterChip('Overdue', 'overdue'),
                          ],
                        ),
                      ),
                    ],

                    // Active filter chips row
                    if (!filter.isEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildActiveFilterChips(theme, filter),
                    ],
                  ],
                ),
              ),
            ),

            // Content: List View OR Calendar View
            if (viewMode == FollowUpViewMode.calendar)
              const SliverFillRemaining(
                child: FollowUpCalendarView(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: groupedAsync.when(
                  data: (groups) {
                    if (groups.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyState(theme),
                      );
                    }

                    // Android Agenda-First Filtering
                    final showOverdue = !PlatformCapabilities.isAndroid ||
                        _mobileAgendaFilter == 'all' ||
                        _mobileAgendaFilter == 'overdue';
                    final showToday = !PlatformCapabilities.isAndroid ||
                        _mobileAgendaFilter == 'all' ||
                        _mobileAgendaFilter == 'today';
                    final showTomorrow = PlatformCapabilities.isAndroid &&
                        _mobileAgendaFilter == 'tomorrow';
                    final showUpcoming = !PlatformCapabilities.isAndroid ||
                        _mobileAgendaFilter == 'all' ||
                        _mobileAgendaFilter == 'upcoming';

                    final tomorrowDate = DateTime.now().add(const Duration(days: 1));
                    final tomorrowItems = groups.upcoming.where((f) {
                      return f.scheduledAt.year == tomorrowDate.year &&
                          f.scheduledAt.month == tomorrowDate.month &&
                          f.scheduledAt.day == tomorrowDate.day;
                    }).toList();

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. OVERDUE Section
                        if (showOverdue && groups.overdue.isNotEmpty) ...[
                          _buildGroupSectionHeader(
                            context: context,
                            title: 'OVERDUE',
                            count: groups.overdue.length,
                            color: AppColors.error,
                            icon: Icons.error_outline_rounded,
                          ),
                          ...groups.overdue.map((f) => FollowUpCardItem(followup: f)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // 2. TODAY Section
                        if (showToday && groups.today.isNotEmpty) ...[
                          _buildGroupSectionHeader(
                            context: context,
                            title: 'TODAY',
                            count: groups.today.length,
                            color: AppColors.primary,
                            icon: Icons.today_rounded,
                          ),
                          ...groups.today.map((f) => FollowUpCardItem(followup: f)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // 3. TOMORROW Section (Android specific quick filter)
                        if (showTomorrow && tomorrowItems.isNotEmpty) ...[
                          _buildGroupSectionHeader(
                            context: context,
                            title: 'TOMORROW',
                            count: tomorrowItems.length,
                            color: AppColors.secondary,
                            icon: Icons.next_plan_outlined,
                          ),
                          ...tomorrowItems.map((f) => FollowUpCardItem(followup: f)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // 4. UPCOMING Section
                        if (showUpcoming && groups.upcoming.isNotEmpty) ...[
                          _buildGroupSectionHeader(
                            context: context,
                            title: 'UPCOMING',
                            count: groups.upcoming.length,
                            color: AppColors.secondary,
                            icon: Icons.upcoming_rounded,
                          ),
                          ...groups.upcoming.map((f) => FollowUpCardItem(followup: f)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // 5. COMPLETED Section (if filtered)
                        if (groups.completed.isNotEmpty && (_mobileAgendaFilter == 'all' || !PlatformCapabilities.isAndroid)) ...[
                          _buildGroupSectionHeader(
                            context: context,
                            title: 'COMPLETED',
                            count: groups.completed.length,
                            color: AppColors.success,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          ...groups.completed.map((f) => FollowUpCardItem(followup: f)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // 6. CANCELLED Section (if filtered)
                        if (groups.cancelled.isNotEmpty && (_mobileAgendaFilter == 'all' || !PlatformCapabilities.isAndroid)) ...[
                          _buildGroupSectionHeader(
                            context: context,
                            title: 'CANCELLED',
                            count: groups.cancelled.length,
                            color: AppColors.onSurfaceVariant,
                            icon: Icons.cancel_outlined,
                          ),
                          ...groups.cancelled.map((f) => FollowUpCardItem(followup: f)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        const SizedBox(height: AppSpacing.xxl),
                      ]),
                    );
                  },
                  loading: () => SliverToBoxAdapter(
                    child: _buildSkeletonList(theme),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Error loading follow-ups: $err'),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton(
                              onPressed: () => ref.invalidate(filteredFollowUpsStreamProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSectionHeader({
    required BuildContext context,
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: color.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(ThemeData theme, FollowUpFilter filter) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (filter.dateFilter != FollowUpDateFilter.all)
          Chip(
            label: Text(filter.dateFilter.displayName),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              ref.read(followUpFilterProvider.notifier).state =
                  filter.copyWith(dateFilter: FollowUpDateFilter.all);
            },
          ),
        if (filter.status != null)
          Chip(
            label: Text(filter.status!.displayName),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              ref.read(followUpFilterProvider.notifier).state =
                  filter.copyWith(clearStatus: true);
            },
          ),
        if (filter.priority != null)
          Chip(
            label: Text(filter.priority!.displayName),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              ref.read(followUpFilterProvider.notifier).state =
                  filter.copyWith(clearPriority: true);
            },
          ),
        if (filter.type != null)
          Chip(
            label: Text(filter.type!.displayName),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              ref.read(followUpFilterProvider.notifier).state =
                  filter.copyWith(clearType: true);
            },
          ),
        if (filter.reminderEnabled != null)
          Chip(
            label: Text(filter.reminderEnabled! ? 'Reminder Enabled' : 'No Reminder'),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              ref.read(followUpFilterProvider.notifier).state =
                  filter.copyWith(clearReminderEnabled: true);
            },
          ),
        TextButton(
          onPressed: () {
            ref.read(followUpFilterProvider.notifier).state =
                const FollowUpFilter();
          },
          child: const Text('Clear All'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final filter = ref.watch(followUpFilterProvider);
    final search = ref.watch(followUpSearchQueryProvider);

    String title = 'No follow-ups found';
    String subtitle = 'Schedule your next sales activity to stay ahead of customer deals.';

    if (filter.dateFilter == FollowUpDateFilter.today) {
      title = 'No follow-ups today';
      subtitle = "You're all caught up for today.";
    } else if (filter.dateFilter == FollowUpDateFilter.overdue) {
      title = 'No overdue follow-ups';
      subtitle = 'Great job! Nothing needs urgent attention.';
    } else if (search.isNotEmpty) {
      title = 'No results found';
      subtitle = 'No follow-ups match "$search".';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.followupCreate),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Follow-up'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList(ThemeData theme) {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaFilterChip(String label, String key) {
    final isSelected = _mobileAgendaFilter == key;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.borderDark : AppColors.border),
      ),
      onSelected: (_) {
        setState(() {
          _mobileAgendaFilter = key;
        });
      },
    );
  }
}
