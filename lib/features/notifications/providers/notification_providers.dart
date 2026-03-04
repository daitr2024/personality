import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/reminder_scheduler.dart';
import '../../../core/services/smart_notification_service.dart';
import '../../tasks/presentation/providers/task_providers.dart';

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for reminder scheduler
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final database = ref.watch(databaseProvider);
  return ReminderScheduler(notificationService, database);
});

/// Provider for smart notification service
final smartNotificationServiceProvider = Provider<SmartNotificationService>((
  ref,
) {
  final notificationService = ref.watch(notificationServiceProvider);
  final database = ref.watch(databaseProvider);
  return SmartNotificationService(notificationService, database);
});

/// Provider to initialize notification service
final notificationInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  await service.initialize();
  await service.requestPermissions();
});

/// Provider that schedules smart notifications.
/// Watch this in the home screen to auto-refresh.
final smartNotificationSchedulerProvider = FutureProvider<void>((ref) async {
  // Wait for notification service to be initialized first
  await ref.watch(notificationInitProvider.future);
  final smartService = ref.watch(smartNotificationServiceProvider);
  await smartService.scheduleSmartNotifications();
});
