import 'package:flutter_test/flutter_test.dart';

/// Tests for date range calculation logic used in report_screen.dart
/// These verify the _getDateRange() logic without needing the widget.

enum ReportPeriod { daily, monthly, custom }

DateTimeRange getDateRange(DateTime selectedDate, ReportPeriod period,
    {DateTime? customStart, DateTime? customEnd}) {
  final now = selectedDate;
  switch (period) {
    case ReportPeriod.daily:
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    case ReportPeriod.monthly:
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    case ReportPeriod.custom:
      final start = customStart ?? DateTime(now.year, now.month, now.day);
      final end = customEnd ??
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      return DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
      );
  }
}

/// Simulates monthly navigation logic from report_screen.dart
DateTime navigateMonthBack(DateTime current) {
  return DateTime(current.year, current.month - 1, 1);
}

DateTime navigateMonthForward(DateTime current) {
  return DateTime(current.year, current.month + 1, 1);
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange({required this.start, required this.end});
}

void main() {
  // ── Test 3: Date Range Calculations ──
  group('Date Range Calculations', () {
    test('daily range covers full day 00:00:00.000 to 23:59:59.999', () {
      final date = DateTime(2026, 5, 14);
      final range = getDateRange(date, ReportPeriod.daily);

      expect(range.start, equals(DateTime(2026, 5, 14, 0, 0, 0, 0)));
      expect(range.end, equals(DateTime(2026, 5, 14, 23, 59, 59, 999)));
    });

    test('monthly range covers full month (start=1st, end=last day)', () {
      final date = DateTime(2026, 5, 14);
      final range = getDateRange(date, ReportPeriod.monthly);

      expect(range.start, equals(DateTime(2026, 5, 1, 0, 0, 0, 0)));
      // May has 31 days
      expect(range.end.day, equals(31));
      expect(range.end.hour, equals(23));
      expect(range.end.minute, equals(59));
    });

    test('monthly range for February (non-leap year)', () {
      final date = DateTime(2025, 2, 15);
      final range = getDateRange(date, ReportPeriod.monthly);

      expect(range.start, equals(DateTime(2025, 2, 1, 0, 0, 0, 0)));
      // Feb 2025 has 28 days
      expect(range.end.day, equals(28));
    });

    test('monthly range for February (leap year)', () {
      final date = DateTime(2024, 2, 15);
      final range = getDateRange(date, ReportPeriod.monthly);

      expect(range.start, equals(DateTime(2024, 2, 1, 0, 0, 0, 0)));
      // Feb 2024 has 29 days
      expect(range.end.day, equals(29));
    });

    test('custom range uses provided start and end dates', () {
      final date = DateTime(2026, 5, 14);
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 10);
      final range = getDateRange(date, ReportPeriod.custom,
          customStart: start, customEnd: end);

      expect(range.start, equals(DateTime(2026, 5, 1, 0, 0, 0, 0)));
      expect(range.end, equals(DateTime(2026, 5, 10, 23, 59, 59, 999)));
    });

    test('custom range defaults to today when no dates provided', () {
      final date = DateTime(2026, 5, 14);
      final range = getDateRange(date, ReportPeriod.custom);

      expect(range.start, equals(DateTime(2026, 5, 14, 0, 0, 0, 0)));
      expect(range.end, equals(DateTime(2026, 5, 14, 23, 59, 59, 999)));
    });
  });

  // ── Test 6: Monthly Navigation Regression ──
  group('Monthly Navigation (Regression - Devin Review Bug)', () {
    test('navigating back from March 31 goes to Feb 1, not Mar 2/3', () {
      final march31 = DateTime(2026, 3, 31);
      final result = navigateMonthBack(march31);

      expect(result.month, equals(2),
          reason: 'Should be February, not March (overflow)');
      expect(result.day, equals(1),
          reason: 'Should be day 1 to avoid day-of-month overflow');
    });

    test('navigating back from Jan 31 goes to Dec 1 of previous year', () {
      final jan31 = DateTime(2026, 1, 31);
      final result = navigateMonthBack(jan31);

      expect(result.year, equals(2025));
      expect(result.month, equals(12));
      expect(result.day, equals(1));
    });

    test('navigating forward from Jan 31 goes to Feb 1, not Mar 2/3', () {
      final jan31 = DateTime(2026, 1, 31);
      final result = navigateMonthForward(jan31);

      expect(result.month, equals(2),
          reason: 'Should be February, not March (overflow)');
      expect(result.day, equals(1));
    });

    test('navigating forward from Dec 31 goes to Jan 1 of next year', () {
      final dec31 = DateTime(2025, 12, 31);
      final result = navigateMonthForward(dec31);

      expect(result.year, equals(2026));
      expect(result.month, equals(1));
      expect(result.day, equals(1));
    });

    test('navigating back from Oct 31 goes to Sep 1 (not Oct 1)', () {
      final oct31 = DateTime(2026, 10, 31);
      final result = navigateMonthBack(oct31);

      expect(result.month, equals(9),
          reason: 'Should be September, not October');
      expect(result.day, equals(1));
    });
  });
}
