import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/app_database.dart';

import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../notes/presentation/providers/note_providers.dart';
import 'package:device_calendar/device_calendar.dart';

/// Holds the currently selected date in the dashboard
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  () {
    return SelectedDateNotifier();
  },
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void updateDate(DateTime newDate) {
    state = newDate;
  }
}

final calendarVisibilityProvider =
    NotifierProvider<CalendarVisibilityNotifier, bool>(() {
      return CalendarVisibilityNotifier();
    });

class CalendarVisibilityNotifier extends Notifier<bool> {
  static const _kKey = 'calendar_visible';

  @override
  bool build() {
    _load();
    return true; // Default
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, state);
  }
}

/// Filters tasks for the selected date
final dailyTasksProvider = Provider<AsyncValue<List<TaskEntity>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final tasksAsync = ref.watch(taskListProvider);

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      return _isTaskOnDate(task, selectedDate);
    }).toList();
  });
});

bool _isTaskOnDate(TaskEntity task, DateTime selectedDate) {
  if (task.date == null) return false;

  // 1. Direct match
  if (isSameDay(task.date!.toLocal(), selectedDate)) return true;

  // 2. Recurrence check
  if (task.isRecurring) {
    final taskLocalDate = task.date!.toLocal();
    // Cannot be before start date
    if (selectedDate.isBefore(
      DateTime(taskLocalDate.year, taskLocalDate.month, taskLocalDate.day),
    )) {
      return false;
    }

    // Cannot be after end date
    if (task.recurrenceEndDate != null &&
        selectedDate.isAfter(task.recurrenceEndDate!)) {
      return false;
    }

    if (task.recurrencePattern == 'daily') {
      return true;
    }

    if (task.recurrencePattern == 'weekly' && task.recurrenceDays != null) {
      final days = task.recurrenceDays!.split(',');
      final weekday = _getWeekdayName(selectedDate.weekday);
      return days.contains(weekday);
    }
  }

  return false;
}

String _getWeekdayName(int day) {
  const names = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };
  return names[day] ?? '';
}

/// Filters overdue tasks (incomplete and before today)
final overdueTasksProvider = Provider<AsyncValue<List<TaskEntity>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      if (task.isCompleted) return false;
      if (task.date == null) return false;

      // Recurring tasks are never truly "overdue" in the past-date sense for today
      // unless we implement instance-based completion. For now, keep it simple.
      if (task.isRecurring) return false;

      return task.date!.isBefore(todayStart);
    }).toList();
  });
});

/// Filters calendar events for the selected date
final dailyEventsProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final eventsAsync = ref.watch(calendarEventsProvider);

  return eventsAsync.whenData((events) {
    return events.where((event) {
      if (event is CalendarEventEntity) {
        return isSameDay(event.date.toLocal(), selectedDate);
      } else if (event is Event) {
        final start = event.start;
        if (start == null) return false;

        // Correctly handle UTC to Local conversion for device events
        final localStart = start.isUtc ? start.toLocal() : start;
        return isSameDay(localStart, selectedDate);
      }
      return false;
    }).toList();
  });
});

/// Filters notes created on the selected date
final dailyNotesProvider = Provider<AsyncValue<List<NoteEntity>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final notesAsync = ref.watch(noteListProvider);

  return notesAsync.whenData((notes) {
    return notes.where((note) {
      return isSameDay(note.date.toLocal(), selectedDate);
    }).toList();
  });
});

// Helper to check same day
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

enum DashboardFilter { all, tasks, events, notes }

class DashboardFilterNotifier extends Notifier<DashboardFilter> {
  @override
  DashboardFilter build() => DashboardFilter.all;

  void updateFilter(DashboardFilter filter) {
    state = filter;
  }
}

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilter>(
      DashboardFilterNotifier.new,
    );

enum ItemType { task, event, note }

final dayItemsTypeProvider = Provider.family<Set<ItemType>, DateTime>((
  ref,
  date,
) {
  final types = <ItemType>{};
  final tasksAsync = ref.watch(taskListProvider);
  final eventsAsync = ref.watch(calendarEventsProvider);
  final notesAsync = ref.watch(noteListProvider);

  if (tasksAsync.value?.any((t) => _isTaskOnDate(t, date)) ?? false) {
    types.add(ItemType.task);
  }
  if (eventsAsync.value?.any((e) {
        if (e is CalendarEventEntity) return isSameDay(e.date, date);
        if (e is Event && e.start != null) return isSameDay(e.start!, date);
        return false;
      }) ??
      false) {
    types.add(ItemType.event);
  }
  if (notesAsync.value?.any((n) => isSameDay(n.date, date)) ?? false) {
    types.add(ItemType.note);
  }
  return types;
});

final dayHasItemsProvider = Provider.family<bool, DateTime>((ref, date) {
  final types = ref.watch(dayItemsTypeProvider(date));
  return types.isNotEmpty;
});

final nearFutureItemsProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final tasksAsync = ref.watch(taskListProvider);
  final eventsAsync = ref.watch(calendarEventsProvider);
  final notesAsync = ref.watch(noteListProvider);

  if (tasksAsync.isLoading || eventsAsync.isLoading || notesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final allItems = <dynamic>[];
  tasksAsync.whenData(
    (tasks) => allItems.addAll(tasks.where((t) => t.date != null)),
  );
  eventsAsync.whenData((events) => allItems.addAll(events));
  notesAsync.whenData((notes) => allItems.addAll(notes));

  // Sort all items by date
  allItems.sort((a, b) {
    final dateA = _getItemDate(a);
    final dateB = _getItemDate(b);
    return dateA.compareTo(dateB);
  });

  // Future items only (after selectedDate)
  final futureItems = allItems.where((item) {
    final date = _getItemDate(item);
    // Start of next day
    final nextDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).add(const Duration(days: 1));
    return date.isAfter(nextDay) || isSameDay(date, nextDay);
  }).toList();

  // Try to get next 7 days, if not enough, get next 10 items
  final rangeEnd = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day + 7,
    23,
    59,
    59,
  );
  final prioritized = futureItems
      .where((item) => _getItemDate(item).isBefore(rangeEnd))
      .toList();

  if (prioritized.length >= 5) {
    return AsyncValue.data(prioritized);
  }

  return AsyncValue.data(futureItems.take(10).toList());
});

DateTime _getItemDate(dynamic item) {
  if (item is TaskEntity) return item.date!;
  if (item is CalendarEventEntity) return item.date;
  if (item is Event && item.start != null) return item.start!;
  if (item is NoteEntity) return item.date;
  return DateTime(0);
}
