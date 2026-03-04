import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/dashboard_providers.dart';

class TwoWeekCalendarBar extends ConsumerStatefulWidget {
  const TwoWeekCalendarBar({super.key});

  @override
  ConsumerState<TwoWeekCalendarBar> createState() => _TwoWeekCalendarBarState();
}

class _TwoWeekCalendarBarState extends ConsumerState<TwoWeekCalendarBar> {
  late PageController _pageController;
  late DateTime _today;
  late DateTime _initialDate;
  final int _initialPage = 500;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _today = DateTime(_today.year, _today.month, _today.day);

    // Start of the current week (Monday)
    _initialDate = _today.subtract(Duration(days: _today.weekday - 1));

    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetCalendar() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _initialPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
      );
    }
    ref.read(selectedDateProvider.notifier).updateDate(_today);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isVisible = ref.watch(calendarVisibilityProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Month/Year and navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    final becomingHidden = ref.read(calendarVisibilityProvider);
                    ref.read(calendarVisibilityProvider.notifier).toggle();
                    if (becomingHidden) {
                      _resetCalendar();
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        DateFormat(
                          'd MMMM yyyy',
                          Localizations.localeOf(context).toString(),
                        ).format(selectedDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      Icon(
                        isVisible ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: isVisible
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _NavButton(
                      icon: Icons.history_rounded,
                      tooltip: 'Bugüne Dön',
                      onPressed: _resetCalendar,
                    ),
                    const Gap(8),
                    _NavButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () {
                        final newDate = selectedDate.subtract(
                          const Duration(days: 1),
                        );
                        ref
                            .read(selectedDateProvider.notifier)
                            .updateDate(newDate);

                        final pageOfNewDate =
                            _initialPage +
                            ((newDate.difference(_initialDate).inDays) / 14)
                                .floor();
                        if (_pageController.hasClients &&
                            _pageController.page?.round() != pageOfNewDate) {
                          _pageController.animateToPage(
                            pageOfNewDate,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                    const Gap(4),
                    _NavButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: () {
                        final newDate = selectedDate.add(
                          const Duration(days: 1),
                        );
                        ref
                            .read(selectedDateProvider.notifier)
                            .updateDate(newDate);

                        final pageOfNewDate =
                            _initialPage +
                            ((newDate.difference(_initialDate).inDays) / 14)
                                .floor();
                        if (_pageController.hasClients &&
                            _pageController.page?.round() != pageOfNewDate) {
                          _pageController.animateToPage(
                            pageOfNewDate,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isVisible) ...[
            const Gap(12),
            // PageView for 2-week blocks
            SizedBox(
              height: 125,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  final pageOffset = index - _initialPage;
                  final pageStartDate = _initialDate.add(
                    Duration(days: pageOffset * 14),
                  );
                  return _buildTwoWeekGrid(pageStartDate, selectedDate);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwoWeekGrid(DateTime startDate, DateTime selectedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85,
        ),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          return _buildDateItem(date, selectedDate);
        },
      ),
    );
  }

  Widget _buildDateItem(DateTime date, DateTime selectedDate) {
    final isSelected = isSameDay(date, selectedDate);
    final isToday = isSameDay(date, _today);
    final itemsTypes = ref.watch(dayItemsTypeProvider(date));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).updateDate(date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : isToday
              ? cs.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: cs.primary.withValues(alpha: 0.3))
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat(
                'E',
                Localizations.localeOf(context).toString(),
              ).format(date)[0],
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? cs.onPrimary.withValues(alpha: 0.7)
                    : cs.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(2),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? cs.onPrimary : cs.onSurface,
              ),
            ),
            const Gap(4),
            // Dots for Tasks, Events, Notes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (itemsTypes.contains(ItemType.task))
                  _buildDot(AppTheme.taskColor, isSelected, cs),
                if (itemsTypes.contains(ItemType.event))
                  _buildDot(AppTheme.eventColor, isSelected, cs),
                if (itemsTypes.contains(ItemType.note))
                  _buildDot(AppTheme.noteColor, isSelected, cs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color, bool isSelected, ColorScheme cs) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isSelected ? cs.onPrimary.withValues(alpha: 0.9) : color,
        shape: BoxShape.circle,
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;

  const _NavButton({required this.icon, this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
