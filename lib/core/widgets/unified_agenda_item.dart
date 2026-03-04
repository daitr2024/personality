import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart' as dc;
import '../../config/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/notes/presentation/providers/note_providers.dart';
import '../database/app_database.dart';
import '../../features/tasks/presentation/providers/attachment_providers.dart';
import 'attachment_manager.dart';

class UnifiedAgendaItem extends ConsumerWidget {
  final dynamic item;
  final VoidCallback? onEdit;
  final bool showDate;

  const UnifiedAgendaItem({
    super.key,
    required this.item,
    this.onEdit,
    this.showDate = false,
    this.compact = false,
  });
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String title = '';
    String typeLabel = '';
    String? subtitleExtra;
    IconData leadingIcon = Icons.event;
    Color? iconColor;
    Widget? trailing;
    bool isCompleted = false;
    VoidCallback? onToggle;
    bool isUrgent = false;

    final l10n = AppLocalizations.of(context)!;

    if (item is CalendarEventEntity) {
      final event = item as CalendarEventEntity;
      title = event.title;
      typeLabel = l10n.event;
      subtitleExtra = DateFormat('HH:mm').format(event.date);
      if (showDate) {
        subtitleExtra =
            '${DateFormat('d MMM').format(event.date)} • $subtitleExtra';
      }
      leadingIcon = Icons.event_rounded;
      iconColor = AppTheme.eventColor;
      trailing = onEdit != null
          ? IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: onEdit,
            )
          : IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: () =>
                  ref.read(calendarRepositoryProvider).deleteEvent(event.id),
            );
    } else if (item is dc.Event) {
      final event = item as dc.Event;
      title = event.title ?? l10n.unnamedEvent;
      typeLabel = l10n.externalEvent;
      if (event.start != null) {
        subtitleExtra = DateFormat('HH:mm').format(event.start!);
        if (showDate) {
          subtitleExtra =
              '${DateFormat('d MMM').format(event.start!)} • $subtitleExtra';
        }
      }
      leadingIcon = Icons.sync_rounded;
      iconColor = AppTheme.completedColor;
    } else if (item is TaskEntity) {
      final task = item as TaskEntity;
      title = task.title;
      typeLabel = l10n.task;
      isCompleted = task.isCompleted;
      isUrgent = task.isUrgent;
      leadingIcon = isCompleted
          ? Icons.check_circle_rounded
          : Icons.circle_outlined;
      iconColor = isCompleted ? AppTheme.completedColor : AppTheme.taskColor;
      onToggle = () {
        ref
            .read(tasksRepositoryProvider)
            .toggleTaskCompletion(task.id, isCompleted);
      };

      if (showDate && task.date != null) {
        subtitleExtra = DateFormat('d MMM').format(task.date!);
      }

      if (onEdit != null || isUrgent) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUrgent)
              Icon(
                Icons.priority_high_rounded,
                color: AppTheme.urgentColor,
                size: 18,
              ),
            if (onEdit != null)
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
          ],
        );
      }
    } else if (item is NoteEntity) {
      final note = item as NoteEntity;
      title = note.content;
      typeLabel = l10n.note;
      if (showDate) {
        subtitleExtra = DateFormat('d MMM HH:mm').format(note.date);
      } else {
        subtitleExtra = DateFormat('HH:mm').format(note.date);
      }
      leadingIcon = Icons.note_alt_outlined;
      iconColor = AppTheme.noteColor;
      trailing = onEdit != null
          ? IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: onEdit,
            )
          : IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: () =>
                  ref.read(notesRepositoryProvider).deleteNote(note.id),
            );
    }

    final content = ListTile(
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      visualDensity: VisualDensity.compact,
      minLeadingWidth: 0,
      horizontalTitleGap: 8,
      leading: onToggle != null
          ? IconButton(
              icon: Icon(leadingIcon, color: iconColor, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onToggle,
            )
          : Container(
              padding: EdgeInsets.zero,
              child: Icon(leadingIcon, color: iconColor, size: 20),
            ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted
                    ? cs.onSurface.withValues(alpha: 0.4)
                    : cs.onSurface,
              ),
            ),
          ),
          _AttachmentBadge(item: item),
        ],
      ),
      subtitle:
          subtitleExtra != null ||
              (item is TaskEntity && (item as TaskEntity).date != null)
          ? Text(
              subtitleExtra != null ? '$typeLabel • $subtitleExtra' : typeLabel,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            )
          : null,
      trailing: trailing,
      onTap: item is CalendarEventEntity
          ? () => _showEventActionDialog(
              context,
              ref,
              item as CalendarEventEntity,
            )
          : null,
    );

    if (compact) return content;

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.1 : 0.2),
        ),
      ),
      child: content,
    );
  }

  void _showEventActionDialog(
    BuildContext context,
    WidgetRef ref,
    CalendarEventEntity event,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarih: ${DateFormat('d MMMM yyyy').format(event.date)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Saat: ${DateFormat('HH:mm').format(event.date)}',
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            AttachmentManager(itemId: event.id, source: AttachmentSource.event),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditEventDialog(context, ref, event);
            },
            icon: const Icon(Icons.edit_rounded),
            label: Text(AppLocalizations.of(context)!.edit),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ref.read(calendarRepositoryProvider).deleteEvent(event.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.eventDeleted)));
            },
            icon: Icon(Icons.delete_rounded, color: cs.error),
            label: Text('Sil', style: TextStyle(color: cs.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(
    BuildContext context,
    WidgetRef ref,
    CalendarEventEntity event,
  ) {
    DateTime selectedDate = event.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(event.date);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text(AppLocalizations.of(context)!.editEvent),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(AppLocalizations.of(context)!.date),
                subtitle: Text(DateFormat('d MMMM yyyy').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: Text(AppLocalizations.of(context)!.time),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                ref
                    .read(calendarRepositoryProvider)
                    .updateEvent(event.id, event.title, newDate);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.eventUpdated)),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentBadge extends ConsumerWidget {
  final dynamic item;

  const _AttachmentBadge({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<AttachmentEntity>>? attachmentsAsync;

    if (item is TaskEntity) {
      attachmentsAsync = ref.watch(taskAttachmentsProvider(item.id));
    } else if (item is NoteEntity) {
      attachmentsAsync = ref.watch(noteAttachmentsProvider(item.id));
    } else if (item is CalendarEventEntity) {
      attachmentsAsync = ref.watch(eventAttachmentsProvider(item.id));
    }

    if (attachmentsAsync == null) return const SizedBox.shrink();

    return attachmentsAsync.when(
      data: (attachments) {
        if (attachments.isEmpty) return const SizedBox.shrink();

        final hasAudio = attachments.any((a) => a.fileType == 'audio');
        final hasImage = attachments.any((a) => a.fileType == 'image');

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAudio)
              const Icon(Icons.mic_none_rounded, size: 14, color: Colors.blue),
            if (hasAudio && hasImage) const SizedBox(width: 2),
            if (hasImage)
              const Icon(Icons.image_outlined, size: 14, color: Colors.orange),
            if (!hasAudio && !hasImage)
              const Icon(
                Icons.attach_file_rounded,
                size: 14,
                color: Colors.grey,
              ),
            const SizedBox(width: 4),
            Text(
              '${attachments.length}',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
