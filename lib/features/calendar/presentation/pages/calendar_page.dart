import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../../core/database/app_database.dart';
import 'package:device_calendar/device_calendar.dart' as dc;
import '../providers/calendar_settings_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/unified_agenda_item.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  void _showAddEventDialog() {
    final controller = TextEditingController();
    DateTime pickedDate = _selectedDay;
    TimeOfDay pickedTime = TimeOfDay.now();
    bool syncToSystem =
        ref.read(calendarSettingsProvider).isSyncEnabled &&
        ref.read(calendarSettingsProvider).selectedCalendarId != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.newEvent),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.eventName,
                    hintText: AppLocalizations.of(context)!.eventNameHint,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(AppLocalizations.of(context)!.date),
                  subtitle: Text(
                    DateFormat(
                      'd MMMM yyyy',
                      Localizations.localeOf(context).toString(),
                    ).format(pickedDate),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: pickedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                    );
                    if (picked != null) {
                      setState(() => pickedDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(AppLocalizations.of(context)!.time),
                  subtitle: Text(pickedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: pickedTime,
                    );
                    if (picked != null) {
                      setState(() => pickedTime = picked);
                    }
                  },
                ),
                if (ref.read(calendarSettingsProvider).isSyncEnabled &&
                    ref.read(calendarSettingsProvider).selectedCalendarId !=
                        null)
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.sync),
                    subtitle: Text(
                      AppLocalizations.of(context)!.syncDesc,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: syncToSystem,
                    onChanged: (val) =>
                        setState(() => syncToSystem = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final title = controller.text;
                  final finalDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  // Add to local DB
                  String? systemEventId;

                  // Add to system calendar if requested first to get the ID
                  if (syncToSystem) {
                    final settings = ref.read(calendarSettingsProvider);
                    if (settings.selectedCalendarId != null) {
                      systemEventId = await ref
                          .read(calendarSyncServiceProvider)
                          .addEventToCalendar(
                            calendarId: settings.selectedCalendarId!,
                            title: title,
                            date: finalDateTime,
                          );
                    }
                  }

                  // Add to local DB with the systemEventId
                  await ref
                      .read(calendarRepositoryProvider)
                      .addEvent(
                        title,
                        finalDateTime,
                        systemEventId: systemEventId,
                      );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.calendarTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddEventDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (allEvents) {
          return tasksAsync.when(
            data: (allTasks) {
              final dailyEvents = allEvents.where((e) {
                if (e is CalendarEventEntity) {
                  return isSameDay(e.date, _selectedDay);
                } else if (e is dc.Event) {
                  final start = e.start;
                  if (start == null) return false;
                  return isSameDay(
                    DateTime(start.year, start.month, start.day),
                    _selectedDay,
                  );
                }
                return false;
              }).toList();
              final dailyTasks = allTasks
                  .where(
                    (t) => t.date != null && isSameDay(t.date!, _selectedDay),
                  )
                  .toList();

              // Combine into a list of "CalendarItem" for sorting/display
              final List<dynamic> agendaItems = [];
              agendaItems.addAll(dailyEvents);
              agendaItems.addAll(dailyTasks);

              // Sort? Maybe by time if we had times for tasks, but tasks usually just date.
              // Let's just keep order or sort alphabetically?
              // Keeping simple append order for now.

              return Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ), // 1 year back
                    lastDay: DateTime.now().add(
                      const Duration(days: 365),
                    ), // 1 year forward
                    focusedDay: _focusedDay,
                    currentDay: DateTime.now(),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarFormat: _calendarFormat,
                    locale: Localizations.localeOf(context).toString(),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    eventLoader: (day) {
                      final dayEvents = allEvents.where((e) {
                        if (e is CalendarEventEntity) {
                          return isSameDay(e.date, day);
                        } else if (e is dc.Event) {
                          final start = e.start;
                          if (start == null) return false;
                          return isSameDay(
                            DateTime(start.year, start.month, start.day),
                            day,
                          );
                        }
                        return false;
                      }).toList();
                      final dayTasks = allTasks
                          .where(
                            (t) => t.date != null && isSameDay(t.date!, day),
                          )
                          .toList();
                      return [...dayEvents, ...dayTasks];
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (dailyTasks.where((t) => !t.isCompleted).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 4),
                            child: Text(
                              AppLocalizations.of(context)!.uncompletedTasks(
                                dailyTasks.where((t) => !t.isCompleted).length,
                              ),
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        if (agendaItems.isNotEmpty) ...[
                          ...agendaItems.map((item) {
                            return UnifiedAgendaItem(item: item);
                          }),
                        ] else
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.noRecordsFound(
                                  isSameDay(_selectedDay, DateTime.now())
                                      ? AppLocalizations.of(
                                          context,
                                        )!.today.toLowerCase()
                                      : DateFormat(
                                          'd MMMM',
                                          Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        ).format(_selectedDay),
                                ),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Text('${AppLocalizations.of(context)!.error}: $e'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            Center(child: Text('${AppLocalizations.of(context)!.error}: $e')),
      ),
    );
  }
}


