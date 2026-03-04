import 'dart:async';
import 'package:flutter/material.dart';

/// Widget that displays a countdown timer for tasks with upcoming due dates
class TaskCountdown extends StatefulWidget {
  final DateTime dueDate;
  final TextStyle? textStyle;

  const TaskCountdown({super.key, required this.dueDate, this.textStyle});

  @override
  State<TaskCountdown> createState() => _TaskCountdownState();
}

class _TaskCountdownState extends State<TaskCountdown> {
  Timer? _timer;
  String _countdownText = '';
  Color _countdownColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (context.mounted) {
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final remaining = widget.dueDate.difference(now);

    setState(() {
      if (remaining.isNegative) {
        _countdownText = 'Süresi doldu';
        _countdownColor = Colors.red;
      } else if (remaining.inHours > 24) {
        // Don't show countdown for tasks more than 24 hours away
        _countdownText = '';
        _countdownColor = Colors.grey;
      } else if (remaining.inHours >= 1) {
        _countdownText = '${remaining.inHours} sa kaldı';
        // Color coding based on urgency
        if (remaining.inHours < 1) {
          _countdownColor = Colors.red; // < 1 hour
        } else if (remaining.inHours < 6) {
          _countdownColor = Colors.orange; // < 6 hours
        } else {
          _countdownColor = Colors.amber; // < 24 hours
        }
      } else if (remaining.inMinutes > 0) {
        _countdownText = '${remaining.inMinutes} dk kaldı';
        _countdownColor = Colors.red;
      } else {
        _countdownText = 'Az kaldı';
        _countdownColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_countdownText.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _countdownColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _countdownColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 12, color: _countdownColor),
              const SizedBox(width: 4),
              Text(
                _countdownText,
                maxLines: 1,
                style: (widget.textStyle ?? const TextStyle(fontSize: 10.5))
                    .copyWith(
                      color: _countdownColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to check if a task should show countdown
bool shouldShowCountdown(DateTime dueDate) {
  final now = DateTime.now();
  final remaining = dueDate.difference(now);
  return remaining.inHours <= 24 && !remaining.isNegative;
}

/// Helper function to get countdown color
Color getCountdownColor(DateTime dueDate) {
  final now = DateTime.now();
  final remaining = dueDate.difference(now);

  if (remaining.isNegative) {
    return Colors.red;
  } else if (remaining.inHours < 1) {
    return Colors.red;
  } else if (remaining.inHours < 6) {
    return Colors.orange;
  } else if (remaining.inHours <= 24) {
    return Colors.amber;
  }
  return Colors.grey;
}




