class BookingSchedule {
  const BookingSchedule._();

  static DateTime? startAt(DateTime? date, String? time) {
    if (date == null || time == null) return null;
    final cleanTime = time.trim();
    if (cleanTime.contains('T')) {
      return DateTime.tryParse(cleanTime)?.toLocal();
    }
    final parts = cleanTime.split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length == 3 ? double.tryParse(parts[2]) : 0.0;
    if (hour == null ||
        hour < 0 ||
        hour > 23 ||
        minute == null ||
        minute < 0 ||
        minute > 59 ||
        second == null ||
        !second.isFinite ||
        second < 0 ||
        second >= 60) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      second.toInt(),
    );
  }

  static bool canStart(DateTime? start, DateTime now) =>
      start != null &&
      !now.isBefore(start.subtract(const Duration(minutes: 15)));
}
