// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/task_providers.dart';
import '../providers/recurring_task_providers.dart';
import '../../../../core/services/recurring_task_service.dart';

class NewTaskPage extends ConsumerStatefulWidget {
  const NewTaskPage({super.key});

  @override
  ConsumerState<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends ConsumerState<NewTaskPage> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _routineTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isUrgent = false;
  DateTime? _reminderTime;
  bool _reminderEnabled = false;

  // Recurring task fields
  bool _isRecurring = false;
  DateTime? _recurrenceStartDate;
  RecurrencePattern _recurrencePattern = RecurrencePattern.daily;
  final int _customInterval = 1;
  final Set<int> _selectedWeekDays = {}; // 1=Mon, 7=Sun
  DateTime? _recurrenceEndDate;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day); // Start of today

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5), // 5 years future
    );

    if (picked != null && mounted) {
      // Also pick time for precise timestamp
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterTitle)),
      );
      return;
    }

    if (_isRecurring) {
      // Create recurring task
      final baseDate = _recurrenceStartDate ?? DateTime.now();
      final finalStartDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        _routineTime?.hour ?? 9,
        _routineTime?.minute ?? 0,
      );

      await ref
          .read(recurringTaskServiceProvider)
          .createRecurringTask(
            title: _titleController.text,
            startDate: finalStartDate,
            pattern: _recurrencePattern,
            isUrgent: _isUrgent,
            customInterval: _recurrencePattern == RecurrencePattern.custom
                ? _customInterval
                : null,
            weeklyDays: _recurrencePattern == RecurrencePattern.weekly
                ? _selectedWeekDays.toList()
                : null,
            endDate: _recurrenceEndDate,
            reminderTime: _reminderEnabled ? _reminderTime : null,
            reminderEnabled: _reminderEnabled,
          );
    } else {
      // Create regular task
      await ref
          .read(tasksRepositoryProvider)
          .addTask(
            _titleController.text,
            _selectedDate,
            _isUrgent,
            reminderTime: _reminderEnabled ? _reminderTime : null,
            reminderEnabled: _reminderEnabled,
          );
    }

    if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _pickReminderTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectEndDateFirst),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? now,
      firstDate: now,
      lastDate: _selectedDate!,
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _reminderTime != null
            ? TimeOfDay.fromDateTime(_reminderTime!)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _reminderTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          _reminderEnabled = true;
        });
      }
    }
  }

  Future<void> _pickRecurrenceEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  String _getPatternLabel(RecurrencePattern p) {
    final loc = AppLocalizations.of(context)!;
    switch (p) {
      case RecurrencePattern.daily:
        return loc.daily;
      case RecurrencePattern.weekly:
        return loc.weekly;
      case RecurrencePattern.monthly:
        return loc.recurring;
      case RecurrencePattern.custom:
        return loc.categoryOther;
    }
  }

  String _getShortDayName(int day) {
    const days = ['Pzt', 'Sal', 'Çar', 'Pş', 'Cum', 'Cmt', 'Paz'];
    return days[day - 1];
  }

  Future<void> _pickRecurrenceStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceStartDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _recurrenceStartDate = picked;
      });
    }
  }

  Future<void> _pickRoutineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _routineTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _routineTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.newTaskTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              context,
              AppLocalizations.of(context)!.taskTitleHint,
              'Rapor Hazırlığı',
              _titleController,
            ),
            const Gap(24),
            if (!_isRecurring) ...[
              Text(
                AppLocalizations.of(context)!.date,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Gap(12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const Gap(12),
                      Text(
                        _selectedDate == null
                            ? AppLocalizations.of(context)!.pickDate
                            : DateFormat(
                                'dd MMMM yyyy HH:mm',
                                Localizations.localeOf(context).toString(),
                              ).format(_selectedDate!),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Gap(24),
            Row(
              children: [
                Checkbox(
                  value: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v!),
                ),
                Text(
                  AppLocalizations.of(context)!.urgentTask,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Gap(24),
            // Reminder Section
            Text(
              AppLocalizations.of(context)!.reminder,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Gap(12),
            Row(
              children: [
                Checkbox(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v!),
                ),
                Text(
                  AppLocalizations.of(context)!.reminderActive,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (_reminderEnabled) const Gap(12),
            if (_reminderEnabled)
              InkWell(
                onTap: _pickReminderTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.orange,
                      ),
                      const Gap(12),
                      Text(
                        _reminderTime == null
                            ? AppLocalizations.of(context)!.reminderTime
                            : DateFormat(
                                'dd MMMM yyyy HH:mm',
                                Localizations.localeOf(context).toString(),
                              ).format(_reminderTime!),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const Gap(24),
            // Recurring Task Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.repeat, color: Colors.blue),
                          const Gap(12),
                          Text(
                            AppLocalizations.of(context)!.recurring,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const Divider(height: 24),
                    Text(AppLocalizations.of(context)!.recurrenceInterval),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      children: RecurrencePattern.values.map((p) {
                        return ChoiceChip(
                          label: Text(_getPatternLabel(p)),
                          selected: _recurrencePattern == p,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _recurrencePattern = p);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    if (_recurrencePattern == RecurrencePattern.weekly) ...[
                      const Gap(16),
                      Text(AppLocalizations.of(context)!.whichDays),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final isSelected = _selectedWeekDays.contains(day);
                          return FilterChip(
                            label: Text(_getShortDayName(day)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWeekDays.add(day);
                                } else {
                                  _selectedWeekDays.remove(day);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.startDate),
                              const Gap(8),
                              InkWell(
                                onTap: _pickRecurrenceStartDate,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        size: 18,
                                      ),
                                      const Gap(8),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(
                                          _recurrenceStartDate ??
                                              DateTime.now(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.routineTime),
                              const Gap(8),
                              InkWell(
                                onTap: _pickRoutineTime,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 18),
                                      const Gap(8),
                                      Text(_routineTime?.format(context) ?? ''),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Text(AppLocalizations.of(context)!.endDateOptional),
                    const Gap(8),
                    InkWell(
                      onTap: _pickRecurrenceEndDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_note, size: 18),
                            const Gap(8),
                            Text(
                              _recurrenceEndDate == null
                                  ? AppLocalizations.of(context)!.endNone
                                  : DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(_recurrenceEndDate!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(24),

            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
