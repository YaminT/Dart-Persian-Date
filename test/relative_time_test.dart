import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  final today = PersianDate(1405, 8, 5);
  String rel(PersianDate date, {bool numeric = false}) =>
      date.relativeTo(today, numeric: numeric);

  group('relativeTo, calendar days', () {
    test('named days', () {
      expect(rel(today), 'امروز');
      expect(rel(PersianDate(1405, 8, 4)), 'دیروز');
      expect(rel(PersianDate(1405, 8, 3)), 'پریروز');
      expect(rel(PersianDate(1405, 8, 6)), 'فردا');
      expect(rel(PersianDate(1405, 8, 7)), 'پس‌فردا');
    });

    test('days, weeks, months, and years', () {
      expect(rel(PersianDate(1405, 8, 2)), '3 روز پیش');
      expect(rel(PersianDate(1405, 8, 8)), '3 روز دیگر');
      expect(rel(PersianDate(1405, 7, 29)), '6 روز پیش');
      expect(rel(PersianDate(1405, 7, 28)), 'هفتهٔ گذشته');
      expect(rel(PersianDate(1405, 8, 12)), 'هفتهٔ آینده');
      expect(rel(PersianDate(1405, 7, 15)), '2 هفته پیش');
      expect(rel(PersianDate(1405, 8, 26)), '3 هفته بعد');
      expect(rel(PersianDate(1405, 7, 6)), '4 هفته پیش');
      expect(rel(PersianDate(1405, 7, 5)), 'ماه گذشته');
      expect(rel(PersianDate(1405, 9, 5)), 'ماه آینده');
      expect(rel(PersianDate(1405, 2, 5)), '6 ماه پیش');
      expect(rel(PersianDate(1406, 8, 4)), '11 ماه بعد');
      expect(rel(PersianDate(1404, 8, 5)), 'سال گذشته');
      expect(rel(PersianDate(1406, 8, 5)), 'سال آینده');
      expect(rel(PersianDate(1403, 8, 5)), '2 سال پیش');
      expect(rel(PersianDate(1415, 8, 6)), '10 سال بعد');
    });

    test('numeric always writes a number', () {
      expect(rel(today, numeric: true), '0 روز دیگر');
      expect(rel(PersianDate(1405, 8, 4), numeric: true), '1 روز پیش');
      expect(rel(PersianDate(1405, 8, 6), numeric: true), '1 روز دیگر');
      expect(rel(PersianDate(1405, 7, 28), numeric: true), '1 هفته پیش');
      expect(rel(PersianDate(1405, 9, 5), numeric: true), '1 ماه بعد');
      expect(rel(PersianDate(1404, 8, 5), numeric: true), '1 سال پیش');
    });

    test('persianDigits', () {
      expect(PersianDate(1403, 8, 5).relativeTo(today, persianDigits: true),
          '۲ سال پیش');
    });

    test('a time of day on only one side counts calendar days', () {
      final evening = PersianDate.withTime(1405, 8, 4, 23, 59);
      expect(evening.relativeTo(today), 'دیروز');
      expect(today.relativeTo(evening), 'فردا');
    });
  });

  group('relativeTo, with time on both sides', () {
    final now = PersianDate.withTime(1405, 8, 5, 12, 0, 0);
    String at(int hour, [int minute = 0, int second = 0]) =>
        PersianDate.withTime(1405, 8, 5, hour, minute, second).relativeTo(now);

    test('seconds, minutes, and hours', () {
      expect(at(12), 'اکنون');
      expect(at(11, 59, 30), 'اکنون');
      expect(at(11, 59), '1 دقیقه پیش');
      expect(at(12, 5), '5 دقیقه بعد');
      expect(at(11, 0, 1), '59 دقیقه پیش');
      expect(at(10), '2 ساعت پیش');
      expect(at(23, 59), '11 ساعت بعد');
      expect(
          PersianDate.withTime(1405, 8, 5, 12, 0, 30)
              .relativeTo(now, numeric: true),
          '30 ثانیه بعد');
    });

    test('a day or more counts calendar days', () {
      final late = PersianDate.withTime(1405, 8, 5, 23, 0);
      final early = PersianDate.withTime(1405, 8, 6, 1, 0);
      expect(early.relativeTo(late), '2 ساعت بعد');
      expect(PersianDate.withTime(1405, 8, 6, 23, 0).relativeTo(late), 'فردا');
      expect(PersianDate.withTime(1405, 8, 4, 12, 0).relativeTo(now), 'دیروز');
    });
  });

  test('fromNow uses the current time', () {
    expect(PersianDate.now().fromNow(), 'اکنون');
    expect(PersianDate.now().addDays(-1).fromNow(), 'دیروز');
    expect(PersianDate.now().addDays(1).fromNow(persianDigits: true), 'فردا');
  });
}
