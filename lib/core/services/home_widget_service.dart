import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../utils/date_utils.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Service to update the Android Home Widget with daily task data.
/// This data is also visible on Samsung Galaxy Watch via widget mirroring.
class HomeWidgetService {
  final AppDatabase _database;

  HomeWidgetService(this._database);

  /// Update the home widget with today's task summary
  Future<void> updateWidget() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get incomplete tasks (overdue + upcoming)
      final incompleteTasks =
          await (_database.select(_database.tasks)
                ..where(
                  (t) =>
                      t.isDeleted.equals(false) & t.isCompleted.equals(false),
                )
                ..orderBy([
                  (t) =>
                      OrderingTerm(expression: t.date, mode: OrderingMode.asc),
                ])
                ..limit(15))
              .get();

      // Get count for progress (today's only)
      final allTodayTasks =
          await (_database.select(_database.tasks)..where(
                (t) =>
                    t.isDeleted.equals(false) &
                    t.date.isBetween(Variable(todayStart), Variable(todayEnd)),
              ))
              .get();

      final completedTodayCount = allTodayTasks
          .where((t) => t.isCompleted)
          .length;
      final totalTodayCount = allTodayTasks.length;

      // Get today's events too
      final allEvents = await (_database.select(
        _database.calendarEvents,
      )..where((e) => e.isDeleted.equals(false))).get();

      final todayEvents = allEvents.where((e) {
        return !e.date.isBefore(todayStart) && e.date.isBefore(todayEnd);
      }).toList();

      // Build unified list of incomplete tasks and today's events
      final unifiedItems = <dynamic>[];

      // Add incomplete tasks
      unifiedItems.addAll(incompleteTasks);

      // Add all today's events
      unifiedItems.addAll(todayEvents);

      // Sort everything chronologically by date/time
      unifiedItems.sort((a, b) {
        DateTime dateA;
        if (a is TaskEntity) {
          dateA = a.date ?? now;
        } else if (a is CalendarEventEntity) {
          dateA = a.startTime ?? a.date;
        } else {
          dateA = now;
        }

        DateTime dateB;
        if (b is TaskEntity) {
          dateB = b.date ?? now;
        } else if (b is CalendarEventEntity) {
          dateB = b.startTime ?? b.date;
        } else {
          dateB = now;
        }

        return dateA.compareTo(dateB);
      });

      // Filter and limit to 8 closest items (closest to 'now' but starting from oldest relevant)
      // Actually the user said "closest to today's tasks", so we take the first 8 from our sorted list
      final displayList = unifiedItems.take(8).toList();

      final displayItems = <String>[];
      for (final item in displayList) {
        if (item is TaskEntity) {
          final isOverdue =
              item.date != null && item.date!.isBefore(todayStart);
          final localDate = item.date?.toAppLocal;
          final timeStr = localDate != null
              ? '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}'
              : '';
          final urgentMark = item.isUrgent ? '❗' : '';
          final overdueMark = isOverdue ? '⚠️ ' : '';
          displayItems.add('$timeStr $overdueMark$urgentMark${item.title}');
        } else if (item is CalendarEventEntity) {
          final time = (item.startTime ?? item.date).toAppLocal;
          final timeStr =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          displayItems.add('$timeStr 📅 ${item.title}');
        }
      }

      final taskListText = displayItems.isEmpty
          ? 'Bugün görev yok ✨'
          : displayItems.join('\n');

      // Progress text (Today only)
      final progressText = totalTodayCount > 0
          ? '$completedTodayCount/$totalTodayCount tamamlandı'
          : 'Bugün görev yok';

      // Save data for widget
      await HomeWidget.saveWidgetData<String>('task_list', taskListText);
      await HomeWidget.saveWidgetData<String>('progress', progressText);
      await HomeWidget.saveWidgetData<int>('completed', completedTodayCount);
      await HomeWidget.saveWidgetData<int>('total', totalTodayCount);
      await HomeWidget.saveWidgetData<int>('event_count', todayEvents.length);

      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: 'HomeWidgetProvider',
        qualifiedAndroidName: 'com.example.personality_ai.HomeWidgetProvider',
      );
    } catch (e) {
      debugPrint('HomeWidgetService: Error updating widget: $e');
    }
  }
}
