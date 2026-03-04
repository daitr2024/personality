import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/reminder_scheduler.dart';
import '../../../../core/services/home_widget_service.dart';

class TasksRepository {
  final AppDatabase _db;
  final ReminderScheduler? _reminderScheduler;

  TasksRepository(this._db, [this._reminderScheduler]);

  Stream<List<TaskEntity>> watchAllTasks() {
    return (_db.select(_db.tasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<int> addTask(
    String title,
    DateTime? date,
    bool isUrgent, {
    DateTime? reminderTime,
    bool reminderEnabled = false,
    bool isRecurring = false,
    String? recurrencePattern,
    int? recurrenceInterval,
    List<String>? recurrenceDays,
    DateTime? recurrenceEndDate,
  }) async {
    // Ensure every task has a timestamp - use provided date or current time
    final taskDate = date ?? DateTime.now();

    final id = await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            title: title,
            date: Value(taskDate),
            isUrgent: Value(isUrgent),
            reminderTime: Value(reminderTime),
            reminderEnabled: Value(reminderEnabled),
            isRecurring: Value(isRecurring),
            recurrencePattern: Value(recurrencePattern),
            recurrenceInterval: Value(recurrenceInterval),
            recurrenceDays: recurrenceDays != null
                ? Value(recurrenceDays.join(','))
                : const Value.absent(),
            recurrenceEndDate: Value(recurrenceEndDate),
          ),
        );

    final scheduler = _reminderScheduler;
    if (scheduler != null && reminderEnabled && reminderTime != null) {
      final task = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(id))).getSingle();
      await scheduler.scheduleTaskReminder(task);
    }

    // Trigger widget update
    HomeWidgetService(_db).updateWidget();

    return id;
  }

  Future<void> toggleTaskCompletion(int id, bool currentStatus) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(isCompleted: Value(!currentStatus)),
    );
    // Trigger widget update
    HomeWidgetService(_db).updateWidget();
  }

  Future<void> deleteTask(int id) async {
    // Cancel any pending reminders
    final scheduler = _reminderScheduler;
    if (scheduler != null) {
      final task = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (task != null) {
        await scheduler.cancelTaskReminder(task);
      }
    }

    // Soft delete
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
    // Trigger widget update
    HomeWidgetService(_db).updateWidget();
  }

  Future<void> permanentDeleteTask(int id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<List<TaskEntity>> findTasksByTitle(String title) async {
    return (_db.select(_db.tasks)..where((t) => t.title.equals(title))).get();
  }

  Future<void> updateTaskContent(
    int id,
    String title,
    DateTime? date,
    bool? isUrgent, {
    DateTime? reminderTime,
    bool? reminderEnabled,
  }) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(title),
        date: date != null ? Value(date) : const Value.absent(),
        isUrgent: isUrgent != null ? Value(isUrgent) : const Value.absent(),
        reminderTime: reminderTime != null
            ? Value(reminderTime)
            : const Value.absent(),
        reminderEnabled: reminderEnabled != null
            ? Value(reminderEnabled)
            : const Value.absent(),
      ),
    );

    final scheduler = _reminderScheduler;
    if (scheduler != null) {
      final task = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(id))).getSingle();
      if (task.reminderEnabled && task.reminderTime != null) {
        await scheduler.scheduleTaskReminder(task);
      } else {
        await scheduler.cancelTaskReminder(task);
      }
    }
  }
}
