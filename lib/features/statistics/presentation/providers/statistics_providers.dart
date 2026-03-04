import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/statistics_service.dart';
import '../../../../core/database/app_database.dart';

/// Provider for AppDatabase
final _appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for StatisticsService
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  final database = ref.watch(_appDatabaseProvider);
  return StatisticsService(database);
});

/// Provider for today's stats
final todayStatsProvider = FutureProvider<ProductivityStatEntity>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getTodayStats();
});

/// Provider for last 7 days stats
final last7DaysStatsProvider = FutureProvider<List<ProductivityStatEntity>>((
  ref,
) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getLastNDaysStats(7);
});

/// Provider for last 30 days stats
final last30DaysStatsProvider = FutureProvider<List<ProductivityStatEntity>>((
  ref,
) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getLastNDaysStats(30);
});

/// Provider for total tasks completed
final totalTasksCompletedProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getTotalTasksCompleted();
});

/// Provider for completion rate
final completionRateProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getCompletionRate();
});

/// Provider for current streak
final currentStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getCurrentStreak();
});

/// Provider for longest streak
final longestStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  return await service.getLongestStreak();
});
