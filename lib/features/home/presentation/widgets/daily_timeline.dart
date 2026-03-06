import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart' as dc;
import '../../../../core/utils/date_utils.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/unified_agenda_item.dart';

class DailyTimeline extends ConsumerWidget {
  final List<dynamic> items;
  final DateTime selectedDate;
  final Function(dynamic) onItemTap;

  const DailyTimeline({
    super.key,
    required this.items,
    required this.selectedDate,
    required this.onItemTap,
  });

  DateTime _getTime(dynamic item) {
    DateTime? original;

    if (item is TaskEntity) {
      original = item.date;
    } else if (item is CalendarEventEntity) {
      original = item.startTime ?? item.date;
    } else if (item is dc.Event) {
      original = item.start;
    } else if (item is NoteEntity) {
      original = item.date;
    }

    if (original == null) return DateTime(0);

    // For sorting items on a specific daily view, we must treat them as
    // occurring on the 'selectedDate' but at their original local time.
    // This fixes sorting for recurring tasks created on different dates.
    final l = original.toAppLocal;
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      l.hour,
      l.minute,
      l.second,
    );
  }

  String _getItemTitle(dynamic item) {
    if (item is TaskEntity) return item.title;
    if (item is CalendarEventEntity) return item.title;
    if (item is dc.Event) return item.title ?? '';
    if (item is NoteEntity) return 'Not';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sortedItems = List<dynamic>.from(items);

    sortedItems.sort((a, b) {
      final tA = _getTime(a);
      final tB = _getTime(b);

      final isNoneA = tA.year == 0;
      final isNoneB = tB.year == 0;

      // Put items without time (year 0) at the TOP
      if (isNoneA && !isNoneB) return -1;
      if (!isNoneA && isNoneB) return 1;
      if (isNoneA && isNoneB) {
        return _getItemTitle(a).compareTo(_getItemTitle(b));
      }

      // Normal chronological comparison
      final timeCompare = tA.compareTo(tB);
      if (timeCompare != 0) return timeCompare;

      // Tie-breaker by title
      return _getItemTitle(a).compareTo(_getItemTitle(b));
    });

    return Column(
      children: [
        // Main Header
        Row(
          children: [
            Text(
              _getHeaderTitle(context),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.timeline_rounded,
              color: cs.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
        const Gap(16),
        ...sortedItems.asMap().entries.map((entry) {
          final item = entry.value;
          final prevItem = entry.key > 0 ? sortedItems[entry.key - 1] : null;

          final currentDate = _getTime(item);
          final prevDate = prevItem != null ? _getTime(prevItem) : null;

          final bool showDateSeparator =
              prevDate == null || !isSameDay(currentDate, prevDate);

          // Don't show separator if it's the selected date (already in top header)
          final bool isSelectedDate = isSameDay(currentDate, selectedDate);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateSeparator && entry.key > 0 && !isSelectedDate) ...[
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.only(left: 57, bottom: 16),
                  child: Text(
                    _formatSeparatorDate(context, currentDate),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              _buildTimelineItem(
                context,
                item,
                isLast: entry.key == sortedItems.length - 1,
              ),
            ],
          );
        }),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatSeparatorDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) return AppLocalizations.of(context)!.today;

    final localeCode = Localizations.localeOf(context).toString();
    return DateFormat('d MMMM yyyy, EEEE', localeCode).format(date);
  }

  Widget _buildTimelineItem(
    BuildContext context,
    dynamic item, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = _getItemColor(item);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 34,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getFormattedHour(item),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(
                  _getFormattedMinute(item),
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const Gap(4),
          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? cs.surface : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          cs.outlineVariant.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const Gap(8),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () => onItemTap(item),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? cs.surfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.15 : 0.2,
                      ),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: UnifiedAgendaItem(
                    item: item,
                    compact: true,
                    showDate: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedHour(dynamic item) {
    final dt = _getTime(item);
    return dt != DateTime(0) ? DateFormat('HH').format(dt) : '--';
  }

  String _getFormattedMinute(dynamic item) {
    final dt = _getTime(item);
    return dt != DateTime(0) ? DateFormat('mm').format(dt) : '--';
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

  String _getHeaderTitle(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (isToday) return AppLocalizations.of(context)!.today;

    final localeCode = Localizations.localeOf(context).toString();
    return DateFormat('d MMMM yyyy, EEEE', localeCode).format(selectedDate);
  }
}
