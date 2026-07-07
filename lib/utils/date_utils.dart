// lib/utils/date_utils.dart
import 'package:flutter/material.dart';

class DateUtilsHelper {
  // ============================================================
  // RANGE
  // ============================================================

  static DateTimeRange getLastDays(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange getLastWeeks(int weeks) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: weeks * 7));
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange getLastMonths(int months) {
    final end = DateTime.now();
    final start = DateTime(end.year, end.month - months, end.day);
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange getCurrentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange getCurrentYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31);
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange getCustomRange(DateTime start, DateTime end) {
    return DateTimeRange(start: start, end: end);
  }

  // ============================================================
  // COMPARISON
  // ============================================================

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static bool isSameYear(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  static bool isInRange(DateTime date, DateTimeRange range) {
    return date.isAfter(range.start) && date.isBefore(range.end);
  }

  // ============================================================
  // GENERATION
  // ============================================================

  static List<DateTime> getDaysInMonth(int year, int month) {
    final days = <DateTime>[];
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    for (int i = 0; i < lastDay.day; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    return days;
  }

  static List<DateTime> getWeeksInMonth(int year, int month) {
    final days = getDaysInMonth(year, month);
    final weeks = <DateTime>[];
    final firstDayOfWeek = days.first.weekday;
    
    // Get first day of first week
    DateTime start = days.first.subtract(Duration(days: firstDayOfWeek - 1));
    
    while (start.isBefore(days.last)) {
      weeks.add(start);
      start = start.add(const Duration(days: 7));
    }
    return weeks;
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  static String formatDate(DateTime date, {String separator = '/'}) {
    return '${date.day}$separator${date.month}$separator${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static String getShortMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  static String getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  static String getShortDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays.abs();
  }

  static int monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  static int yearsBetween(DateTime start, DateTime end) {
    return end.year - start.year;
  }
}
