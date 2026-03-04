import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/recurring_task_service.dart';
import 'task_providers.dart';
import '../../../notifications/providers/notification_providers.dart';

/// Provider for recurring task service
final recurringTaskServiceProvider = Provider<RecurringTaskService>((ref) {
  final db = ref.watch(databaseProvider);
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return RecurringTaskService(db, reminderScheduler);
});
