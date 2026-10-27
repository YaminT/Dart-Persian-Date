import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  PersianDate at(int hour, [int minute = 0]) =>
      PersianDate.withTime(1403, 1, 4, hour, minute);

  test('dayPeriod follows the CLDR hours', () {
    const expected = {
      0: 'نیمه‌شب', 1: 'بامداد', 3: 'بامداد', 4: 'صبح', 11: 'صبح', //
      12: 'ظهر', 13: 'عصر', 18: 'عصر', 19: 'شب', 23: 'شب',
    };
    expected.forEach((hour, name) {
      expect(at(hour).dayPeriod, name, reason: '$hour');
      expect(at(hour, 59).dayPeriod, name, reason: '$hour:59');
    });
  });

  test('B and BBBB tokens', () {
    expect(at(8).format('h B'), '8 صبح');
    expect(at(16).format('h B'), '4 عصر');
    expect(at(23).format('h B'), '11 شب');
    expect(at(12, 30).format('h:mm B'), '12:30 ظهر');
    expect(at(12, 30).format('h:mm BBBB'), '12:30 بعدازظهر');
    expect(at(2).format('h BBBB'), '2 بامداد');
    expect(at(0, 15).format('h:mm B'), '12:15 نیمه‌شب');
    expect(at(8).format("h 'B'"), '8 B');
  });

  test('date-only throws', () {
    expect(() => PersianDate(1403, 1, 4).dayPeriod, throwsStateError);
    expect(() => PersianDate(1403, 1, 4).format('B'), throwsStateError);
  });
}
