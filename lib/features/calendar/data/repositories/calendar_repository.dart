import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/reminder_scheduler.dart';
import '../../../../core/services/home_widget_service.dart';

class CalendarRepository {
  final AppDatabase _db;
  final ReminderScheduler? _reminderScheduler;

  CalendarRepository(this._db, [this._reminderScheduler]);

  Stream<List<CalendarEventEntity>> watchAllEvents() {
    return (_db.select(
      _db.calendarEvents,
    )..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<List<CalendarEventEntity>> getUnsyncedEvents() async {
    return (_db.select(_db.calendarEvents)
          ..where((t) => t.isDeleted.equals(false) & t.systemEventId.isNull()))
        .get();
  }

  Future<int> addEvent(
    String title,
    DateTime date, {
    String? systemEventId,
    int? reminderMinutesBefore,
    bool reminderEnabled = false,
  }) async {
    final id = await _db
        .into(_db.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            title: title,
            date: date,
            startTime: Value(date),
            systemEventId: Value(systemEventId),
            reminderMinutesBefore: Value(reminderMinutesBefore),
            reminderEnabled: Value(reminderEnabled),
          ),
        );

    final scheduler = _reminderScheduler;
    if (scheduler != null && reminderEnabled && reminderMinutesBefore != null) {
      final event = await (_db.select(
        _db.calendarEvents,
      )..where((e) => e.id.equals(id))).getSingle();
      await scheduler.scheduleEventReminder(event);
    }

    // Trigger widget update
    HomeWidgetService(_db).updateWidget();

    return id;
  }

  Future<void> deleteEvent(int id) async {
    // Cancel any pending reminders
    final scheduler = _reminderScheduler;
    if (scheduler != null) {
      final event = await (_db.select(
        _db.calendarEvents,
      )..where((e) => e.id.equals(id))).getSingleOrNull();
      if (event != null) {
        await scheduler.cancelEventReminder(event);
      }
    }

    // Soft delete
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
      CalendarEventsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
    // Trigger widget update
    HomeWidgetService(_db).updateWidget();
  }

  Future<void> permanentDeleteEvent(int id) async {
    await (_db.delete(_db.calendarEvents)..where((t) => t.id.equals(id))).go();
  }

  Future<List<CalendarEventEntity>> findEventsByTitle(String title) async {
    return (_db.select(
      _db.calendarEvents,
    )..where((t) => t.title.equals(title))).get();
  }

  Future<void> updateEvent(
    int id,
    String title,
    DateTime? date, {
    String? systemEventId,
    int? reminderMinutesBefore,
    bool? reminderEnabled,
  }) async {
    if (date != null) {
      debugPrint(
        '📅 REPO updateEvent: date=$date isUtc=${date.isUtc} hour=${date.hour} ms=${date.millisecondsSinceEpoch}',
      );
    }
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
      CalendarEventsCompanion(
        title: Value(title),
        date: date != null ? Value(date) : const Value.absent(),
        startTime: date != null ? Value(date) : const Value.absent(),
        systemEventId: systemEventId != null
            ? Value(systemEventId)
            : const Value.absent(),
        reminderMinutesBefore: reminderMinutesBefore != null
            ? Value(reminderMinutesBefore)
            : const Value.absent(),
        reminderEnabled: reminderEnabled != null
            ? Value(reminderEnabled)
            : const Value.absent(),
      ),
    );

    // Trigger widget update
    HomeWidgetService(_db).updateWidget();

    final scheduler = _reminderScheduler;
    if (scheduler != null) {
      final event = await (_db.select(
        _db.calendarEvents,
      )..where((e) => e.id.equals(id))).getSingle();
      if (event.reminderEnabled && event.reminderMinutesBefore != null) {
        await scheduler.scheduleEventReminder(event);
      } else {
        await scheduler.cancelEventReminder(event);
      }
    }
  }

  Future<void> updateSystemEventId(int id, String systemEventId) async {
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
      CalendarEventsCompanion(systemEventId: Value(systemEventId)),
    );
  }
}
