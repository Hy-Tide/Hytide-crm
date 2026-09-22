// lib/features/followups/widgets/followup_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/followup_filter_model.dart';
import '../models/followup_model.dart';
import '../providers/followup_providers.dart';

class FollowUpCalendarView extends ConsumerWidget {
  const FollowUpCalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final viewType = ref.watch(calendarViewTypeProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Column(
      children: [
        // Calendar Toolbar: Navigation (Prev, Next, Today) + View Switcher (Month, Week, Day)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Month/Week label
              Text(
                _getHeaderTitle(selectedDate, viewType),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Prev / Next / Today
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _navigateDate(ref, selectedDate, viewType, -1),
                tooltip: 'Previous',
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () {
                  ref.read(calendarSelectedDateProvider.notifier).state = DateTime.now();
                },
                child: const Text('Today'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _navigateDate(ref, selectedDate, viewType, 1),
                tooltip: 'Next',
              ),
              const Spacer(),
              // View Segmented Button (Month, Week, Day)
              SegmentedButton<CalendarViewType>(
                segments: const [
                  ButtonSegment(
                    value: CalendarViewType.month,
                    label: Text('Month'),
                  ),
                  ButtonSegment(
                    value: CalendarViewType.week,
                    label: Text('Week'),
                  ),
                  ButtonSegment(
                    value: CalendarViewType.day,
                    label: Text('Day'),
                  ),
                ],
                selected: {viewType},
                onSelectionChanged: (set) {
                  ref.read(calendarViewTypeProvider.notifier).state = set.first;
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Calendar Content Body
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              switch (viewType) {
                case CalendarViewType.month:
                  return _MonthView(
                    selectedDate: selectedDate,
                    events: events,
                  );
                case CalendarViewType.week:
                  return _WeekView(
                    selectedDate: selectedDate,
                    events: events,
                  );
                case CalendarViewType.day:
                  return _DayView(
                    selectedDate: selectedDate,
                    events: events,
                  );
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Failed to load events: $err'),
            ),
          ),
        ),
      ],
    );
  }

  String _getHeaderTitle(DateTime date, CalendarViewType view) {
    switch (view) {
      case CalendarViewType.month:
        return DateFormat('MMMM yyyy').format(date);
      case CalendarViewType.week:
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}';
      case CalendarViewType.day:
        return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  void _navigateDate(
    WidgetRef ref,
    DateTime current,
    CalendarViewType view,
    int delta,
  ) {
    final notifier = ref.read(calendarSelectedDateProvider.notifier);
    switch (view) {
      case CalendarViewType.month:
        notifier.state = DateTime(current.year, current.month + delta, 1);
        break;
      case CalendarViewType.week:
        notifier.state = current.add(Duration(days: delta * 7));
        break;
      case CalendarViewType.day:
        notifier.state = current.add(Duration(days: delta));
        break;
    }
  }
}

// ─── Month View ───────────────────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  final DateTime selectedDate;
  final List<FollowUpModel> events;

  const _MonthView({
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayWeekday = DateTime(selectedDate.year, selectedDate.month, 1).weekday; // 1 = Monday
    final totalCells = ((firstDayWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Day-of-week header
        Container(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),

        // Grid of days
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final numRows = totalCells / 7;
              final cellHeight = constraints.maxHeight / numRows;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: cellWidth / cellHeight,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  final dayOffset = index - (firstDayWeekday - 1);
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                          width: 0.5,
                        ),
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
                      ),
                    );
                  }

                  final currentDay = DateTime(selectedDate.year, selectedDate.month, dayOffset + 1);
                  final isToday = TimezoneHelper.isTodayIST(currentDay);

                  // Filter events falling on this day (IST)
                  final dayEvents = events.where((e) {
                    final ist = TimezoneHelper.toIST(e.scheduledAt);
                    return ist.year == currentDay.year &&
                        ist.month == currentDay.month &&
                        ist.day == currentDay.day;
                  }).toList();

                  return InkWell(
                    onTap: () {
                      // Click to create follow-up on this date
                      final dateStr = DateFormat('yyyy-MM-dd').format(currentDay);
                      context.push('${AppRoutes.followupCreate}?date=$dateStr');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                          width: 0.5,
                        ),
                        color: isToday
                            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                            : theme.colorScheme.surface,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isToday ? theme.colorScheme.primary : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${dayOffset + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                    color: isToday
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (dayEvents.length > 2)
                                Text(
                                  '+${dayEvents.length - 2}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayEvents.take(2).length,
                              itemBuilder: (context, eIndex) {
                                final e = dayEvents[eIndex];
                                return _CalendarEventPill(
                                  event: e,
                                  onTap: () => context.push('/followups/${e.id}'),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Week View ────────────────────────────────────────────────────────────────

class _WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<FollowUpModel> events;

  const _WeekView({
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Row(
      children: weekDays.map((day) {
        final isToday = TimezoneHelper.isTodayIST(day);
        final dayEvents = events.where((e) {
          final ist = TimezoneHelper.toIST(e.scheduledAt);
          return ist.year == day.year && ist.month == day.month && ist.day == day.day;
        }).toList();

        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  width: 0.5,
                ),
              ),
              color: isToday
                  ? theme.colorScheme.primaryContainer.withOpacity(0.08)
                  : theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                // Day header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Events list for the day
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final dateStr = DateFormat('yyyy-MM-dd').format(day);
                      context.push('${AppRoutes.followupCreate}?date=$dateStr');
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      itemCount: dayEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final e = dayEvents[index];
                        return _CalendarEventPill(
                          event: e,
                          showTime: true,
                          onTap: () => context.push('/followups/${e.id}'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Day View ─────────────────────────────────────────────────────────────────

class _DayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<FollowUpModel> events;

  const _DayView({
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayEvents = events.where((e) {
      final ist = TimezoneHelper.toIST(e.scheduledAt);
      return ist.year == selectedDate.year &&
          ist.month == selectedDate.month &&
          ist.day == selectedDate.day;
    }).toList();

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No sales activities for this day',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Schedule Follow-up'),
              onPressed: () {
                final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                context.push('${AppRoutes.followupCreate}?date=$dateStr');
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: dayEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final e = dayEvents[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(e).withOpacity(0.15),
              child: Icon(_getTypeIcon(e.type), color: _getStatusColor(e), size: 18),
            ),
            title: Text(e.companyName.isNotEmpty ? e.companyName : e.leadName),
            subtitle: Text('${e.title} · ${e.formattedTime}'),
            trailing: Chip(
              label: Text(e.status.displayName),
              backgroundColor: _getStatusColor(e).withOpacity(0.12),
              labelStyle: TextStyle(
                color: _getStatusColor(e),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            onTap: () => context.push('/followups/${e.id}'),
          ),
        );
      },
    );
  }
}

// ─── Shared Event Pill ────────────────────────────────────────────────────────

class _CalendarEventPill extends StatelessWidget {
  final FollowUpModel event;
  final bool showTime;
  final VoidCallback onTap;

  const _CalendarEventPill({
    required this.event,
    this.showTime = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(event);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          border: Border(left: BorderSide(color: statusColor, width: 3)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          showTime
              ? '${event.formattedTime} - ${event.companyName}'
              : event.companyName.isNotEmpty
                  ? event.companyName
                  : event.title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

Color _getStatusColor(FollowUpModel e) {
  if (e.status == FollowUpStatus.completed) return AppColors.success;
  if (e.status == FollowUpStatus.cancelled) return AppColors.onSurfaceVariant;
  if (e.isOverdue) return AppColors.error;
  return AppColors.primary;
}

IconData _getTypeIcon(FollowUpType type) {
  switch (type) {
    case FollowUpType.call:
      return Icons.phone_in_talk_rounded;
    case FollowUpType.whatsapp:
      return Icons.chat_rounded;
    case FollowUpType.email:
      return Icons.mail_rounded;
    case FollowUpType.meeting:
      return Icons.groups_rounded;
    case FollowUpType.demo:
      return Icons.laptop_mac_rounded;
    default:
      return Icons.schedule_rounded;
  }
}
