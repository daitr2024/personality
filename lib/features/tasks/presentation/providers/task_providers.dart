import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../../finance/presentation/providers/finance_providers.dart'; // Reuse databaseProvider
import '../../../notifications/providers/notification_providers.dart';

// Export databaseProvider for use in other features
export '../../../finance/presentation/providers/finance_providers.dart'
    show databaseProvider;

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return TasksRepository(db, reminderScheduler);
});

final taskListProvider = StreamProvider<List<TaskEntity>>((ref) {
  final repository = ref.watch(tasksRepositoryProvider);
  return repository.watchAllTasks();
});
