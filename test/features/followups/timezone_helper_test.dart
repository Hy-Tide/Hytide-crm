// test/features/followups/timezone_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/services/timezone_helper.dart';

void main() {
  group('TimezoneHelper Tests (Asia/Kolkata UTC+5:30)', () {
    test('toIST adds 5 hours 30 minutes to UTC', () {
      final utc = DateTime.utc(2026, 9, 10, 10, 0); // 10:00 UTC
      final ist = TimezoneHelper.toIST(utc);
      expect(ist.hour, equals(15));
      expect(ist.minute, equals(30));
    });

    test('istToUtc subtracts 5 hours 30 minutes from IST', () {
      final ist = DateTime.utc(2026, 9, 10, 15, 30);
      final utc = TimezoneHelper.istToUtc(ist);
      expect(utc.hour, equals(10));
      expect(utc.minute, equals(0));
    });

    test('startOfTodayUtc and endOfTodayUtc span exactly 24 hours minus 1 ms', () {
      final start = TimezoneHelper.startOfTodayUtc();
      final end = TimezoneHelper.endOfTodayUtc();

      final diff = end.difference(start);
      expect(diff.inHours, equals(23));
      expect(diff.inMinutes, equals(1439));
      expect(diff.inSeconds, equals(86399));
    });

    test('startOfTomorrowUtc is after endOfTodayUtc', () {
      final endToday = TimezoneHelper.endOfTodayUtc();
      final startTomorrow = TimezoneHelper.startOfTomorrowUtc();

      expect(startTomorrow.isAfter(endToday), isTrue);
    });

    test('isTodayIST correctly matches a time scheduled in IST today', () {
      final nowIst = TimezoneHelper.nowIST();
      // Midday today in IST converted to UTC
      final middayIstAsUtc = DateTime.utc(nowIst.year, nowIst.month, nowIst.day, 12, 0)
          .subtract(TimezoneHelper.istOffset);

      expect(TimezoneHelper.isTodayIST(middayIstAsUtc), isTrue);
    });
  });
}
