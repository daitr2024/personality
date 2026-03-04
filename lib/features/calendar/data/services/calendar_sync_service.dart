import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarSyncService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  Future<bool> requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
    }
    return permissionsGranted.isSuccess && permissionsGranted.data!;
  }

  Future<List<Calendar>> getCalendars() async {
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) return [];

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      return calendarsResult.data!;
    }
    return [];
  }

  Future<String?> addEventToCalendar({
    required String calendarId,
    required String title,
    required DateTime date,
    String? description,
    String? eventId,
  }) async {
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      return null;
    }

    // Create a TZDateTime from the provided DateTime
    final tzLocation = tz.local;

    final start = tz.TZDateTime.from(date, tzLocation);
    // Default to 1 hour event
    final end = start.add(const Duration(hours: 1));

    final event = Event(
      calendarId,
      eventId: eventId,
      title: title,
      start: start,
      end: end,
      description: description,
    );

    debugPrint(
      'CalendarSyncService: Adding event "$title" to calendar $calendarId at $date',
    );

    final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(
      event,
    );

    final success = createEventResult?.isSuccess ?? false;
    if (!success && createEventResult?.errors != null) {
      return null;
    }

    return createEventResult?.data; // Returns the eventId
  }

  Future<List<Event>> getEventsFromCalendar(
    String calendarId,
    DateTime start,
    DateTime end,
  ) async {
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      return [];
    }

    final retrieveEventsParams = RetrieveEventsParams(
      startDate: start,
      endDate: end,
    );

    final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
      calendarId,
      retrieveEventsParams,
    );

    if (eventsResult.isSuccess && eventsResult.data != null) {
      return eventsResult.data!;
    }
    return [];
  }

  /// Pushes multiple events to the system calendar.
  /// This is intended for bulk synchronization of existing local events.
  Future<Map<int, String>> syncExistingEvents({
    required String calendarId,
    required List<({int id, String title, DateTime date})> eventsToSync,
  }) async {
    final Map<int, String> syncedIds = {};

    for (var event in eventsToSync) {
      final systemId = await addEventToCalendar(
        calendarId: calendarId,
        title: event.title,
        date: event.date,
      );
      if (systemId != null) {
        syncedIds[event.id] = systemId;
      }
    }

    debugPrint(
      'CalendarSyncService: Bulk sync completed. Synced ${syncedIds.length} items.',
    );
    return syncedIds;
  }

  Future<bool> deleteEvent(String calendarId, String? eventId) async {
    if (eventId == null) return false;
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) return false;

    final result = await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    return result.isSuccess;
  }

  /// Fetches events from ALL available system calendars for the given range.
  Future<List<Event>> getEventsFromAllCalendars(
    DateTime start,
    DateTime end,
  ) async {
    final calendars = await getCalendars();
    final List<Event> allExternalEvents = [];

    for (var calendar in calendars) {
      if (calendar.id != null) {
        final events = await getEventsFromCalendar(calendar.id!, start, end);
        allExternalEvents.addAll(events);
      }
    }

    return allExternalEvents;
  }
}
