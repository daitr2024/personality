import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Service for tracking and retrieving productivity statistics
class StatisticsService {
  final AppDatabase _database;

  StatisticsService(this._database);

  /// Get or create today's stats
  Future<ProductivityStatEntity> getTodayStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final existing = await (_database.select(
      _database.productivityStats,
    )..where((s) => s.date.equals(startOfDay))).getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    // Create new stats for today
    final id = await _database
        .into(_database.productivityStats)
        .insert(ProductivityStatsCompanion.insert(date: startOfDay));

    return await (_database.select(
      _database.productivityStats,
    )..where((s) => s.id.equals(id))).getSingle();
  }

  /// Increment tasks completed count
  Future<void> incrementTasksCompleted() async {
    final stats = await getTodayStats();
    await (_database.update(
      _database.productivityStats,
    )..where((s) => s.id.equals(stats.id))).write(
      ProductivityStatsCompanion(
        tasksCompleted: Value(stats.tasksCompleted + 1),
      ),
    );
  }

  /// Increment tasks created count
  Future<void> incrementTasksCreated() async {
    final stats = await getTodayStats();
    await (_database.update(
      _database.productivityStats,
    )..where((s) => s.id.equals(stats.id))).write(
      ProductivityStatsCompanion(tasksCreated: Value(stats.tasksCreated + 1)),
    );
  }

  /// Increment notes created count
  Future<void> incrementNotesCreated() async {
    final stats = await getTodayStats();
    await (_database.update(
      _database.productivityStats,
    )..where((s) => s.id.equals(stats.id))).write(
      ProductivityStatsCompanion(notesCreated: Value(stats.notesCreated + 1)),
    );
  }

  /// Increment events attended count
  Future<void> incrementEventsAttended() async {
    final stats = await getTodayStats();
    await (_database.update(
      _database.productivityStats,
    )..where((s) => s.id.equals(stats.id))).write(
      ProductivityStatsCompanion(
        eventsAttended: Value(stats.eventsAttended + 1),
      ),
    );
  }

  /// Get stats for a specific date range
  Future<List<ProductivityStatEntity>> getStatsForRange(
    DateTime start,
    DateTime end,
  ) async {
    return await (_database.select(_database.productivityStats)
          ..where(
            (s) =>
                s.date.isBiggerOrEqualValue(start) &
                s.date.isSmallerOrEqualValue(end),
          )
          ..orderBy([(s) => OrderingTerm(expression: s.date)]))
        .get();
  }

  /// Get stats for last N days
  Future<List<ProductivityStatEntity>> getLastNDaysStats(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getStatsForRange(start, end);
  }

  /// Get total tasks completed
  Future<int> getTotalTasksCompleted() async {
    final allStats = await _database.select(_database.productivityStats).get();
    return allStats.fold<int>(0, (sum, stat) => sum + stat.tasksCompleted);
  }

  /// Get completion rate (%)
  Future<double> getCompletionRate() async {
    final allStats = await _database.select(_database.productivityStats).get();
    final completed = allStats.fold<int>(
      0,
      (sum, stat) => sum + stat.tasksCompleted,
    );
    final created = allStats.fold<int>(
      0,
      (sum, stat) => sum + stat.tasksCreated,
    );

    if (created == 0) return 0.0;
    return (completed / created) * 100;
  }

  /// Get average daily tasks
  Future<double> getAverageDailyTasks() async {
    final allStats = await _database.select(_database.productivityStats).get();
    if (allStats.isEmpty) return 0.0;

    final total = allStats.fold<int>(
      0,
      (sum, stat) => sum + stat.tasksCompleted,
    );
    return total / allStats.length;
  }

  /// Get current streak (consecutive days with at least 1 task completed)
  Future<int> getCurrentStreak() async {
    final stats = await getLastNDaysStats(365); // Check last year
    if (stats.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < stats.length; i++) {
      final stat = stats[stats.length - 1 - i]; // Reverse order
      final daysDiff = today.difference(stat.date).inDays;

      if (daysDiff == i && stat.tasksCompleted > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get longest streak
  Future<int> getLongestStreak() async {
    final stats = await _database.select(_database.productivityStats).get();
    if (stats.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final stat in stats) {
      if (stat.tasksCompleted > 0) {
        if (lastDate == null || stat.date.difference(lastDate).inDays == 1) {
          currentStreak++;
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        } else {
          currentStreak = 1;
        }
        lastDate = stat.date;
      } else {
        currentStreak = 0;
      }
    }

    return maxStreak;
  }

  /// Get most productive day of week (0 = Monday, 6 = Sunday)
  Future<int?> getMostProductiveDay() async {
    final stats = await _database.select(_database.productivityStats).get();
    if (stats.isEmpty) return null;

    final dayTotals = List.filled(7, 0);

    for (final stat in stats) {
      final weekday = stat.date.weekday - 1; // Convert to 0-6
      dayTotals[weekday] += stat.tasksCompleted;
    }

    int maxDay = 0;
    for (int i = 1; i < 7; i++) {
      if (dayTotals[i] > dayTotals[maxDay]) {
        maxDay = i;
      }
    }

    return dayTotals[maxDay] > 0 ? maxDay : null;
  }
}
