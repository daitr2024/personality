import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import 'notification_service.dart';

/// Smart notification system that schedules non-intrusive daily reminders.
///
/// Strategy to avoid notification fatigue:
/// 1. **Morning Summary** (08:00) — One grouped notification with today's overview
/// 2. **Event Pre-alert** (30 min before) — Only for calendar events with times
/// 3. **Task Gentle Nudge** (1h before) — Only for urgent/high-priority tasks
/// 4. **Evening Wrap-up** (21:00) — Summary of incomplete tasks (if any)
///
/// All notifications are batched and grouped to minimize interruptions.
class SmartNotificationService {
  final NotificationService _notificationService;
  final AppDatabase _database;

  // Notification ID ranges
  static const int _morningSummaryId = 90000;
  static const int _eveningWrapUpId = 90001;
  static const int _eventPreAlertBase = 50000;
  static const int _taskNudgeBase = 60000;

  SmartNotificationService(this._notificationService, this._database);

  /// Schedule all smart notifications for today.
  /// Call this on app launch and whenever tasks/events change.
  Future<void> scheduleSmartNotifications() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Fetch today's tasks (filter in Dart for nullable date)
      final allTasks = await (_database.select(
        _database.tasks,
      )..where((t) => t.isDeleted.equals(false))).get();
      final todayTasks = allTasks.where((t) {
        if (t.date == null) return false;
        return !t.date!.isBefore(todayStart) && t.date!.isBefore(todayEnd);
      }).toList();

      // Fetch today's events
      final allEvents = await (_database.select(
        _database.calendarEvents,
      )..where((e) => e.isDeleted.equals(false))).get();
      final todayEvents = allEvents.where((e) {
        return !e.date.isBefore(todayStart) && e.date.isBefore(todayEnd);
      }).toList();

      await _scheduleMorningSummary(now, todayTasks, todayEvents);
      await _scheduleEventPreAlerts(now, todayEvents);
      await _scheduleTaskNudges(now, todayTasks);
      await _scheduleEveningWrapUp(now, todayTasks);
    } catch (e) {
      debugPrint('SmartNotificationService: Error scheduling: $e');
    }
  }

  // ─── Morning Summary (08:00) ───────────────────────────────────

  Future<void> _scheduleMorningSummary(
    DateTime now,
    List<TaskEntity> todayTasks,
    List<CalendarEventEntity> todayEvents,
  ) async {
    final morningTime = DateTime(now.year, now.month, now.day, 8, 0);

    // Only schedule if morning hasn't passed
    if (morningTime.isBefore(now)) return;

    final incompleteTasks = todayTasks.where((t) => !t.isCompleted).length;
    final urgentTasks = todayTasks
        .where((t) => t.isUrgent && !t.isCompleted)
        .length;
    final eventCount = todayEvents.length;

    // Don't send notification if there's nothing
    if (incompleteTasks == 0 && eventCount == 0) return;

    // Build a concise summary
    final List<String> parts = [];
    if (incompleteTasks > 0) {
      parts.add('📋 $incompleteTasks görev');
    }
    if (urgentTasks > 0) {
      parts.add('🔴 $urgentTasks acil');
    }
    if (eventCount > 0) {
      parts.add('📅 $eventCount etkinlik');
    }

    final body = parts.join(' • ');

    await _notificationService.scheduleNotification(
      id: _morningSummaryId,
      title: 'Günaydın! Bugünün programı 🌅',
      body: body,
      scheduledDate: morningTime,
      payload: 'daily_summary',
    );
  }

  // ─── Event Pre-alerts (30 min before) ──────────────────────────

  Future<void> _scheduleEventPreAlerts(
    DateTime now,
    List<CalendarEventEntity> todayEvents,
  ) async {
    for (final event in todayEvents) {
      // Use startTime if available, otherwise use date
      final eventTime = event.startTime ?? event.date;

      // Schedule 30 minutes before
      final alertTime = eventTime.subtract(const Duration(minutes: 30));

      // Skip if alert time already passed
      if (alertTime.isBefore(now)) continue;

      // Skip if event already has a custom reminder
      if (event.notificationId != null) continue;

      final notifId = _eventPreAlertBase + event.id;

      final timeStr =
          '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';

      await _notificationService.scheduleNotification(
        id: notifId,
        title: '📅 ${event.title}',
        body: '30 dakika sonra • $timeStr',
        scheduledDate: alertTime,
        payload: 'event_${event.id}',
      );
    }
  }

  // ─── Task Gentle Nudges (only for urgent tasks) ────────────────

  Future<void> _scheduleTaskNudges(
    DateTime now,
    List<TaskEntity> todayTasks,
  ) async {
    // Only nudge for urgent, incomplete tasks
    final urgentTasks = todayTasks
        .where((t) => !t.isCompleted && t.isUrgent && t.date != null)
        .toList();

    for (final task in urgentTasks) {
      // Skip if task already has a custom reminder
      if (task.notificationId != null) continue;

      // Nudge 1 hour before task time
      final nudgeTime = task.date!.subtract(const Duration(hours: 1));

      if (nudgeTime.isBefore(now)) continue;

      final notifId = _taskNudgeBase + task.id;

      await _notificationService.scheduleNotification(
        id: notifId,
        title: '⚡ Acil Görev',
        body: task.title,
        scheduledDate: nudgeTime,
        payload: 'task_${task.id}',
      );
    }
  }

  // ─── Evening Wrap-up (21:00) ───────────────────────────────────

  Future<void> _scheduleEveningWrapUp(
    DateTime now,
    List<TaskEntity> todayTasks,
  ) async {
    final eveningTime = DateTime(now.year, now.month, now.day, 21, 0);

    // Only schedule if evening hasn't passed
    if (eveningTime.isBefore(now)) return;

    final incompleteTasks = todayTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = todayTasks.where((t) => t.isCompleted).toList();

    // Don't send wrap-up if everything is done or no tasks at all
    if (incompleteTasks.isEmpty) return;

    String body;
    if (completedTasks.isNotEmpty) {
      body =
          '✅ ${completedTasks.length} görev tamamlandı! '
          '📌 ${incompleteTasks.length} görev yarına aktarılabilir.';
    } else {
      body =
          '📌 ${incompleteTasks.length} tamamlanmamış görev var. '
          'Yarın için plan yapabilirsiniz.';
    }

    await _notificationService.scheduleNotification(
      id: _eveningWrapUpId,
      title: 'Günün Özeti 🌙',
      body: body,
      scheduledDate: eveningTime,
      payload: 'daily_summary',
    );
  }

  /// Cancel all smart notifications
  Future<void> cancelAll() async {
    await _notificationService.cancelNotification(_morningSummaryId);
    await _notificationService.cancelNotification(_eveningWrapUpId);

    // Cancel event pre-alerts and task nudges
    for (int i = 0; i < 200; i++) {
      await _notificationService.cancelNotification(_eventPreAlertBase + i);
      await _notificationService.cancelNotification(_taskNudgeBase + i);
    }
  }

  /// Re-schedule all notifications (call after task/event changes)
  Future<void> refresh() async {
    await cancelAll();
    await scheduleSmartNotifications();
  }
}
