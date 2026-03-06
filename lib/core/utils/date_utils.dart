extension DateTimeExtension on DateTime {
  /// If UTC, convert to local. If already local, return as-is.
  DateTime get toAppLocal {
    if (isUtc) return toLocal();
    return this;
  }

  /// Same-day comparison using local time.
  bool isSameDayLocal(DateTime other) {
    final d1 = toAppLocal;
    final d2 = other.toAppLocal;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
