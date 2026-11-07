class DateFormatter {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Formats DateTime to "18 Oct 2026, 6:30 PM"
  static String format(DateTime date) {
    final day = date.day;
    final month = _months[date.month - 1];
    final year = date.year;

    int hour = date.hour;
    final isPm = hour >= 12;
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = isPm ? 'PM' : 'AM';

    return '$day $month $year, $hour:$minute $period';
  }

  /// Formats DateTime to "18 Oct 2026"
  static String formatShort(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}
