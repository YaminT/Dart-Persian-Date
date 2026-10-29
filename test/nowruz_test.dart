import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

// Moments of the March equinox announced by the Calendar Center of the
// University of Tehran, in Iran Standard Time (UTC+3:30): Gregorian year,
// month, day, hour, minute, second. From calendar.ut.ac.ir (the page of past
// years and the yearly calendars).
const _announced = [
  (1981, 3, 20, 20, 33, 31),
  (1982, 3, 21, 2, 25, 59),
  (1983, 3, 21, 8, 8, 53),
  (1984, 3, 20, 13, 54, 31),
  (1985, 3, 20, 19, 43, 56),
  (1986, 3, 21, 1, 32, 56),
  (1987, 3, 21, 7, 22, 8),
  (1988, 3, 20, 13, 8, 56),
  (1989, 3, 20, 18, 58, 29),
  (1990, 3, 21, 0, 49, 26),
  (1991, 3, 21, 6, 32, 4),
  (1992, 3, 20, 12, 18, 11),
  (1993, 3, 20, 18, 10, 50),
  (1994, 3, 20, 23, 58, 13),
  (1995, 3, 21, 5, 44, 35),
  (1996, 3, 20, 11, 33, 10),
  (1997, 3, 20, 17, 24, 46),
  (1998, 3, 20, 23, 24, 31),
  (1999, 3, 21, 5, 15, 48),
  (2000, 3, 20, 11, 5, 14),
  (2001, 3, 20, 17, 0, 40),
  (2002, 3, 20, 22, 46, 2),
  (2003, 3, 21, 4, 29, 45),
  (2004, 3, 20, 10, 18, 37),
  (2005, 3, 20, 16, 3, 24),
  (2006, 3, 20, 21, 55, 35),
  (2007, 3, 21, 3, 37, 26),
  (2008, 3, 20, 9, 18, 19),
  (2009, 3, 20, 15, 13, 39),
  (2010, 3, 20, 21, 2, 13),
  (2011, 3, 21, 2, 50, 45),
  (2012, 3, 20, 8, 44, 27),
  (2013, 3, 20, 14, 31, 56),
  (2014, 3, 20, 20, 27, 7),
  (2015, 3, 21, 2, 15, 11),
  (2016, 3, 20, 8, 0, 12),
  (2017, 3, 20, 13, 58, 40),
  (2018, 3, 20, 19, 45, 28),
  (2019, 3, 21, 1, 28, 27),
  (2020, 3, 20, 7, 19, 37),
  (2021, 3, 20, 13, 7, 28),
  (2022, 3, 20, 19, 3, 26),
  (2023, 3, 21, 0, 54, 28),
  (2024, 3, 20, 6, 36, 26),
  (2025, 3, 20, 12, 31, 30),
  (2026, 3, 20, 18, 15, 59),
];

void main() {
  test('matches the moments the University of Tehran announced', () {
    for (final (year, month, day, hour, minute, second) in _announced) {
      final announced = DateTime.utc(year, month, day, hour, minute, second)
          .subtract(const Duration(hours: 3, minutes: 30));
      final moment = PersianDate.nowruzMoment(year - 621);
      final error = moment.difference(announced).inMilliseconds.abs() / 1000;
      // The announcements before 2003 were computed with older theories and
      // are up to 40 seconds from modern ephemerides.
      expect(error, lessThan(year >= 2003 ? 4 : 45), reason: '$year');
    }
  });

  test('is UTC and inside the first days of spring', () {
    final moment = PersianDate.nowruzMoment(1405);
    expect(moment.isUtc, isTrue);
    expect(moment.month, 3);
    expect(moment.day, 20);
    expect(PersianDate.nowruzMoment(-61).year, 560);
    expect(PersianDate.nowruzMoment(3177).year, 3798);
    expect(() => PersianDate.nowruzMoment(-62), throwsArgumentError);
    expect(() => PersianDate.nowruzMoment(3178), throwsArgumentError);
  });

  test('1 Farvardin follows the noon rule from 1200 to 1699', () {
    // The year starts on the day of the equinox when it comes before noon
    // in Iran (52.5 degrees east, UTC+3:30), and on the next day otherwise.
    for (var year = 1200; year < 1700; year++) {
      final iran = PersianDate.nowruzMoment(year)
          .add(const Duration(hours: 3, minutes: 30));
      var first = DateTime.utc(iran.year, iran.month, iran.day);
      if (iran.hour >= 12) first = first.add(const Duration(days: 1));
      expect(PersianDate.fromGregorian(first.year, first.month, first.day),
          PersianDate(year, 1, 1),
          reason: '$year');
    }
  });
}
