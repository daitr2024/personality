import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../data/services/calendar_sync_service.dart';
import 'calendar_settings_provider.dart';
import '../../../notifications/providers/notification_providers.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return CalendarRepository(db, reminderScheduler);
});

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService();
});

final calendarEventsProvider = StreamProvider<List<dynamic>>((ref) async* {
  final repository = ref.watch(calendarRepositoryProvider);
  final syncService = ref.watch(calendarSyncServiceProvider);
  final settings = ref.watch(calendarSettingsProvider);

  // Local events stream
  final localEventsStream = repository.watchAllEvents();

  await for (final localEvents in localEventsStream) {
    List<dynamic> combinedEvents = List.from(localEvents);

    if (settings.isSyncEnabled) {
      // Fetch external events from ALL available calendars for a reasonable range around today
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 1, now.day);
      final end = DateTime(now.year, now.month + 1, now.day);

      final externalEvents = await syncService.getEventsFromAllCalendars(
        start,
        end,
      );
      combinedEvents.addAll(externalEvents);
    }

    yield combinedEvents;
  }
});
