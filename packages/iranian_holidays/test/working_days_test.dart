import 'package:iranian_holidays/iranian_holidays.dart';
import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  final offline = OfflineHolidaySource();

  test('isWorkingDay over a whole year', () {
    final holidays = {for (final day in offline.holidaysOf(1405)) day.date};
    for (final date in PersianDate(1405, 1, 1)
        .daysUntil(PersianDate(1405, 1, 1).lastDayOfYear)) {
      final off = holidays.contains(date) || date.weekday == DateTime.friday;
      expect(offline.isWorkingDay(date), !off, reason: '$date');
    }
    expect(offline.isWorkingDay(PersianDate(1405, 1, 13)), isFalse);
    expect(offline.isWorkingDay(PersianDate(1405, 4, 4)), isFalse); // Ashura
    expect(offline.isWorkingDay(PersianDate(1405, 1, 15)), isTrue);
    expect(offline.isWorkingDay(PersianDate.withTime(1405, 1, 15, 23)), isTrue);
  });

  test('weekend', () {
    const thursdayAndFriday = {DateTime.thursday, DateTime.friday};
    final thursday = PersianDate(1405, 1, 20);
    expect(thursday.weekday, DateTime.thursday);
    expect(offline.isWorkingDay(thursday), isTrue);
    expect(offline.isWorkingDay(thursday, weekend: thursdayAndFriday), isFalse);
    expect(
        () =>
            offline.addWorkingDays(thursday, 1, weekend: {1, 2, 3, 4, 5, 6, 7}),
        throwsArgumentError);
    // fridaysAreHolidays only changes dayOf and day, not the weekend here.
    final noFridays = OfflineHolidaySource(fridaysAreHolidays: false);
    expect(noFridays.isWorkingDay(PersianDate(1405, 1, 21)), isFalse);
    expect(noFridays.isWorkingDay(PersianDate(1405, 1, 21), weekend: const {}),
        isTrue);
  });

  test('addWorkingDays', () {
    // 1 to 4 Farvardin are Nowruz, 7 is a Friday.
    expect(offline.addWorkingDays(PersianDate(1405, 1, 1), 3),
        PersianDate(1405, 1, 8));
    expect(offline.addWorkingDays(PersianDate(1405, 1, 8), -3),
        PersianDate(1404, 12, 28));
    expect(offline.addWorkingDays(PersianDate(1405, 1, 1), 0),
        PersianDate(1405, 1, 1));
    // Across the end of the year and Nowruz.
    expect(offline.addWorkingDays(PersianDate(1404, 12, 27), 2),
        PersianDate(1405, 1, 5));
    expect(
        offline.addWorkingDays(PersianDate.withTime(1405, 1, 1, 9), 1).hasTime,
        isFalse);
  });

  test('workingDaysBetween', () {
    expect(
        offline.workingDaysBetween(
            PersianDate(1405, 1, 1), PersianDate(1405, 1, 8)),
        3);
    expect(
        offline.workingDaysBetween(
            PersianDate(1405, 1, 8), PersianDate(1404, 12, 28)),
        -3);
    expect(
        offline.workingDaysBetween(
            PersianDate(1405, 1, 8), PersianDate(1405, 1, 1)),
        -2);
    expect(
        offline.workingDaysBetween(
            PersianDate(1405, 1, 8), PersianDate(1405, 1, 8)),
        0);
    var start = PersianDate(1404, 12, 20);
    for (var i = 0; i < 40; i++, start = start.addDays(1)) {
      for (final n in [-12, -1, 1, 5, 30]) {
        final end = offline.addWorkingDays(start, n);
        expect(offline.workingDaysBetween(start, end), n,
            reason: '$start + $n');
      }
    }
  });
}
