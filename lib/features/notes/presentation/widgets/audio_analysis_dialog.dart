import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/audio_analysis_service.dart';
import '../../../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../../../features/calendar/presentation/providers/calendar_settings_provider.dart';
import '../../../../features/tasks/presentation/providers/task_providers.dart';
import '../../../../features/notes/presentation/providers/note_providers.dart';
import '../../../../features/settings/presentation/providers/locale_provider.dart';
import '../../../../features/settings/presentation/providers/ai_config_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../features/tasks/presentation/providers/attachment_providers.dart';
import '../../../../core/utils/date_utils.dart';

class AudioAnalysisDialog extends ConsumerStatefulWidget {
  final String? text;
  final String? audioPath;
  final bool autoStartRecording;

  const AudioAnalysisDialog({
    super.key,
    this.text,
    this.audioPath,
    this.autoStartRecording = false,
  });

  @override
  ConsumerState<AudioAnalysisDialog> createState() =>
      _AudioAnalysisDialogState();
}

class _AudioAnalysisDialogState extends ConsumerState<AudioAnalysisDialog> {
  // Service will be accessed via provider in methods

  bool _isLoading = true;
  bool _isLocal = false;
  String? _lastAnalyzedText;

  // Mutable lists for suggested items
  final List<String> _suggestedTasks = [];
  final List<AnalysisEvent> _suggestedEvents = [];
  final List<String> _suggestedNotes = [];

  // Selection state
  final Set<String> _selectedTasks = {};
  final Set<AnalysisEvent> _selectedEvents = {};
  final Set<String> _selectedNotes = {};

  // Existing items (to show duplicates/conflicts)
  final Map<String, int> _existingTasks = {}; // Title -> ID
  final Map<AnalysisEvent, int> _existingEvents = {}; // Event -> ID

  // Manual overrides
  final Map<String, AnalysisTask> _suggestedTaskObjects = {};

  @override
  void dispose() {
    // Safety check to ensure focus is cleared when dialog is closed in any way
    FocusManager.instance.primaryFocus?.unfocus();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startAnalysis(widget.text);
  }

  Future<void> _startAnalysis(String? textToAnalyze) async {
    _lastAnalyzedText = textToAnalyze;

    if (textToAnalyze == null || textToAnalyze.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // If it's a re-analysis (editing), we don't want to clear everything,
    // but the initial call needs to process the result.
    // This function is now also used for initial load.

    // Get user's language preference
    final userLocale = ref.read(localeProvider);
    final languageCode = userLocale.languageCode;
    final service = ref.read(audioAnalysisServiceProvider);

    final (result, error) = await service.analyzeText(
      textToAnalyze,
      language: languageCode,
    );
    if (mounted) {
      if (result != null) {
        setState(() {
          _isLocal = result.isLocal;
        });
        await _processAnalysisResult(result);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? AppLocalizations.of(context)!.unknownError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isSameTime(DateTime a, DateTime b) {
    // Normalizing to minute precision as requested
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  Future<bool> _isDuplicateAcrossRepos(String title, DateTime? date) async {
    if (date == null) return false;

    if (!mounted) return false;
    // Check Tasks
    final tasks = await ref
        .read(tasksRepositoryProvider)
        .findTasksByTitle(title);
    if (tasks.any((t) => t.date != null && _isSameTime(t.date!, date))) {
      return true;
    }

    if (!mounted) return false;
    // Check Events
    final events = await ref
        .read(calendarRepositoryProvider)
        .findEventsByTitle(title);
    if (events.any((e) => _isSameTime(e.date, date))) {
      return true;
    }

    if (!mounted) return false;
    // Check Notes
    final notes = await ref
        .read(notesRepositoryProvider)
        .findNotesByContent(title);

    // Notes uniqueness check: if a note has exact same content, we count as duplicate
    if (notes.any((n) => n.content.trim() == title.trim())) {
      return true;
    }

    return false;
  }

  Future<void> _processAnalysisResult(AnalysisResult result) async {
    // Selection state is cleared when starting a new analysis
    _suggestedTasks.clear();
    _suggestedEvents.clear();
    _suggestedNotes.clear();
    _selectedTasks.clear();
    _selectedEvents.clear();
    _selectedNotes.clear();
    _existingTasks.clear();
    _existingEvents.clear();

    for (var task in result.tasks) {
      if (!mounted) return;
      // Kısıtlama: Tüm başlıkları 200 karakterle sınırlıyoruz
      String safeTitle = task.title.length > 200
          ? task.title.substring(0, 200)
          : task.title;

      final isDup = await _isDuplicateAcrossRepos(safeTitle, task.date);
      if (isDup) {
        _existingTasks[safeTitle] = -1; // Marker for existing
      }
      _suggestedTasks.add(safeTitle);

      // Update object with safe title
      final safeTask = AnalysisTask(
        title: safeTitle,
        date: task.date,
        isRecurring: task.isRecurring,
        recurrencePattern: task.recurrencePattern,
        recurrenceInterval: task.recurrenceInterval,
        recurrenceDays: task.recurrenceDays,
        recurrenceEndDate: task.recurrenceEndDate,
      );
      _suggestedTaskObjects[safeTitle] = safeTask;

      if (!isDup) _selectedTasks.add(safeTitle);
    }

    for (var event in result.events) {
      if (!mounted) return;

      String safeTitle = event.title.length > 200
          ? event.title.substring(0, 200)
          : event.title;
      final safeEvent = AnalysisEvent(title: safeTitle, date: event.date);

      final isDup = await _isDuplicateAcrossRepos(safeTitle, safeEvent.date);
      if (isDup) {
        _existingEvents[safeEvent] = -1;
      }
      _suggestedEvents.add(safeEvent);
      if (!isDup) _selectedEvents.add(safeEvent);
    }

    for (var originalNote in result.notes) {
      if (!mounted) return;

      String safeNote = originalNote.length > 200
          ? originalNote.substring(0, 200)
          : originalNote;

      final isDup = await _isDuplicateAcrossRepos(safeNote, DateTime.now());
      if (isDup) {
        // Assume note string is also the key for existing
        _existingTasks[safeNote] = -1; // Use this to visually grey them out
      }
      _suggestedNotes.add(safeNote);
      if (!isDup) _selectedNotes.add(safeNote);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelected() async {
    setState(() {
      _isLoading = true;
    });

    int count = 0;
    try {
      final attachmentService = ref.read(attachmentServiceProvider);
      final audioPath = widget.audioPath;

      // Save Tasks
      final tasksRepo = ref.read(tasksRepositoryProvider);
      for (var taskTitle in _selectedTasks) {
        final taskObj = _suggestedTaskObjects[taskTitle];
        if (taskObj != null &&
            taskObj.isRecurring &&
            taskObj.recurrenceEndDate != null) {
          // EXPAND recurring tasks into individual records for finite periods
          DateTime currentDate = taskObj.date ?? DateTime.now();
          final endDate = taskObj.recurrenceEndDate!;
          final pattern = taskObj.recurrencePattern;

          int instanceCount = 0;
          // Limit to 60 days to avoid accidental massive data creation
          while (currentDate.isBefore(
                endDate.add(const Duration(seconds: 1)),
              ) &&
              instanceCount < 60) {
            bool shouldAdd = false;
            if (pattern == 'daily') {
              shouldAdd = true;
            } else if (pattern == 'weekly' && taskObj.recurrenceDays != null) {
              final weekdayName = _getWeekdayNameFromInt(currentDate.weekday);
              if (taskObj.recurrenceDays!.contains(weekdayName)) {
                shouldAdd = true;
              }
            }

            if (shouldAdd) {
              // Check for duplicate BEFORE adding in expansion loop
              if (!await _isDuplicateAcrossRepos(taskObj.title, currentDate)) {
                final id = await tasksRepo.addTask(
                  taskObj.title,
                  currentDate,
                  false,
                );
                if (audioPath != null) {
                  await attachmentService.saveAttachment(
                    taskId: id,
                    file: File(audioPath),
                  );
                }
                count++;
              }
            }

            currentDate = currentDate.add(const Duration(days: 1));
            instanceCount++;
          }
        } else if (taskObj != null) {
          // Final guard before saving a single task
          if (!await _isDuplicateAcrossRepos(taskObj.title, taskObj.date)) {
            final id = await tasksRepo.addTask(
              taskObj.title,
              taskObj.date,
              false,
              isRecurring: taskObj.isRecurring,
              recurrencePattern: taskObj.recurrencePattern,
              recurrenceInterval: taskObj.recurrenceInterval,
              recurrenceDays: taskObj.recurrenceDays,
              recurrenceEndDate: taskObj.recurrenceEndDate,
            );
            if (audioPath != null) {
              await attachmentService.saveAttachment(
                taskId: id,
                file: File(audioPath),
              );
            }
            count++;
          }
        } else {
          // Fallback for simple task strings
          if (!await _isDuplicateAcrossRepos(taskTitle, DateTime.now())) {
            final id = await tasksRepo.addTask(
              taskTitle,
              DateTime.now(),
              false,
            );
            if (audioPath != null) {
              await attachmentService.saveAttachment(
                taskId: id,
                file: File(audioPath),
              );
            }
            count++;
          }
        }
      }
      // Save Events
      final calendarRepo = ref.read(calendarRepositoryProvider);
      final syncService = ref.read(calendarSyncServiceProvider);
      final settings = ref.read(calendarSettingsProvider);

      for (var event in _selectedEvents) {
        if (event.date != null) {
          String? systemEventId;
          // System sync if enabled
          if (settings.isSyncEnabled && settings.selectedCalendarId != null) {
            systemEventId = await syncService.addEventToCalendar(
              calendarId: settings.selectedCalendarId!,
              title: event.title,
              date: event.date!,
            );
          }
          if (!await _isDuplicateAcrossRepos(event.title, event.date)) {
            // Local save with potentially returned systemEventId
            final id = await calendarRepo.addEvent(
              event.title,
              event.date!,
              systemEventId: systemEventId,
            );
            if (audioPath != null) {
              await attachmentService.saveAttachment(
                eventId: id,
                file: File(audioPath),
              );
            }
            count++;
          }
        }
      }

      // Save Notes
      final notesRepo = ref.read(notesRepositoryProvider);
      for (var note in _selectedNotes) {
        if (!await _isDuplicateAcrossRepos(note, DateTime.now())) {
          final id = await notesRepo.addNote(note);
          if (audioPath != null) {
            await attachmentService.saveAttachment(
              noteId: id,
              file: File(audioPath),
            );
          }
          count++;
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorOccurred(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        // Explicitly unfocus to prevent keyboard from popping up or input bar re-triggering
        FocusScope.of(context).unfocus();

        // Grab context-dependent resources before popping
        final messenger = ScaffoldMessenger.of(context);
        final loc = AppLocalizations.of(context)!;

        // Pop the dialog explicitly
        Navigator.pop(context);

        if (count > 0) {
          messenger.showSnackBar(
            SnackBar(content: Text(loc.itemsSavedCount(count))),
          );
        }
      }
    }
  }

  Future<void> _handleManualEdit(
    String oldItemText,
    dynamic oldItemObj,
    String type,
    String newItemText,
    DateTime? newDate, {
    AnalysisTask? task,
  }) async {
    if (!mounted) return;
    setState(() {
      // 1. Remove old item
      if (type == 'task') {
        _suggestedTasks.remove(oldItemText);
        _selectedTasks.remove(oldItemText);
        _suggestedTaskObjects.remove(oldItemText);
      } else if (type == 'event') {
        _suggestedEvents.remove(oldItemObj);
        _selectedEvents.remove(oldItemObj);
      } else if (type == 'note') {
        _suggestedNotes.remove(oldItemText);
        _selectedNotes.remove(oldItemText);
      }

      // 2. Add new item based on rules
      if (newDate != null || (type == 'task' && task != null)) {
        // It is a TASK
        _suggestedTasks.add(newItemText);
        _selectedTasks.add(newItemText);
        _suggestedTaskObjects[newItemText] =
            task ?? AnalysisTask(title: newItemText, date: newDate);
      } else {
        // It is a NOTE
        _suggestedNotes.add(newItemText);
        _selectedNotes.add(newItemText);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.updatedAndClassified),
      ),
    );
  }

  void _showEditItemDialog({
    required String currentText,
    DateTime? currentDate,
    AnalysisTask? task,
    required Function(String newItem, DateTime? newDate, AnalysisTask? newTask)
    onSave,
  }) {
    final controller = TextEditingController(text: currentText);
    DateTime? selectedDate = currentDate;

    // Recurrence state
    bool isRecurring = task?.isRecurring ?? false;
    String recurrencePattern = task?.recurrencePattern ?? 'daily';
    Set<int> selectedWeekDays = {};
    if (task?.recurrenceDays != null) {
      const dayMap = {
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7,
      };
      for (var d in task!.recurrenceDays!) {
        if (dayMap.containsKey(d)) selectedWeekDays.add(dayMap[d]!);
      }
    }
    DateTime? recurrenceEndDate = task?.recurrenceEndDate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            scrollable: true,
            title: Text(AppLocalizations.of(context)!.edit),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 200, // Enforce 200 character limit
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.descriptionHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const Gap(16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? DateFormat(
                                'd MMM y HH:mm',
                                Localizations.localeOf(context).toString(),
                              ).format(selectedDate!.toAppLocal)
                            : AppLocalizations.of(
                                context,
                              )!.noDateSelectedNoteHint,
                        style: TextStyle(
                          color: selectedDate != null
                              ? Colors.blue
                              : Colors.grey.shade600,
                          fontWeight: selectedDate != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
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
                          if (time != null) {
                            setStateDialog(() {
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
                      child: Text(AppLocalizations.of(context)!.pickDate),
                    ),
                  ],
                ),
                const Divider(),
                // Recurring Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.repeat, size: 20, color: Colors.blue),
                        Gap(8),
                        Text(
                          'Tekrarlayan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Switch(
                      value: isRecurring,
                      onChanged: (v) => setStateDialog(() => isRecurring = v),
                    ),
                  ],
                ),
                if (isRecurring) ...[
                  const Gap(8),
                  DropdownButtonFormField<String>(
                    initialValue: recurrencePattern,
                    decoration: const InputDecoration(
                      labelText: 'Tekrar Periyodu',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Günlük')),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Haftalık'),
                      ),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => recurrencePattern = v!),
                  ),
                  if (recurrencePattern == 'weekly') ...[
                    const Gap(12),
                    const Text('Günler:'),
                    const Gap(4),
                    Wrap(
                      spacing: 4,
                      children: List.generate(7, (i) {
                        final day = i + 1;
                        final isSelected = selectedWeekDays.contains(day);
                        final dayName = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][i];
                        return FilterChip(
                          label: Text(dayName),
                          selected: isSelected,
                          onSelected: (v) {
                            setStateDialog(() {
                              if (v) {
                                selectedWeekDays.add(day);
                              } else {
                                selectedWeekDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                  const Gap(12),
                  Row(
                    children: [
                      const Text('Bitiş: '),
                      Expanded(
                        child: Text(
                          recurrenceEndDate == null
                              ? 'Süresiz'
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(recurrenceEndDate!),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                recurrenceEndDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (!context.mounted) return;
                          if (date != null) {
                            setStateDialog(() => recurrenceEndDate = date);
                          }
                        },
                        child: const Text('Bitiş Seç'),
                      ),
                    ],
                  ),
                ],
                const Gap(8),
                Text(
                  AppLocalizations.of(context)!.editItemTip,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context);

                    AnalysisTask? newTask;
                    if (isRecurring || selectedDate != null) {
                      newTask = AnalysisTask(
                        title: controller.text,
                        date: selectedDate,
                        isRecurring: isRecurring,
                        recurrencePattern: recurrencePattern,
                        recurrenceEndDate: recurrenceEndDate,
                        recurrenceDays: recurrencePattern == 'weekly'
                            ? selectedWeekDays
                                  .map((d) => _getWeekdayNameFromInt(d))
                                  .toList()
                            : null,
                      );
                    }

                    onSave(controller.text, selectedDate, newTask);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Helper to build list items
    Widget buildListItem({
      required Widget title,
      Widget? subtitle,
      required bool isSelected,
      required VoidCallback onToggle,
      required VoidCallback onEdit,
      bool isExisting = false,
    }) {
      return Card(
        // Use Card for better separation
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          leading: Checkbox(
            value: isSelected,
            onChanged: isExisting ? null : (_) => onToggle(),
            activeColor: isExisting ? Colors.grey : null,
          ),
          title: title,
          subtitle:
              subtitle ??
              (isExisting
                  ? Text(
                      AppLocalizations.of(context)!.alreadyExists,
                      style: const TextStyle(color: Colors.orange),
                    )
                  : null),
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEdit,
          ),
          onTap: isExisting ? null : onToggle,
        ),
      );
    }

    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.purple),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.aiAnalysisTitle),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  Gap(16),
                  Text('Analiz ediliyor...'),
                ],
              ),
            )
          else ...[
            if (_suggestedTasks.isEmpty &&
                _suggestedEvents.isEmpty &&
                _suggestedNotes.isEmpty)
              Text(AppLocalizations.of(context)!.analysisFailedOrEmpty)
            else ...[
              if (_suggestedTasks.isNotEmpty) ...[
                _sectionHeader(
                  AppLocalizations.of(context)!.tasks,
                  Icons.check_circle_outline,
                  Colors.blue,
                ),
                ..._suggestedTasks.map((taskTitle) {
                  final exists = _existingTasks.containsKey(taskTitle);
                  final taskObj = _suggestedTaskObjects[taskTitle];
                  final taskDate = taskObj?.date;
                  final isRecurring = taskObj?.isRecurring ?? false;

                  String subtitleText = '';
                  if (taskDate != null) {
                    subtitleText = DateFormat(
                      'd MMM y HH:mm',
                      Localizations.localeOf(context).toString(),
                    ).format(taskDate.toAppLocal);
                  }
                  if (isRecurring) {
                    subtitleText +=
                        ' (Tekrarlayan: ${taskObj?.recurrencePattern})';
                  }

                  return buildListItem(
                    title: Text(
                      taskTitle,
                      style: exists
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    subtitle: subtitleText.isNotEmpty
                        ? Text(
                            subtitleText,
                            style: const TextStyle(color: Colors.blue),
                          )
                        : null,
                    isSelected: _selectedTasks.contains(taskTitle),
                    isExisting: exists,
                    onToggle: () {
                      setState(() {
                        if (_selectedTasks.contains(taskTitle)) {
                          _selectedTasks.remove(taskTitle);
                        } else {
                          _selectedTasks.add(taskTitle);
                        }
                      });
                    },
                    onEdit: () => _showEditItemDialog(
                      currentText: taskTitle,
                      currentDate: taskDate,
                      task: taskObj,
                      onSave: (newText, newDate, newTask) => _handleManualEdit(
                        taskTitle,
                        taskTitle,
                        'task',
                        newText,
                        newDate,
                        task: newTask,
                      ),
                    ),
                  );
                }),
                const Gap(8),
              ],

              if (_suggestedEvents.isNotEmpty) ...[
                _sectionHeader(
                  AppLocalizations.of(context)!.events,
                  Icons.calendar_today,
                  Colors.orange,
                ),
                ..._suggestedEvents.map((event) {
                  final exists = _existingEvents.containsKey(event);
                  return buildListItem(
                    title: Text(
                      event.title,
                      style: exists
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    subtitle: Text(
                      event.date != null
                          ? DateFormat(
                              'd MMM y HH:mm',
                              Localizations.localeOf(context).toString(),
                            ).format(event.date!.toAppLocal)
                          : AppLocalizations.of(context)!.noDate,
                    ),
                    isSelected: _selectedEvents.contains(event),
                    isExisting: exists, // Disable selection if exists
                    onToggle: () {
                      setState(() {
                        if (_selectedEvents.contains(event)) {
                          _selectedEvents.remove(event);
                        } else {
                          _selectedEvents.add(event);
                        }
                      });
                    },
                    onEdit: () => _showEditItemDialog(
                      currentText: event.title,
                      currentDate: event.date,
                      onSave: (newText, newDate, _) => _handleManualEdit(
                        event.title,
                        event,
                        'event',
                        newText,
                        newDate,
                      ),
                    ),
                  );
                }),
                const Gap(8),
              ],

              if (_suggestedNotes.isNotEmpty) ...[
                _sectionHeader(
                  AppLocalizations.of(context)!.notes,
                  Icons.note,
                  Colors.green,
                ),
                ..._suggestedNotes.map(
                  (note) => buildListItem(
                    title: Text(note),
                    isSelected: _selectedNotes.contains(note),
                    onToggle: () {
                      setState(() {
                        if (_selectedNotes.contains(note)) {
                          _selectedNotes.remove(note);
                        } else {
                          _selectedNotes.add(note);
                        }
                      });
                    },
                    onEdit: () => _showEditItemDialog(
                      currentText: note,
                      onSave: (newText, newDate, _) => _handleManualEdit(
                        note,
                        note,
                        'note',
                        newText,
                        newDate,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
      actions: _isLoading
          ? []
          : [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed:
                    (_selectedTasks.isEmpty &&
                        _selectedEvents.isEmpty &&
                        _selectedNotes.isEmpty)
                    ? null
                    : _saveSelected,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.saveSelected),
              ),
            ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _getWeekdayNameFromInt(int day) {
    const names = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return names[day] ?? '';
  }
}
