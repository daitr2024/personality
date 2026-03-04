import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'notification_service.dart';

/// Service for scheduling and managing reminders for tasks and events
class ReminderScheduler {
  final NotificationService _notificationService;
  final AppDatabase _database;

  ReminderScheduler(this._notificationService, this._database);

  /// Schedule a reminder for a task
  Future<void> scheduleTaskReminder(TaskEntity task) async {
    if (task.reminderTime == null || !task.reminderEnabled) {
      return;
    }

    // Don't schedule if reminder time is in the past
    if (task.reminderTime!.isBefore(DateTime.now())) {
      return;
    }

    // Cancel existing notification if any
    if (task.notificationId != null) {
      await _notificationService.cancelNotification(task.notificationId!);
    }

    // Generate unique notification ID
    final notificationId = task.id + 10000;

    // Schedule notification
    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Görev Hatırlatıcısı',
      body: task.title,
      scheduledDate: task.reminderTime!,
      payload: 'task_${task.id}',
    );

    // Update task with notification ID
    await _database
        .into(_database.tasks)
        .insertOnConflictUpdate(
          task.copyWith(notificationId: Value(notificationId)),
        );
  }

  /// Schedule a reminder for a calendar event
  Future<void> scheduleEventReminder(CalendarEventEntity event) async {
    if (event.startTime == null ||
        !event.reminderEnabled ||
        event.reminderMinutesBefore == null) {
      return;
    }

    // Cancel existing notification if any
    if (event.notificationId != null) {
      await _notificationService.cancelNotification(event.notificationId!);
    }

    // Calculate reminder time
    final reminderTime = event.startTime!.subtract(
      Duration(minutes: event.reminderMinutesBefore!),
    );

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    // Generate unique notification ID
    final notificationId = event.id + 20000; // Offset to avoid conflicts

    // Schedule notification
    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Etkinlik Hatırlatıcısı',
      body: event.title,
      scheduledDate: reminderTime,
      payload: 'event_${event.id}',
    );

    // Update event with notification ID
    await _database
        .into(_database.calendarEvents)
        .insertOnConflictUpdate(
          event.copyWith(notificationId: Value(notificationId)),
        );
  }

  /// Cancel a task reminder
  Future<void> cancelTaskReminder(TaskEntity task) async {
    if (task.notificationId != null) {
      await _notificationService.cancelNotification(task.notificationId!);

      // Update task to remove notification ID
      await _database
          .into(_database.tasks)
          .insertOnConflictUpdate(
            task.copyWith(
              notificationId: const Value(null),
              reminderEnabled: false,
            ),
          );
    }
  }

  /// Cancel an event reminder
  Future<void> cancelEventReminder(CalendarEventEntity event) async {
    if (event.notificationId != null) {
      await _notificationService.cancelNotification(event.notificationId!);

      // Update event to remove notification ID
      await _database
          .into(_database.calendarEvents)
          .insertOnConflictUpdate(
            event.copyWith(
              notificationId: const Value(null),
              reminderEnabled: false,
            ),
          );
    }
  }

  /// Clean up past reminders
  Future<void> cleanupPastReminders() async {
    final now = DateTime.now();

    // Get all tasks with past reminder times
    final tasksQuery = _database.select(_database.tasks)
      ..where((t) => t.reminderTime.isSmallerThanValue(now));
    final pastTasks = await tasksQuery.get();

    for (final task in pastTasks) {
      if (task.notificationId != null) {
        await _notificationService.cancelNotification(task.notificationId!);
      }
    }

    // Get all events with past reminder times
    final eventsQuery = _database.select(_database.calendarEvents)
      ..where((e) => e.startTime.isSmallerThanValue(now));
    final pastEvents = await eventsQuery.get();

    for (final event in pastEvents) {
      if (event.notificationId != null) {
        await _notificationService.cancelNotification(event.notificationId!);
      }
    }
  }
}
