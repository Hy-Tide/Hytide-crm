// lib/core/services/timezone_helper.dart
import 'package:intl/intl.dart';

/// Helper for managing and querying dates in Asia/Kolkata (IST = UTC+5:30) timezone.
class TimezoneHelper {
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Converts any [DateTime] into IST representation.
  static DateTime toIST(DateTime dt) {
    return dt.toUtc().add(istOffset);
  }

  /// Converts an IST-represented [DateTime] back to true UTC [DateTime] for Firestore storage.
  static DateTime istToUtc(DateTime istDateTime) {
    return istDateTime.subtract(istOffset);
  }

  /// Gets current [DateTime] in IST.
  static DateTime nowIST() {
    return DateTime.now().toUtc().add(istOffset);
  }

  /// Convenience alias for current time in IST.
  static DateTime now() => nowIST();

  /// Returns UTC [DateTime] representing 00:00:00.000 IST for today or a given date.
  static DateTime startOfDayUtc([DateTime? date]) {
    final ist = date != null ? toIST(date) : nowIST();
    final istMidnight = DateTime.utc(ist.year, ist.month, ist.day, 0, 0, 0, 0);
    return istMidnight.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing 23:59:59.999 IST for today or a given date.
  static DateTime endOfDayUtc([DateTime? date]) {
    final ist = date != null ? toIST(date) : nowIST();
    final istEnd = DateTime.utc(ist.year, ist.month, ist.day, 23, 59, 59, 999);
    return istEnd.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing 00:00:00.000 IST for today.
  static DateTime startOfTodayUtc() {
    final ist = nowIST();
    final istMidnight = DateTime.utc(ist.year, ist.month, ist.day, 0, 0, 0, 0);
    return istMidnight.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing 23:59:59.999 IST for today.
  static DateTime endOfTodayUtc() {
    final ist = nowIST();
    final istEnd = DateTime.utc(ist.year, ist.month, ist.day, 23, 59, 59, 999);
    return istEnd.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing 00:00:00.000 IST for tomorrow.
  static DateTime startOfTomorrowUtc() {
    final ist = nowIST().add(const Duration(days: 1));
    final istMidnight = DateTime.utc(ist.year, ist.month, ist.day, 0, 0, 0, 0);
    return istMidnight.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing 23:59:59.999 IST for tomorrow.
  static DateTime endOfTomorrowUtc() {
    final ist = nowIST().add(const Duration(days: 1));
    final istEnd = DateTime.utc(ist.year, ist.month, ist.day, 23, 59, 59, 999);
    return istEnd.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing the start of the current week (Monday 00:00:00 IST).
  static DateTime startOfWeekUtc() {
    final ist = nowIST();
    final daysFromMonday = ist.weekday - 1;
    final monday = ist.subtract(Duration(days: daysFromMonday));
    final istMondayMidnight = DateTime.utc(monday.year, monday.month, monday.day, 0, 0, 0, 0);
    return istMondayMidnight.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing the end of the current week (Sunday 23:59:59.999 IST).
  static DateTime endOfWeekUtc() {
    final ist = nowIST();
    final daysToSunday = 7 - ist.weekday;
    final sunday = ist.add(Duration(days: daysToSunday));
    final istSundayEnd = DateTime.utc(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
    return istSundayEnd.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing the start of the current month (1st 00:00:00 IST).
  static DateTime startOfMonthUtc() {
    final ist = nowIST();
    final istMonthStart = DateTime.utc(ist.year, ist.month, 1, 0, 0, 0, 0);
    return istMonthStart.subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing the end of the current month.
  static DateTime endOfMonthUtc() {
    final ist = nowIST();
    final nextMonth = ist.month == 12 ? 1 : ist.month + 1;
    final nextMonthYear = ist.month == 12 ? ist.year + 1 : ist.year;
    final istNextMonthStart = DateTime.utc(nextMonthYear, nextMonth, 1, 0, 0, 0, 0);
    return istNextMonthStart.subtract(const Duration(milliseconds: 1)).subtract(istOffset);
  }

  /// Returns UTC [DateTime] representing the start of next week (Next Monday 00:00:00 IST).
  static DateTime startOfNextWeekUtc() {
    return startOfWeekUtc().add(const Duration(days: 7));
  }

  /// Returns UTC [DateTime] representing the end of next week (Next Sunday 23:59:59.999 IST).
  static DateTime endOfNextWeekUtc() {
    return endOfWeekUtc().add(const Duration(days: 7));
  }

  /// Determines whether a given UTC [DateTime] falls on today in IST.
  static bool isTodayIST(DateTime utcDate) {
    final start = startOfTodayUtc();
    final end = endOfTodayUtc();
    return (utcDate.isAfter(start) || utcDate.isAtSameMomentAs(start)) &&
        (utcDate.isBefore(end) || utcDate.isAtSameMomentAs(end));
  }

  /// Determines whether a given UTC [DateTime] falls on tomorrow in IST.
  static bool isTomorrowIST(DateTime utcDate) {
    final start = startOfTomorrowUtc();
    final end = endOfTomorrowUtc();
    return (utcDate.isAfter(start) || utcDate.isAtSameMomentAs(start)) &&
        (utcDate.isBefore(end) || utcDate.isAtSameMomentAs(end));
  }

  /// Formats a UTC or Local DateTime into an IST string format.
  static String formatIST(DateTime dateTime, [String pattern = 'MMM d, yyyy h:mm a']) {
    final ist = toIST(dateTime);
    return DateFormat(pattern).format(ist);
  }

  /// Formats time only in IST (e.g., '10:30 AM')
  static String formatTimeIST(DateTime dateTime) {
    final ist = toIST(dateTime);
    return DateFormat('h:mm a').format(ist);
  }

  /// Formats date only in IST (e.g., 'Sep 10, 2026')
  static String formatDateIST(DateTime dateTime) {
    final ist = toIST(dateTime);
    return DateFormat('MMM d, yyyy').format(ist);
  }

  /// Generates human-friendly overdue label like "Overdue by 2 hours", "Overdue by 1 day", "Overdue by 3 days".
  static String getOverdueText(DateTime scheduledAt) {
    final diff = DateTime.now().difference(scheduledAt);
    if (diff.isNegative) return '';

    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return 'Overdue by $years ${years == 1 ? 'year' : 'years'}';
    }
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'Overdue by $months ${months == 1 ? 'month' : 'months'}';
    }
    if (diff.inDays >= 1) {
      return 'Overdue by ${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'}';
    }
    if (diff.inHours >= 1) {
      return 'Overdue by ${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'}';
    }
    if (diff.inMinutes >= 1) {
      return 'Overdue by ${diff.inMinutes} ${diff.inMinutes == 1 ? 'min' : 'mins'}';
    }
    return 'Overdue just now';
  }
}
