import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'reminder_scheduler.dart';

/// Recurrence pattern types
enum RecurrencePattern {
  daily,
  weekly,
  monthly,
  custom;

  String toJson() => name;

  static RecurrencePattern fromJson(String json) {
    return RecurrencePattern.values.firstWhere((e) => e.name == json);
  }
}

/// Service for managing recurring tasks
class RecurringTaskService {
  final AppDatabase _database;
  final ReminderScheduler? _reminderScheduler;

  RecurringTaskService(this._database, [this._reminderScheduler]);

  /// Create a recurring task
  Future<TaskEntity> createRecurringTask({
    required String title,
    required DateTime startDate,
    required RecurrencePattern pattern,
    bool isUrgent = false,
    int? customInterval,
    List<int>? weeklyDays,
    DateTime? endDate,
    DateTime? reminderTime,
    bool reminderEnabled = false,
  }) async {
    final taskId = await _database
        .into(_database.tasks)
        .insert(
          TasksCompanion.insert(
            title: title,
            date: Value(startDate),
            isUrgent: Value(isUrgent),
            isRecurring: const Value(true),
            recurrencePattern: Value(pattern.toJson()),
            recurrenceInterval: Value(customInterval),
            recurrenceDays: Value(
              weeklyDays != null ? jsonEncode(weeklyDays) : null,
            ),
            recurrenceEndDate: Value(endDate),
            reminderTime: Value(reminderTime),
            reminderEnabled: Value(reminderEnabled),
          ),
        );

    // Return the created task
    final task = await (_database.select(
      _database.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();

    final scheduler = _reminderScheduler;
    if (scheduler != null && reminderEnabled && reminderTime != null) {
      await scheduler.scheduleTaskReminder(task);
    }

    return task;
  }

  /// Generate next occurrence of a recurring task
  Future<TaskEntity?> generateNextOccurrence(TaskEntity parentTask) async {
    if (!parentTask.isRecurring || parentTask.date == null) {
      return null;
    }

    final pattern = RecurrencePattern.fromJson(parentTask.recurrencePattern!);
    final nextDate = _calculateNextDate(
      parentTask.date!,
      pattern,
      customInterval: parentTask.recurrenceInterval,
      weeklyDays: parentTask.recurrenceDays,
    );

    // Check if we've passed the end date
    if (parentTask.recurrenceEndDate != null &&
        nextDate.isAfter(parentTask.recurrenceEndDate!)) {
      return null;
    }

    // Calculate new reminder time
    final newReminderTime = parentTask.reminderTime != null
        ? _adjustReminderTime(
            nextDate,
            parentTask.date!,
            parentTask.reminderTime!,
          )
        : null;

    // Create new task instance
    final newTaskId = await _database
        .into(_database.tasks)
        .insert(
          TasksCompanion.insert(
            title: parentTask.title,
            date: Value(nextDate),
            isUrgent: Value(parentTask.isUrgent),
            parentTaskId: Value(parentTask.id),
            reminderTime: Value(newReminderTime),
            reminderEnabled: Value(parentTask.reminderEnabled),
          ),
        );

    final newTask = await (_database.select(
      _database.tasks,
    )..where((t) => t.id.equals(newTaskId))).getSingle();

    final scheduler = _reminderScheduler;
    if (scheduler != null &&
        newTask.reminderEnabled &&
        newTask.reminderTime != null) {
      await scheduler.scheduleTaskReminder(newTask);
    }

    return newTask;
  }

  /// Calculate next date based on recurrence pattern
  DateTime _calculateNextDate(
    DateTime currentDate,
    RecurrencePattern pattern, {
    int? customInterval,
    String? weeklyDays,
  }) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return currentDate.add(const Duration(days: 1));

      case RecurrencePattern.weekly:
        if (weeklyDays != null) {
          final days = (jsonDecode(weeklyDays) as List).cast<int>();
          final currentWeekday = currentDate.weekday;

          // Find next day in the list
          final nextDay = days.firstWhere(
            (day) => day > currentWeekday,
            orElse: () => days.first,
          );

          final daysToAdd = nextDay > currentWeekday
              ? nextDay - currentWeekday
              : 7 - currentWeekday + nextDay;

          return currentDate.add(Duration(days: daysToAdd));
        }
        return currentDate.add(const Duration(days: 7));

      case RecurrencePattern.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );

      case RecurrencePattern.custom:
        if (customInterval != null) {
          return currentDate.add(Duration(days: customInterval));
        }
        return currentDate.add(const Duration(days: 1));
    }
  }

  /// Adjust reminder time for new occurrence
  DateTime? _adjustReminderTime(
    DateTime newDate,
    DateTime oldDate,
    DateTime oldReminderTime,
  ) {
    final difference = oldDate.difference(oldReminderTime);
    return newDate.subtract(difference);
  }

  /// Get all active recurring tasks
  Future<List<TaskEntity>> getActiveRecurringTasks() async {
    return await (_database.select(_database.tasks)
          ..where((t) => t.isRecurring.equals(true))
          ..where((t) => t.isDeleted.equals(false))
          ..where((t) => t.parentTaskId.isNull()))
        .get();
  }

  /// Get child tasks of a recurring task
  Future<List<TaskEntity>> getChildTasks(int parentTaskId) async {
    return await (_database.select(_database.tasks)
          ..where((t) => t.parentTaskId.equals(parentTaskId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  /// Update recurring task and all future occurrences
  Future<void> updateRecurringTask(
    int taskId,
    String title,
    bool isUrgent, {
    DateTime? reminderTime,
    bool? reminderEnabled,
  }) async {
    final task = await (_database.select(
      _database.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();

    // Update parent task
    await (_database.update(
      _database.tasks,
    )..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        title: Value(title),
        isUrgent: Value(isUrgent),
        reminderTime: Value(reminderTime),
        reminderEnabled: reminderEnabled != null
            ? Value(reminderEnabled)
            : const Value.absent(),
      ),
    );

    // Update all future child tasks
    if (task.isRecurring) {
      final now = DateTime.now();
      final childTasks =
          await (_database.select(_database.tasks)
                ..where((t) => t.parentTaskId.equals(taskId))
                ..where((t) => t.date.isBiggerOrEqualValue(now)))
              .get();

      for (final child in childTasks) {
        final newChildReminderTime = reminderTime != null && task.date != null
            ? _adjustReminderTime(child.date!, task.date!, reminderTime)
            : null;

        await (_database.update(
          _database.tasks,
        )..where((t) => t.id.equals(child.id))).write(
          TasksCompanion(
            title: Value(title),
            isUrgent: Value(isUrgent),
            reminderTime: Value(newChildReminderTime),
            reminderEnabled: reminderEnabled != null
                ? Value(reminderEnabled)
                : const Value.absent(),
          ),
        );

        final scheduler = _reminderScheduler;
        if (scheduler != null) {
          final updatedChild = await (_database.select(
            _database.tasks,
          )..where((t) => t.id.equals(child.id))).getSingle();
          if (updatedChild.reminderEnabled &&
              updatedChild.reminderTime != null) {
            await scheduler.scheduleTaskReminder(updatedChild);
          } else {
            await scheduler.cancelTaskReminder(updatedChild);
          }
        }
      }
    }

    final scheduler = _reminderScheduler;
    if (scheduler != null) {
      final updatedParent = await (_database.select(
        _database.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      if (updatedParent.reminderEnabled && updatedParent.reminderTime != null) {
        await scheduler.scheduleTaskReminder(updatedParent);
      } else {
        await scheduler.cancelTaskReminder(updatedParent);
      }
    }
  }

  /// Delete recurring task and optionally all occurrences
  Future<void> deleteRecurringTask(
    int taskId, {
    bool deleteAllOccurrences = false,
  }) async {
    final now = DateTime.now();
    final scheduler = _reminderScheduler;

    // Get parent task for cancellation
    if (scheduler != null) {
      final parent = await (_database.select(
        _database.tasks,
      )..where((t) => t.id.equals(taskId))).getSingleOrNull();
      if (parent != null) {
        await scheduler.cancelTaskReminder(parent);
      }
    }

    // Soft delete the parent task
    await (_database.update(
      _database.tasks,
    )..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(isDeleted: const Value(true), deletedAt: Value(now)),
    );

    if (deleteAllOccurrences) {
      // Get all future child tasks to cancel their reminders
      if (scheduler != null) {
        final children = await (_database.select(
          _database.tasks,
        )..where((t) => t.parentTaskId.equals(taskId))).get();
        for (final child in children) {
          await scheduler.cancelTaskReminder(child);
        }
      }

      // Delete all child tasks
      await (_database.update(
        _database.tasks,
      )..where((t) => t.parentTaskId.equals(taskId))).write(
        TasksCompanion(isDeleted: const Value(true), deletedAt: Value(now)),
      );
    }
  }
}
