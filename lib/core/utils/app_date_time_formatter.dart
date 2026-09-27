import 'package:easy_localization/easy_localization.dart';

/// Centralized Date and Time Formatter utility for the entire application.
/// Enforces 12-hour clock (hh:mm a) with AM/PM across all screens and widgets.
class AppDateTimeFormatter {
  AppDateTimeFormatter._();

  /// Format time in 12-hour format with AM/PM (e.g. "09:30 AM" or "09:30 ص")
  static String formatTime(DateTime? dateTime, {String fallback = '--:--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('hh:mm a').format(dateTime.toLocal());
  }

  /// Format raw time string like "14:30:00" to 12-hour format ("02:30 PM")
  static String formatTimeString(String? timeStr, {String fallback = '--:--'}) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr == 'null') return fallback;
    try {
      final clean = timeStr.trim();
      final parts = clean.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, hour, minute);
        return formatTime(dt, fallback: fallback);
      }
    } catch (_) {}
    return timeStr;
  }

  /// Format full date (e.g. "2026-09-27")
  static String formatDate(DateTime? dateTime, {String pattern = 'yyyy-MM-dd', String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat(pattern).format(dateTime.toLocal());
  }

  /// Format short date with month name (e.g. "Sep 27")
  static String formatShortDate(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('MMM dd').format(dateTime.toLocal());
  }

  /// Format full date & 12-hour time (e.g. "2026-09-27 09:30 AM")
  static String formatDateTime(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime.toLocal());
  }

  /// Format date and time with slash separators (e.g. "2026/09/27 - 09:30 AM")
  static String formatDateTimeSlash(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dateTime.toLocal());
  }

  /// Format full date time with seconds (e.g. "2026/09/27 09:30:15 AM")
  static String formatDateTimeWithSeconds(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('yyyy/MM/dd hh:mm:ss a').format(dateTime.toLocal());
  }

  /// Format month and year (e.g. "September 2026")
  static String formatMonthYear(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('MMMM yyyy').format(dateTime.toLocal());
  }

  /// Format day of week, date and time (e.g. "Sun, Sep 27, 2026 09:30 AM")
  static String formatFullHeaderDate(DateTime? dateTime, {String fallback = '--'}) {
    if (dateTime == null) return fallback;
    return DateFormat('EEE, MMM dd, yyyy • hh:mm a').format(dateTime.toLocal());
  }
}

extension DateTimeFormatExtension on DateTime {
  String toTimeStr({String fallback = '--:--'}) => AppDateTimeFormatter.formatTime(this, fallback: fallback);
  String toDateStr({String pattern = 'yyyy-MM-dd', String fallback = '--'}) => AppDateTimeFormatter.formatDate(this, pattern: pattern, fallback: fallback);
  String toDateTimeStr({String fallback = '--'}) => AppDateTimeFormatter.formatDateTime(this, fallback: fallback);
  String toDateTimeSlashStr({String fallback = '--'}) => AppDateTimeFormatter.formatDateTimeSlash(this, fallback: fallback);
}
