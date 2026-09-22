import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/events/app_domain_events.dart';
import '../../../core/events/app_event_bus.dart';
import '../models/followup_filter_model.dart';
import '../models/followup_model.dart';
import '../repositories/followup_repository.dart';

final followUpFilterProvider =
    StateProvider<FollowUpFilter>((ref) => const FollowUpFilter());

final followUpSearchQueryProvider = StateProvider<String>((ref) => '');

final followUpViewModeProvider =
    StateProvider<FollowUpViewMode>((ref) => FollowUpViewMode.list);

final calendarViewTypeProvider =
    StateProvider<CalendarViewType>((ref) => CalendarViewType.month);

final calendarSelectedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// Stream of follow-ups applying active filters and debounced search
final filteredFollowUpsStreamProvider =
    StreamProvider<List<FollowUpModel>>((ref) {
  final repo = ref.watch(followUpRepositoryProvider);
  final filter = ref.watch(followUpFilterProvider);
  final searchQuery = ref.watch(followUpSearchQueryProvider);

  return repo.streamFollowUpsWithFilter(filter).map((items) {
    return repo.filterBySearch(items, searchQuery);
  });
});

class GroupedFollowUps {
  final List<FollowUpModel> overdue;
  final List<FollowUpModel> today;
  final List<FollowUpModel> upcoming;
  final List<FollowUpModel> completed;
  final List<FollowUpModel> cancelled;

  const GroupedFollowUps({
    this.overdue = const [],
    this.today = const [],
    this.upcoming = const [],
    this.completed = const [],
    this.cancelled = const [],
  });

  bool get isEmpty =>
      overdue.isEmpty &&
      today.isEmpty &&
      upcoming.isEmpty &&
      completed.isEmpty &&
      cancelled.isEmpty;

  int get totalCount =>
      overdue.length +
      today.length +
      upcoming.length +
      completed.length +
      cancelled.length;
}

/// Computes partitioned groups for the default Date-Grouped Follow-up List
final groupedFollowUpsProvider = Provider<AsyncValue<GroupedFollowUps>>((ref) {
  final asyncItems = ref.watch(filteredFollowUpsStreamProvider);

  return asyncItems.whenData((items) {
    final overdue = <FollowUpModel>[];
    final today = <FollowUpModel>[];
    final upcoming = <FollowUpModel>[];
    final completed = <FollowUpModel>[];
    final cancelled = <FollowUpModel>[];

    for (final item in items) {
      if (item.status == FollowUpStatus.completed) {
        completed.add(item);
      } else if (item.status == FollowUpStatus.cancelled) {
        cancelled.add(item);
      } else if (item.isOverdue) {
        overdue.add(item);
      } else if (item.isToday) {
        today.add(item);
      } else {
        upcoming.add(item);
      }
    }

    // Sort: overdue earliest first (most urgent)
    overdue.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    // Today: earliest first
    today.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    // Upcoming: nearest first
    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    // Completed: recently completed first
    completed.sort((a, b) {
      final aDate = a.completedAt ?? a.updatedAt;
      final bDate = b.completedAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return GroupedFollowUps(
      overdue: overdue,
      today: today,
      upcoming: upcoming,
      completed: completed,
      cancelled: cancelled,
    );
  });
});

/// Future provider for loading calendar events for the active month/week
final calendarEventsProvider = FutureProvider<List<FollowUpModel>>((ref) async {
  final repo = ref.watch(followUpRepositoryProvider);
  final selectedDate = ref.watch(calendarSelectedDateProvider);
  final viewType = ref.watch(calendarViewTypeProvider);

  DateTime rangeStart;
  DateTime rangeEnd;

  switch (viewType) {
    case CalendarViewType.month:
      rangeStart = DateTime(selectedDate.year, selectedDate.month - 1, 20);
      rangeEnd = DateTime(selectedDate.year, selectedDate.month + 1, 10);
      break;
    case CalendarViewType.week:
      final daysFromMonday = selectedDate.weekday - 1;
      rangeStart = selectedDate.subtract(Duration(days: daysFromMonday, hours: 24));
      rangeEnd = rangeStart.add(const Duration(days: 9));
      break;
    case CalendarViewType.day:
      rangeStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0);
      rangeEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      break;
  }

  return repo.getCalendarFollowUps(rangeStart: rangeStart, rangeEnd: rangeEnd);
});

/// Family provider to stream single follow-up details
final followUpDetailStreamProvider =
    StreamProvider.family<FollowUpModel?, String>((ref, id) {
  return ref.watch(followUpRepositoryProvider).streamFollowUp(id);
});

/// Sync coordinator for follow-up events
final followUpSyncCoordinatorProvider = Provider<void>((ref) {
  final bus = ref.watch(appEventBusProvider);

  final sub = bus.stream.listen((event) {
    if (event is FollowUpCreatedEvent ||
        event is FollowUpUpdatedEvent ||
        event is FollowUpCompletedEvent ||
        event is FollowUpCancelledEvent ||
        event is FollowUpDeletedEvent) {
      ref.invalidate(calendarEventsProvider);
    }
  });

  ref.onDispose(sub.cancel);
});

