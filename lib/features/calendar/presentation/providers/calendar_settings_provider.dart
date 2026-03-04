import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final calendarSettingsProvider =
    NotifierProvider<CalendarSettingsNotifier, CalendarSettingsState>(() {
      return CalendarSettingsNotifier();
    });

class CalendarSettingsState {
  final String? selectedCalendarId;
  final bool isSyncEnabled;

  CalendarSettingsState({this.selectedCalendarId, this.isSyncEnabled = false});

  CalendarSettingsState copyWith({
    String? selectedCalendarId,
    bool? isSyncEnabled,
  }) {
    return CalendarSettingsState(
      selectedCalendarId: selectedCalendarId ?? this.selectedCalendarId,
      isSyncEnabled: isSyncEnabled ?? this.isSyncEnabled,
    );
  }
}

class CalendarSettingsNotifier extends Notifier<CalendarSettingsState> {
  static const _kSyncEnabledKey = 'calendar_sync_enabled';
  static const _kSelectedCalendarKey = 'selected_calendar_id';

  @override
  CalendarSettingsState build() {
    _loadSettings();
    return CalendarSettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kSyncEnabledKey) ?? false;
    final calendarId = prefs.getString(_kSelectedCalendarKey);
    state = state.copyWith(
      isSyncEnabled: isEnabled,
      selectedCalendarId: calendarId,
    );
  }

  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSyncEnabledKey, enabled);
    state = state.copyWith(isSyncEnabled: enabled);
  }

  Future<void> setSelectedCalendarId(String? calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    if (calendarId == null) {
      await prefs.remove(_kSelectedCalendarKey);
    } else {
      await prefs.setString(_kSelectedCalendarKey, calendarId);
    }
    state = state.copyWith(selectedCalendarId: calendarId);
  }
}
