// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:device_calendar/device_calendar.dart' as dc;
import '../../../../config/theme/app_theme.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../notes/presentation/providers/note_providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../notes/presentation/widgets/audio_player_widget.dart';
import 'daily_timeline.dart';
import 'overdue_tasks_dialog.dart';

class DailyDashboard extends ConsumerWidget {
  const DailyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(dailyTasksProvider);
    final eventsAsync = ref.watch(dailyEventsProvider);
    final notesAsync = ref.watch(dailyNotesProvider);

    // Always show all items in the unified dashboard
    final timelineItems = <dynamic>[];
    tasksAsync.whenData((tasks) => timelineItems.addAll(tasks));
    eventsAsync.whenData((events) => timelineItems.addAll(events));
    notesAsync.whenData((notes) => timelineItems.addAll(notes));

    return Column(
      children: [
        // Overdue Warning & Timeline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _buildOverdueWarning(context, ref),
              DailyTimeline(
                items: timelineItems,
                selectedDate: selectedDate,
                onItemTap: (item) => _showItemDetail(context, ref, item),
              ),
              if (timelineItems.isEmpty) ...[
                const Gap(24),
                _buildEmptyState(context, selectedDate),
              ],
              const Gap(20),
              _buildNearFutureSection(context, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime selectedDate) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday = isSameDay(selectedDate, now);
    final localeCode = Localizations.localeOf(context).toString();
    final dateStr = isToday
        ? AppLocalizations.of(context)!.today.toLowerCase()
        : DateFormat('d MMMM', localeCode).format(selectedDate);

    String message = AppLocalizations.of(context)!.noRecordsFound(dateStr);
    IconData icon = Icons.inbox_outlined;

    return Column(
      children: [
        Icon(icon, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
        const Gap(12),
        Text(
          message,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getItemColor(dynamic item) {
    if (item is TaskEntity) {
      return item.isCompleted ? AppTheme.completedColor : AppTheme.taskColor;
    }
    if (item is CalendarEventEntity) return AppTheme.eventColor;
    if (item is dc.Event) return AppTheme.completedColor;
    if (item is NoteEntity) return AppTheme.noteColor;
    return Colors.grey;
  }

  String _getFormattedTime(dynamic item) {
    DateTime? dt;
    if (item is TaskEntity) {
      dt = item.date?.toAppLocal;
    } else if (item is CalendarEventEntity) {
      dt = item.date.toAppLocal;
    } else if (item is dc.Event) {
      dt = item.start?.toAppLocal;
    } else if (item is NoteEntity) {
      dt = item.date.toAppLocal;
    }

    return dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
  }

  void _showItemDetail(BuildContext context, WidgetRef ref, dynamic item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getItemColor(item).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeLabel(context, item),
                      style: TextStyle(
                        color: _getItemColor(item),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _getFormattedTime(item),
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Text(
                _getTitle(context, item),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(12),
              // ── Detail content per type ──
              ..._buildItemDetailContent(context, item, cs, theme),
              const Gap(32),
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (item is TaskEntity)
                    _buildActionButton(
                      context: context,
                      icon: item.isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_circle_rounded,
                      label: item.isCompleted
                          ? AppLocalizations.of(context)!.undo
                          : AppLocalizations.of(context)!.complete,
                      color: item.isCompleted
                          ? cs.outline
                          : AppTheme.completedColor,
                      onPressed: () {
                        ref
                            .read(tasksRepositoryProvider)
                            .toggleTaskCompletion(item.id, item.isCompleted);
                        Navigator.pop(context);
                      },
                    ),

                  _buildActionButton(
                    context: context,
                    icon: Icons.edit_rounded,
                    label: AppLocalizations.of(context)!.edit,
                    color: AppTheme.eventColor,
                    onPressed: () {
                      Navigator.pop(context);
                      _handleEdit(context, ref, item);
                    },
                  ),

                  _buildActionButton(
                    context: context,
                    icon: Icons.delete_outline_rounded,
                    label: AppLocalizations.of(context)!.delete,
                    color: AppTheme.urgentColor,
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDelete(context, ref, item);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build detail content widgets depending on item type
  List<Widget> _buildItemDetailContent(
    BuildContext context,
    dynamic item,
    ColorScheme cs,
    ThemeData theme,
  ) {
    final localeCode = Localizations.localeOf(context).toString();
    final widgets = <Widget>[];

    if (item is TaskEntity) {
      // Date info
      if (item.date != null) {
        widgets.add(
          _buildDetailRow(
            Icons.calendar_today_rounded,
            DateFormat(
              'd MMMM yyyy, EEEE',
              localeCode,
            ).format(item.date!.toAppLocal),
            cs,
          ),
        );
        widgets.add(const Gap(8));
        widgets.add(
          _buildDetailRow(
            Icons.access_time_rounded,
            DateFormat('HH:mm', localeCode).format(item.date!.toAppLocal),
            cs,
          ),
        );
        widgets.add(const Gap(8));
      }
      // Status
      widgets.add(
        _buildDetailRow(
          item.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
          item.isCompleted ? 'Tamamlandı' : 'Devam ediyor',
          cs,
          color: item.isCompleted
              ? AppTheme.completedColor
              : AppTheme.taskColor,
        ),
      );
      if (item.isUrgent) {
        widgets.add(const Gap(8));
        widgets.add(
          _buildDetailRow(
            Icons.priority_high_rounded,
            'Acil',
            cs,
            color: AppTheme.urgentColor,
          ),
        );
      }
    } else if (item is CalendarEventEntity) {
      // Date
      widgets.add(
        _buildDetailRow(
          Icons.calendar_today_rounded,
          DateFormat(
            'd MMMM yyyy, EEEE',
            localeCode,
          ).format(item.date.toAppLocal),
          cs,
        ),
      );
      widgets.add(const Gap(8));
      // Time range
      if (item.startTime != null || item.endTime != null) {
        String timeRange = '';
        if (item.startTime != null) {
          timeRange = DateFormat('HH:mm').format(item.startTime!.toAppLocal);
        }
        if (item.endTime != null) {
          timeRange +=
              ' — ${DateFormat('HH:mm').format(item.endTime!.toAppLocal)}';
        }
        widgets.add(_buildDetailRow(Icons.access_time_rounded, timeRange, cs));
        widgets.add(const Gap(8));
      } else {
        // No specific time — show the date's time
        widgets.add(
          _buildDetailRow(
            Icons.access_time_rounded,
            DateFormat('HH:mm').format(item.date.toAppLocal),
            cs,
          ),
        );
        widgets.add(const Gap(8));
      }
    } else if (item is dc.Event) {
      // Start date
      if (item.start != null) {
        widgets.add(
          _buildDetailRow(
            Icons.calendar_today_rounded,
            DateFormat(
              'd MMMM yyyy, EEEE',
              localeCode,
            ).format(item.start!.toAppLocal),
            cs,
          ),
        );
        widgets.add(const Gap(8));
        // Time range
        String timeRange = DateFormat('HH:mm').format(item.start!.toAppLocal);
        if (item.end != null) {
          timeRange += ' — ${DateFormat('HH:mm').format(item.end!.toAppLocal)}';
        }
        widgets.add(_buildDetailRow(Icons.access_time_rounded, timeRange, cs));
        widgets.add(const Gap(8));
      }
      // All-day indicator
      if (item.allDay == true) {
        widgets.add(
          _buildDetailRow(
            Icons.wb_sunny_rounded,
            'Tüm Gün',
            cs,
            color: AppTheme.eventColor,
          ),
        );
        widgets.add(const Gap(8));
      }
      // Description
      if (item.description != null && item.description!.isNotEmpty) {
        widgets.add(const Gap(8));
        widgets.add(
          Text(
            item.description!,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        );
      }
      // Location
      if (item.location != null && item.location!.isNotEmpty) {
        widgets.add(const Gap(8));
        widgets.add(
          _buildDetailRow(Icons.location_on_rounded, item.location!, cs),
        );
      }
    } else if (item is NoteEntity) {
      if (item.audioPath != null) {
        widgets.add(AudioPlayerWidget(audioPath: item.audioPath!));
        widgets.add(const Gap(16));
      }
      widgets.add(
        Text(
          item.content,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      );
    }

    return widgets;
  }

  Widget _buildDetailRow(
    IconData icon,
    String text,
    ColorScheme cs, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? cs.onSurface.withValues(alpha: 0.5),
        ),
        const Gap(10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? cs.onSurface.withValues(alpha: 0.7),
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref, dynamic item) {
    if (item is TaskEntity) {
      final controller = TextEditingController(text: item.title);
      DateTime? selectedDate = item.date?.toAppLocal;
      DateTime? reminderTime = item.reminderTime?.toAppLocal;
      bool reminderEnabled = item.reminderEnabled;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text(AppLocalizations.of(context)!.editTask),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.taskTitleHint,
                    labelText: AppLocalizations.of(context)!.task,
                  ),
                  autofocus: true,
                ),
                const Gap(8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(AppLocalizations.of(context)!.date),
                  subtitle: Text(
                    selectedDate != null
                        ? DateFormat('d MMMM yyyy HH:mm').format(selectedDate!)
                        : AppLocalizations.of(context)!.noDate,
                  ),
                  trailing: selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => selectedDate = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          selectedDate ?? DateTime.now(),
                        ),
                      );
                      if (!context.mounted) return;
                      setState(() {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time?.hour ?? 0,
                          time?.minute ?? 0,
                        );
                      });
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.reminder),
                  value: reminderEnabled,
                  onChanged: (val) => setState(() => reminderEnabled = val),
                  secondary: Icon(
                    reminderEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: reminderEnabled ? Colors.blue : Colors.grey,
                  ),
                ),
                if (reminderEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm),
                    title: Text(AppLocalizations.of(context)!.reminderTime),
                    subtitle: Text(
                      reminderTime != null
                          ? DateFormat(
                              'd MMMM yyyy HH:mm',
                            ).format(reminderTime!)
                          : 'Seçilmedi',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            reminderTime ?? selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            reminderTime ?? selectedDate ?? DateTime.now(),
                          ),
                        );
                        if (!context.mounted) return;
                        if (time != null) {
                          setState(() {
                            reminderTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    ref
                        .read(tasksRepositoryProvider)
                        .updateTaskContent(
                          item.id,
                          controller.text,
                          selectedDate,
                          item.isUrgent,
                          reminderEnabled: reminderEnabled,
                          reminderTime: reminderTime,
                        );
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      );
    } else if (item is NoteEntity) {
      final controller = TextEditingController(text: item.content);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(AppLocalizations.of(context)!.editNote),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.noteHint,
            ),
            maxLines: 5,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref
                      .read(notesRepositoryProvider)
                      .updateNote(
                        item.id,
                        controller.text,
                        audioPath: item.audioPath,
                      );
                  Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      );
    } else if (item is CalendarEventEntity) {
      final controller = TextEditingController(text: item.title);
      DateTime selectedDate = item.date.toAppLocal;
      debugPrint(
        '📅 EDIT OPEN: item.date=${item.date} isUtc=${item.date.isUtc} → toAppLocal=$selectedDate hour=${selectedDate.hour}',
      );
      int reminderMinutes = item.reminderMinutesBefore ?? 15;
      bool reminderEnabled = item.reminderEnabled;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text(AppLocalizations.of(context)!.edit),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.eventName,
                  ),
                  autofocus: true,
                ),
                const Gap(8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(AppLocalizations.of(context)!.date),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy HH:mm').format(selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (!context.mounted) return;
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.reminder),
                  value: reminderEnabled,
                  onChanged: (val) => setState(() => reminderEnabled = val),
                  secondary: Icon(
                    reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: reminderEnabled
                        ? AppTheme.eventColor
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (reminderEnabled)
                  DropdownButtonFormField<int>(
                    initialValue: reminderMinutes,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.howManyMinutesBefore,
                      icon: const Icon(Icons.timer_outlined),
                    ),
                    items: [0, 5, 10, 15, 30, 60].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          m == 0
                              ? AppLocalizations.of(context)!.onTime
                              : AppLocalizations.of(context)!.minutesBefore(m),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => reminderMinutes = val ?? 15),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    ref
                        .read(calendarRepositoryProvider)
                        .updateEvent(
                          item.id,
                          controller.text,
                          selectedDate,
                          reminderEnabled: reminderEnabled,
                          reminderMinutesBefore: reminderMinutes,
                        );
                    debugPrint(
                      '📅 SAVE: selectedDate=$selectedDate isUtc=${selectedDate.isUtc} hour=${selectedDate.hour} minute=${selectedDate.minute}',
                    );
                    debugPrint(
                      '📅 SAVE: epoch=${selectedDate.millisecondsSinceEpoch}',
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      );
    } else if (item is dc.Event) {
      final controller = TextEditingController(text: item.title);
      DateTime selectedDate = item.start?.toAppLocal ?? DateTime.now();

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text(AppLocalizations.of(context)!.editEvent),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.title,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Tarih'),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy HH:mm').format(selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (!context.mounted) return;
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty && item.calendarId != null) {
                    await ref
                        .read(calendarSyncServiceProvider)
                        .addEventToCalendar(
                          calendarId: item.calendarId!,
                          eventId: item.eventId,
                          title: controller.text,
                          date: selectedDate,
                        );
                    // Force refresh of external events
                    ref.invalidate(calendarEventsProvider);
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
  }

  void _handleDelete(BuildContext context, WidgetRef ref, dynamic item) async {
    if (item is TaskEntity) {
      ref.read(tasksRepositoryProvider).deleteTask(item.id);
    } else if (item is NoteEntity) {
      ref.read(notesRepositoryProvider).deleteNote(item.id);
    } else if (item is CalendarEventEntity) {
      ref.read(calendarRepositoryProvider).deleteEvent(item.id);
    } else if (item is dc.Event) {
      if (item.calendarId != null) {
        await ref
            .read(calendarSyncServiceProvider)
            .deleteEvent(item.calendarId!, item.eventId);
        // Force refresh
        ref.invalidate(calendarEventsProvider);
      }
    }
  }

  String _getTypeLabel(BuildContext context, dynamic item) {
    final l10n = AppLocalizations.of(context)!;
    if (item is TaskEntity) return l10n.task;
    if (item is CalendarEventEntity) return l10n.event;
    if (item is dc.Event) return l10n.externalEvent;
    if (item is NoteEntity) return l10n.note;
    return '';
  }

  String _getTitle(BuildContext context, dynamic item) {
    if (item is TaskEntity) return item.title;
    if (item is CalendarEventEntity) return item.title;
    if (item is dc.Event) return item.title ?? '';
    if (item is NoteEntity) return AppLocalizations.of(context)!.note;
    return '';
  }

  Widget _buildOverdueWarning(BuildContext context, WidgetRef ref) {
    final overdueAsync = ref.watch(overdueTasksProvider);
    return overdueAsync.when(
      data: (overdue) {
        if (overdue.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => const OverdueTasksDialog(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.urgentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.urgentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.urgentColor,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.overdueTasksTitle(overdue.length),
                      style: const TextStyle(
                        color: AppTheme.urgentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.urgentColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildNearFutureSection(BuildContext context, WidgetRef ref) {
    final nearFutureAsync = ref.watch(nearFutureItemsProvider);
    final cs = Theme.of(context).colorScheme;

    return nearFutureAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            const Divider(),
            const Gap(16),
            GestureDetector(
              onTap: () => _showNearFutureItems(context, ref, items),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, color: cs.primary),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        "Yakın Gelecek (${items.length} Kayıt)",
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  void _showNearFutureItems(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> items,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? cs.surfaceContainerHighest : cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Yakın Gelecek Programı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildNearFutureItemCard(
                    context,
                    ref,
                    item,
                    sheetContext,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearFutureItemCard(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    BuildContext sheetContext,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get item info
    String title = '';
    String typeLabel = '';
    Color itemColor = Colors.grey;
    IconData leadingIcon = Icons.event;
    String? subtitle;
    bool isTask = false;
    bool isCompleted = false;

    if (item is TaskEntity) {
      title = item.title;
      typeLabel = 'Görev';
      isTask = true;
      isCompleted = item.isCompleted;
      itemColor = isCompleted ? AppTheme.completedColor : AppTheme.taskColor;
      leadingIcon = isCompleted
          ? Icons.check_circle_rounded
          : Icons.circle_outlined;
      if (item.date != null) {
        subtitle = DateFormat('d MMM HH:mm').format(item.date!.toAppLocal);
      }
    } else if (item is CalendarEventEntity) {
      title = item.title;
      typeLabel = 'Etkinlik';
      itemColor = AppTheme.eventColor;
      leadingIcon = Icons.event_rounded;
      subtitle = DateFormat('d MMM HH:mm').format(item.date.toAppLocal);
    } else if (item is dc.Event) {
      title = item.title ?? '';
      typeLabel = 'Takvim';
      itemColor = AppTheme.completedColor;
      leadingIcon = Icons.calendar_month_rounded;
      if (item.start != null) {
        subtitle = item.allDay == true
            ? '${DateFormat('d MMM').format(item.start!.toAppLocal)} • Tüm Gün'
            : DateFormat('d MMM HH:mm').format(item.start!.toAppLocal);
      }
    } else if (item is NoteEntity) {
      title = item.content;
      typeLabel = 'Not';
      itemColor = AppTheme.noteColor;
      leadingIcon = Icons.note_alt_outlined;
      subtitle = DateFormat('d MMM HH:mm').format(item.date.toAppLocal);
    }

    return Dismissible(
      key: Key('near_future_${item.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.urgentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_rounded,
              color: AppTheme.urgentColor,
              size: 22,
            ),
            const Gap(4),
            Text(
              'Sil',
              style: TextStyle(
                color: AppTheme.urgentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _handleDelete(context, ref, item);
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.12 : 0.2),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(sheetContext);
            _showItemDetail(context, ref, item);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Leading icon / checkbox for tasks
                if (isTask)
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(tasksRepositoryProvider)
                          .toggleTaskCompletion(
                            (item as TaskEntity).id,
                            isCompleted,
                          );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.completedColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppTheme.completedColor
                              : itemColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppTheme.completedColor,
                            )
                          : null,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(leadingIcon, color: itemColor, size: 18),
                  ),
                const Gap(12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? cs.onSurface.withValues(alpha: 0.4)
                              : cs.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const Gap(2),
                        Text(
                          '$typeLabel • $subtitle',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: itemColor,
                        ),
                      ),
                    ),
                    const Gap(8),
                    // Delete button
                    GestureDetector(
                      onTap: () => _confirmDeleteInPopup(context, ref, item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.urgentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppTheme.urgentColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteInPopup(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
  ) {
    String itemName = '';
    if (item is TaskEntity) {
      itemName = item.title;
    } else if (item is CalendarEventEntity) {
      itemName = item.title;
    } else if (item is NoteEntity) {
      itemName = item.content.length > 30
          ? '${item.content.substring(0, 30)}...'
          : item.content;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Öğeyi Sil'),
        content: Text('"$itemName" silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _handleDelete(context, ref, item);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
