/// Persian (Jalali, Shamsi, Khorshidi) calendar: conversion between
/// Gregorian and Jalali dates, leap years, month lengths, and formatting with
/// Persian month and weekday names.
///
/// The whole public API is the [PersianDate] class:
///
/// ```dart
/// final date = PersianDate.fromGregorian(2021, 3, 21);
/// print(date); // 1400/01/01
/// print(date.format('EEEE d MMMM yyyy')); // یکشنبه 1 فروردین 1400
/// print(PersianDate(1357, 11, 22).toDateTime()); // 1979-02-11 00:00:00.000
/// ```
library jalali_date;

import 'src/jalali_calc.dart';

/// An immutable Jalali (Persian) calendar date.
///
/// Supports Jalali -61/01/01 to 3177/10/11, which is Gregorian 560-03-20 to
/// 3798-12-31. Every constructor throws [ArgumentError] outside that range.
class PersianDate implements Comparable<PersianDate> {
  /// Jalali year, for example 1403.
  final int year;

  /// Jalali month, 1 (Farvardin) to 12 (Esfand).
  final int month;

  /// Day of the month, 1 to [monthLength].
  final int day;

  final DateTime? _dateTime;

  /// Creates a date from the current local date and time.
  factory PersianDate.now() => PersianDate.fromDateTime(DateTime.now());

  /// Creates a date from an ISO 8601 string, parsed with [DateTime.parse].
  factory PersianDate.fromGregorianString(String datetime) =>
      PersianDate.fromDateTime(DateTime.parse(datetime));

  /// Creates a date from [datetime], keeping its time of day and time zone.
  ///
  /// Throws [ArgumentError] when [datetime] is outside the supported range.
  factory PersianDate.fromDateTime(DateTime datetime) {
    final jdn = g2d(datetime.year, datetime.month, datetime.day);
    _checkRange(jdn);
    final date = d2j(jdn);
    return PersianDate._(date.jy, date.jm, date.jd, datetime);
  }

  /// Creates a date from a Gregorian year, month, and day.
  ///
  /// Out-of-range values roll over like [DateTime], so
  /// `PersianDate.fromGregorian(2021, 2, 30)` is the same day as
  /// 2021-03-02.
  factory PersianDate.fromGregorian(int year, int month, int day) =>
      PersianDate.fromDateTime(DateTime(year, month, day));

  /// Creates a date from a Jalali year, month, and day.
  ///
  /// Throws [ArgumentError] when [month] is outside 1 to 12, [day] is
  /// outside the length of that month, or the date is outside the supported
  /// range.
  PersianDate(this.year, this.month, this.day) : _dateTime = null {
    if (year < -61 || year > 3177) {
      throw ArgumentError.value(year, 'year', 'Must be in -61 to 3177');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be in 1 to 12');
    }
    final length = jalaliMonthLength(year, month);
    if (day < 1 || day > length) {
      throw ArgumentError.value(day, 'day', 'Must be in 1 to $length');
    }
    _checkRange(j2d(year, month, day));
  }

  PersianDate._(this.year, this.month, this.day, this._dateTime);

  /// Date-only instance for Julian day number [jdn], range-checked.
  factory PersianDate._fromJulianDay(int jdn) {
    _checkRange(jdn);
    final date = d2j(jdn);
    return PersianDate._(date.jy, date.jm, date.jd, null);
  }

  /// First supported date, Jalali -61/01/01 (Gregorian 560-03-20).
  static final PersianDate min = PersianDate._fromJulianDay(_firstDay);

  /// Last supported date, Jalali 3177/10/11 (Gregorian 3798-12-31).
  static final PersianDate max = PersianDate._fromJulianDay(_lastDay);

  static final _firstDay = g2d(560, 3, 20);
  static final _lastDay = g2d(3798, 12, 31);

  static void _checkRange(int jdn) {
    if (jdn < _firstDay || jdn > _lastDay) {
      throw ArgumentError(
        'Date must be in Jalali -61/01/01 to 3177/10/11 '
        '(Gregorian 560-03-20 to 3798-12-31)',
      );
    }
  }

  /// Returns a date-only copy with the given fields replaced.
  ///
  /// The result is validated like [PersianDate.new] and throws
  /// [ArgumentError] instead of clamping, so `copyWith(day: 31)` on a
  /// 30-day month throws. The time of day is dropped.
  PersianDate copyWith({int? year, int? month, int? day}) =>
      PersianDate(year ?? this.year, month ?? this.month, day ?? this.day);

  /// Returns the date [days] days later; negative values go back.
  ///
  /// The result is date-only, so the time of day is dropped. Throws
  /// [ArgumentError] when the result is outside the supported range.
  PersianDate addDays(int days) =>
      PersianDate._fromJulianDay(_julianDay + days);

  /// Returns the date [months] months later; negative values go back.
  ///
  /// The day is clamped to the length of the target month, so 1403/06/31
  /// plus one month is 1403/07/30. This differs from [DateTime], which rolls
  /// over into the next month. The result is date-only. Throws
  /// [ArgumentError] when the result is outside the supported range.
  PersianDate addMonths(int months) {
    final total = year * 12 + (month - 1) + months;
    // Dart's % is never negative, so this floors for negative totals too.
    final targetYear = (total - total % 12) ~/ 12;
    final targetMonth = total % 12 + 1;
    if (targetYear < -61 || targetYear > 3177) {
      throw ArgumentError.value(months, 'months', 'Result is out of range');
    }
    final length = jalaliMonthLength(targetYear, targetMonth);
    return PersianDate(targetYear, targetMonth, day > length ? length : day);
  }

  /// Returns the date [years] years later; negative values go back.
  ///
  /// Esfand 30 in a leap year becomes Esfand 29 when the target year is not
  /// a leap year. The result is date-only. Throws [ArgumentError] when the
  /// result is outside the supported range.
  PersianDate addYears(int years) => addMonths(years * 12);

  /// Number of days from [other] to this date, ignoring the time of day.
  ///
  /// Positive when this date is later, so
  /// `date.addDays(n).differenceInDays(date) == n`.
  int differenceInDays(PersianDate other) => _julianDay - other._julianDay;

  /// Whether [year] is a Jalali leap year, with 30 days in Esfand.
  bool get isLeapYear => isLeapJalaliYear(year);

  /// Number of days in [month] of [year].
  int get monthLength => jalaliMonthLength(year, month);

  /// Number of days in [year], 365 or 366.
  int get daysInYear => isLeapYear ? 366 : 365;

  /// Day of the year, 1 for 1 Farvardin up to [daysInYear] for the last
  /// day of Esfand.
  int get dayOfYear =>
      month <= 7 ? (month - 1) * 31 + day : 186 + (month - 7) * 30 + day;

  /// Quarter of the year, 1 to 4: months 1 to 3 are quarter 1.
  int get quarter => (month - 1) ~/ 3 + 1;

  /// Season, 1 (spring) to 4 (winter). The Jalali year starts at the March
  /// equinox, so every season is exactly three months and equals [quarter].
  int get season => quarter;

  /// Persian season names, from spring (بهار) to winter (زمستان).
  static const List<String> seasonNames = [
    'بهار',
    'تابستان',
    'پاییز',
    'زمستان'
  ];

  /// Persian name of [season], for example `بهار` for months 1 to 3.
  String get seasonName => seasonNames[season - 1];

  /// First day of this month, date-only.
  PersianDate get firstDayOfMonth => PersianDate._(year, month, 1, null);

  /// Last day of this month, date-only.
  ///
  /// Throws [ArgumentError] for Dey 3177, whose last day is past
  /// [PersianDate.max].
  PersianDate get lastDayOfMonth => PersianDate(year, month, monthLength);

  /// First day of this year (1 Farvardin), date-only.
  PersianDate get firstDayOfYear => PersianDate._(year, 1, 1, null);

  /// Last day of this year (the last day of Esfand), date-only.
  ///
  /// Throws [ArgumentError] for 3177, whose Esfand is past [PersianDate.max].
  PersianDate get lastDayOfYear => PersianDate(year, 12, isLeapYear ? 30 : 29);

  /// Returns the Gregorian [DateTime] for this date.
  ///
  /// A date created from a [DateTime] (including [PersianDate.now],
  /// [PersianDate.fromGregorian], and [PersianDate.fromGregorianString])
  /// returns that exact [DateTime], with its time and time zone. A date
  /// created from Jalali values returns local midnight of that day.
  DateTime toDateTime() {
    final dateTime = _dateTime;
    if (dateTime != null) return dateTime;
    final g = d2g(j2d(year, month, day));
    return DateTime(g.gy, g.gm, g.gd);
  }

  int get _julianDay {
    final dateTime = _dateTime;
    if (dateTime != null) {
      return g2d(dateTime.year, dateTime.month, dateTime.day);
    }
    return j2d(year, month, day);
  }

  /// Equal when [year], [month], and [day] match; the time of day is
  /// ignored.
  @override
  bool operator ==(Object other) =>
      other is PersianDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Orders dates by day; the time of day is ignored.
  @override
  int compareTo(PersianDate other) => _julianDay.compareTo(other._julianDay);

  /// Whether this date is before [other], ignoring the time of day.
  bool isBefore(PersianDate other) => compareTo(other) < 0;

  /// Whether this date is after [other], ignoring the time of day.
  bool isAfter(PersianDate other) => compareTo(other) > 0;

  /// Whether this date is the same day as [other]; the same as `==`.
  bool isSameDay(PersianDate other) => this == other;

  /// Whether this date is in the same Jalali month and year as [other].
  bool isSameMonth(PersianDate other) =>
      year == other.year && month == other.month;

  /// Whether this date is in the same Jalali year as [other].
  bool isSameYear(PersianDate other) => year == other.year;

  /// Whether this date is today in local time.
  bool get isToday => this == PersianDate.now();

  /// Whether this date is before [other]; see [compareTo].
  bool operator <(PersianDate other) => compareTo(other) < 0;

  /// Whether this date is before or the same day as [other].
  bool operator <=(PersianDate other) => compareTo(other) <= 0;

  /// Whether this date is after [other]; see [compareTo].
  bool operator >(PersianDate other) => compareTo(other) > 0;

  /// Whether this date is after or the same day as [other].
  bool operator >=(PersianDate other) => compareTo(other) >= 0;

  /// Persian month names, from Farvardin to Esfand.
  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  /// Persian weekday names, indexed by ISO weekday minus one (Monday first).
  static const List<String> weekdayNames = [
    'دوشنبه',
    'سه\u200cشنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];

  /// Persian name of [month], for example `فروردین` for month 1.
  String get monthName => monthNames[month - 1];

  /// One-letter Persian weekday names, indexed like [weekdayNames]
  /// (ISO weekday minus one, Monday first): د، س، چ، پ، ج، ش، ی.
  static const List<String> weekdayNamesShort = [
    'د',
    'س',
    'چ',
    'پ',
    'ج',
    'ش',
    'ی',
  ];

  /// ISO weekday, 1 = Monday to 7 = Sunday, the same as [DateTime.weekday].
  ///
  /// The Persian week starts on Saturday, but the number follows [DateTime]
  /// so it can be compared with [DateTime.monday] and friends directly. Use
  /// [weekdayPersian] for the Saturday-first number.
  int get weekday => _julianDay % 7 + 1;

  /// Persian weekday, 1 = Saturday to 7 = Friday.
  ///
  /// This is the column of the date in a Persian calendar grid, so the first
  /// row of a month has `firstDayOfMonth.weekdayPersian - 1` empty cells.
  int get weekdayPersian => (weekday + 1) % 7 + 1;

  /// Persian name of [weekday], for example `شنبه` for Saturday.
  String get weekdayName => weekdayNames[weekday - 1];

  /// One-letter Persian name of [weekday], for example `ش` for Saturday.
  String get weekdayNameShort => weekdayNamesShort[weekday - 1];

  /// Whether this date is a Friday, the weekly holiday in Iran.
  ///
  /// Thursday is a half working day for many offices but not a weekend, so
  /// it returns false; check [weekday] directly for other conventions.
  bool get isWeekend => weekday == DateTime.friday;

  /// Saturday of this date's Persian week, date-only.
  ///
  /// Throws [ArgumentError] when that Saturday is before [PersianDate.min].
  PersianDate startOfWeek() => addDays(1 - weekdayPersian);

  /// Friday of this date's Persian week, date-only.
  ///
  /// Throws [ArgumentError] when that Friday is after [PersianDate.max].
  PersianDate endOfWeek() => addDays(7 - weekdayPersian);

  /// Week of the year with Saturday-first weeks, 1 to 53.
  ///
  /// Week 1 is the week that contains 1 Farvardin, even when it starts in
  /// Esfand of the previous year.
  int get weekOfYear =>
      (dayOfYear - 1 + firstDayOfYear.weekdayPersian - 1) ~/ 7 + 1;

  /// Returns the date as `yyyy/MM/dd`, optionally followed by the time.
  ///
  /// The time is `HH:mm:ss`, zero-padded. [showHour], [showMinute], and
  /// [showSecond] drop the matching part and only apply when [showTime] is
  /// true.
  ///
  /// Throws [ArgumentError] when both [showDate] and [showTime] are false, or
  /// when [showTime] is true and every time part is disabled. Throws
  /// [StateError] when [showTime] is true but this instance was created from
  /// a Jalali date and therefore carries no time of day.
  @override
  String toString({
    bool showDate = true,
    bool showTime = false,
    bool showHour = true,
    bool showMinute = true,
    bool showSecond = true,
  }) {
    if (!showDate && !showTime) {
      throw ArgumentError('At least one of showDate or showTime must be true.');
    }
    if (showTime && !showHour && !showMinute && !showSecond) {
      throw ArgumentError(
        'showTime requires at least one of showHour, showMinute, or showSecond.',
      );
    }
    final parts = <String>[];
    if (showDate) {
      parts.add('$year/${_twoDigits(month)}/${_twoDigits(day)}');
    }
    if (showTime) {
      final dateTime = _dateTime;
      if (dateTime == null) {
        throw StateError(
          'Cannot show time for a PersianDate created without a Gregorian DateTime.',
        );
      }
      parts.add(
        [
          if (showHour) _twoDigits(dateTime.hour),
          if (showMinute) _twoDigits(dateTime.minute),
          if (showSecond) _twoDigits(dateTime.second),
        ].join(':'),
      );
    }
    return parts.join(' ');
  }

  static const _tokens = [
    'yyyy', 'yy', 'MMMM', 'MM', 'M', 'dd', 'd', 'EEEE', //
    'HH', 'H', 'mm', 'm', 'ss', 's',
  ];

  /// Formats this date with [pattern].
  ///
  /// | Token  | Output                          |
  /// | ------ | ------------------------------- |
  /// | `yyyy` | year, at least four digits      |
  /// | `yy`   | last two digits of the year     |
  /// | `MMMM` | Persian month name              |
  /// | `MM`   | month, two digits               |
  /// | `M`    | month                           |
  /// | `dd`   | day, two digits                 |
  /// | `d`    | day                             |
  /// | `EEEE` | Persian weekday name            |
  /// | `HH`   | hour (0 to 23), two digits      |
  /// | `H`    | hour (0 to 23)                  |
  /// | `mm`   | minute, two digits              |
  /// | `m`    | minute                          |
  /// | `ss`   | second, two digits              |
  /// | `s`    | second                          |
  ///
  /// The longest token wins, and every other character is copied as is.
  /// There is no escaping, so letters that form a token are always replaced:
  /// `format('Month')` gives `1onth`.
  /// Throws [StateError] for a time token when this instance was created
  /// from a Jalali date and therefore carries no time of day.
  String format(String pattern) {
    final out = StringBuffer();
    var i = 0;
    while (i < pattern.length) {
      final token = _tokens.firstWhere(
        (t) => pattern.startsWith(t, i),
        orElse: () => '',
      );
      if (token.isEmpty) {
        out.write(pattern[i]);
        i++;
        continue;
      }
      out.write(_formatToken(token));
      i += token.length;
    }
    return out.toString();
  }

  String _formatToken(String token) {
    switch (token) {
      case 'yyyy':
        final digits = year.abs().toString().padLeft(4, '0');
        return year < 0 ? '-$digits' : digits;
      case 'yy':
        return _twoDigits(year.remainder(100).abs());
      case 'MMMM':
        return monthName;
      case 'MM':
        return _twoDigits(month);
      case 'M':
        return '$month';
      case 'dd':
        return _twoDigits(day);
      case 'd':
        return '$day';
      case 'EEEE':
        return weekdayName;
    }
    final dateTime = _dateTime;
    if (dateTime == null) {
      throw StateError(
        'Cannot format time for a PersianDate created without a Gregorian DateTime.',
      );
    }
    final value = switch (token[0]) {
      'H' => dateTime.hour,
      'm' => dateTime.minute,
      _ => dateTime.second,
    };
    return token.length == 2 ? _twoDigits(value) : '$value';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
