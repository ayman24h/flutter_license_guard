/// Utility class for date/time operations related to licenses.
class DateUtils {
  DateUtils._();

  /// Checks whether [date] is in the past.
  static bool isExpired(DateTime date) {
    return DateTime.now().isAfter(date);
  }

  /// Returns the number of days until [date].
  ///
  /// Returns a negative number if [date] is in the past.
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  /// Adds [days] to the current date and returns the result.
  static DateTime fromNow(int days) {
    return DateTime.now().add(Duration(days: days));
  }

  /// Formats a date as ISO 8601 string (date only).
  static String toIsoDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
