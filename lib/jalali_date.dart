/// Persian (Jalali, Shamsi, Khorshidi) calendar: conversion between
/// Gregorian and Jalali dates, leap years, month lengths, and formatting with
/// Persian month and weekday names.
///
/// The main type is the immutable [PersianDate]. [PersianDateRange] holds an
/// inclusive range of days, [toPersianDigits] and [toLatinDigits] convert
/// digits, [JalaliEra] picks Solar Hijri or Shahanshahi year numbers for
/// text, [HijriDate] and [IranianHijri] give the lunar Hijri date as Iran's
/// official calendar counts it, and `DateTime.toPersianDate()` and
/// `DateTime.toHijriDate()` convert a [DateTime].
///
/// ```dart
/// final date = PersianDate.fromGregorian(2021, 3, 21);
/// print(date); // 1400/01/01
/// print(date.format('EEEE d MMMM yyyy')); // یکشنبه 1 فروردین 1400
/// print(date.addMonths(1).toString(persianDigits: true)); // ۱۴۰۰/۰۲/۰۱
/// print(PersianDate.parse('1357/11/22').toDateTime()); // 1979-02-11 00:00:00.000
/// ```
library jalali_date;

import 'src/digits.dart';
import 'src/era.dart';
import 'src/hijri.dart';
import 'src/jalali_calc.dart';
import 'src/nowruz.dart';
import 'src/parse_format.dart';
import 'src/pattern.dart';
import 'src/relative_time.dart';
import 'src/words.dart';

export 'src/digits.dart';
export 'src/era.dart';
export 'src/hijri.dart';
export 'src/persian_date_range.dart';
export 'src/words.dart';

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

  /// Creates a date from Jalali values with a local time of day.
  ///
  /// The date is validated like [PersianDate.new]. Throws [ArgumentError]
  /// when [hour] is outside 0 to 23, or [minute] or [second] is outside
  /// 0 to 59, and when that wall-clock time does not exist in the local
  /// time zone because of a daylight saving change. The result carries a
  /// local [DateTime], so [hasTime] is true and [toDateTime] returns that
  /// moment.
  factory PersianDate.withTime(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    final date = PersianDate(year, month, day);
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Must be in 0 to 23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'Must be in 0 to 59');
    }
    if (second < 0 || second > 59) {
      throw ArgumentError.value(second, 'second', 'Must be in 0 to 59');
    }
    final g = d2g(date._julianDay);
    final dateTime = DateTime(g.gy, g.gm, g.gd, hour, minute, second);
    if (dateTime.day != g.gd ||
        dateTime.hour != hour ||
        dateTime.minute != minute) {
      throw ArgumentError(
        '$date $hour:$minute does not exist in the local time zone',
      );
    }
    return PersianDate._(year, month, day, dateTime);
  }

  PersianDate._(this.year, this.month, this.day, this._dateTime);

  static final _parsePattern = RegExp(
    r'^\s*(-?\d{1,4})([/-])(\d{1,2})\2(\d{1,2})'
    r'(?:[ T](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?\s*$',
  );

  /// Parses a Jalali date such as `1403/01/01`, `1403-1-1`, or
  /// `۱۴۰۳/۰۱/۰۱ ۱۴:۳۰`.
  ///
  /// Accepts `/` or `-` between year, month, and day (the same one twice),
  /// an optional time of
  /// `HH:mm` or `HH:mm:ss` after a space or `T`, and ASCII, Persian, or
  /// Arabic-Indic digits. With a time the result is a local
  /// [PersianDate.withTime]; without one it is date-only like
  /// [PersianDate.new].
  ///
  /// The year is read in [era], so with [JalaliEra.shahanshahi] `2585/01/01`
  /// is Solar Hijri 1405/01/01.
  ///
  /// Throws [FormatException] when [input] does not match or is not a valid
  /// date, like [DateTime.parse].
  static PersianDate parse(String input,
      {JalaliEra era = JalaliEra.solarHijri}) {
    final match = _parsePattern.firstMatch(toLatinDigits(input));
    if (match == null) {
      throw FormatException('Invalid Jalali date', input);
    }
    int part(int group) => int.parse(match.group(group)!);
    final firstYear = -61 + era.offset;
    final lastYear = 3177 + era.offset;
    if (part(1) < firstYear || part(1) > lastYear) {
      throw FormatException(
        'Invalid Jalali date: year must be in $firstYear to $lastYear',
        input,
      );
    }
    final year = part(1) - era.offset;
    try {
      if (match.group(5) == null) {
        return PersianDate(year, part(3), part(4));
      }
      return PersianDate.withTime(
        year,
        part(3),
        part(4),
        part(5),
        part(6),
        match.group(7) == null ? 0 : part(7),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid Jalali date: ${error.message}', input);
    }
  }

  /// Creates a date from the `yyyy-MM-dd` string written by [toJson].
  ///
  /// Accepts everything [parse] accepts and throws [FormatException] for
  /// invalid input. `json_serializable` uses it, together with [toJson], for
  /// `PersianDate` fields without any annotation.
  factory PersianDate.fromJson(String json) => parse(json);

  /// Like [parse], but returns null instead of throwing.
  static PersianDate? tryParse(String input,
      {JalaliEra era = JalaliEra.solarHijri}) {
    try {
      return parse(input, era: era);
    } on FormatException {
      return null;
    }
  }

  /// Parses [input] written with [pattern], the reverse of [format]:
  /// `PersianDate.parseFormat('۴ فروردین ۱۴۰۳', 'd MMMM yyyy')` is
  /// 1403/01/04.
  ///
  /// [pattern] uses the tokens and quoting of [format] and needs `yyyy`, a
  /// month (`MMMM`, `MM`, or `M`), and a day (`dd` or `d`). `MM`, `dd`, `HH`,
  /// `hh`, `mm`, and `ss` need two digits, so `yyyyMMdd` works; `M`, `d`,
  /// `H`, `h`, `m`, and `s` take one or two. `MMMM` reads Persian, Latin
  /// (in any case), and Dari month names, and `EEEE` Persian and Latin
  /// weekday names. `h` and `hh` need `a` or `B` (or `BBBB`) for the half of
  /// the day. `EEEE`, `E`, `D`, `Q`, `a`, and `B` must agree with the date
  /// and hour, or parsing fails.
  ///
  /// Digits may be ASCII, Persian, or Arabic-Indic. Arabic `ي`, `ى`, `ك`,
  /// and `ة` count as their Persian letters, and a zero-width non-joiner,
  /// a space, or nothing between the parts of a name all match, so
  /// `سه‌شنبه`, `سه شنبه`, and `سهشنبه` are the same. Spaces in [pattern]
  /// and around its literal text match any run of spaces.
  ///
  /// With an hour token the result is a local [PersianDate.withTime];
  /// otherwise it is date-only. The year is read in [era], like [parse].
  ///
  /// Throws [FormatException] when [input] does not match or is not a valid
  /// date, and [ArgumentError] when [pattern] lacks a part of the date, has
  /// `h` without `a` or `B`, or has `yy`, `yw`, or `dw`, which cannot be
  /// read back.
  static PersianDate parseFormat(
    String input,
    String pattern, {
    JalaliEra era = JalaliEra.solarHijri,
  }) {
    final date = parseWithPattern(input, pattern, era);
    if (date == null) {
      throw FormatException('Does not match the pattern $pattern', input);
    }
    return date;
  }

  /// Like [parseFormat], but returns null instead of throwing
  /// [FormatException]. Still throws [ArgumentError] for a [pattern] that
  /// cannot be parsed.
  static PersianDate? tryParseFormat(
    String input,
    String pattern, {
    JalaliEra era = JalaliEra.solarHijri,
  }) =>
      parseWithPattern(input, pattern, era);

  /// The moment Jalali [year] begins, the March equinox (سال تحویل), in
  /// UTC.
  ///
  /// `PersianDate.nowruzMoment(1405)` is 2026-03-20 14:45:56 UTC, which is
  /// 18:15:56 in Iran; the University of Tehran announced 18:15:59. Add
  /// 3 hours and 30 minutes for Iran Standard Time, which Iran has kept all
  /// year since 2022; before that, Iran used daylight saving time in summer,
  /// but never at the equinox.
  ///
  /// Calculated from the VSOP87 theory of the Earth's orbit with nutation
  /// and aberration, then converted to UTC with the observed difference
  /// between atomic time and the Earth's rotation (Delta T) for 1974 to
  /// 2026. For 2003 to 2026 every result is within 4 seconds of the moment
  /// the University of Tehran announced, and from 1981 within 3 seconds of
  /// the JPL DE440 ephemeris. Further from today the error grows with the
  /// uncertainty of Delta T: minutes a century away, and more in the
  /// earliest and latest supported years.
  ///
  /// The year begins on the day of this moment when it comes before noon in
  /// Iran, and on the next day otherwise, which is how 1 Farvardin is fixed.
  ///
  /// Throws [ArgumentError] when [year] is outside -61 to 3177.
  static DateTime nowruzMoment(int year) {
    if (year < -61 || year > 3177) {
      throw ArgumentError.value(year, 'year', 'Must be in -61 to 3177');
    }
    return marchEquinox(year + 621);
  }

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

  /// Every day from this date to [end] in order, date-only.
  ///
  /// [end] is included unless [inclusive] is false. Empty when [end] is
  /// before this date. The sequence is lazy, so a long span costs nothing
  /// until it is iterated.
  Iterable<PersianDate> daysUntil(PersianDate end,
      {bool inclusive = true}) sync* {
    final last = end._julianDay - (inclusive ? 0 : 1);
    for (var jdn = _julianDay; jdn <= last; jdn++) {
      yield PersianDate._fromJulianDay(jdn);
    }
  }

  /// Number of days from [other] to this date, ignoring the time of day.
  ///
  /// Positive when this date is later, so
  /// `date.addDays(n).differenceInDays(date) == n`.
  int differenceInDays(PersianDate other) => _julianDay - other._julianDay;

  /// Number of whole Jalali months from [other] to this date, ignoring the
  /// time of day.
  ///
  /// Positive when this date is later. A month is complete when
  /// `other.addMonths(n)` is not past this date, and [addMonths] clamps the
  /// day, so `date.addMonths(n).differenceInMonths(date) == n`: 1403/06/31 to
  /// 1403/07/30 is one month.
  int differenceInMonths(PersianDate other) {
    if (this < other) return -other.differenceInMonths(this);
    final months = (year - other.year) * 12 + month - other.month;
    final day = other.day < monthLength ? other.day : monthLength;
    return day > this.day ? months - 1 : months;
  }

  /// Number of whole Jalali years from [other] to this date, ignoring the
  /// time of day.
  ///
  /// Positive when this date is later, and counted like
  /// [differenceInMonths]: someone born on 1370/12/30 is 30 years old on
  /// 1400/12/29, the last day of 1400.
  int differenceInYears(PersianDate other) => differenceInMonths(other) ~/ 12;

  /// This date relative to [other] in Persian, for example `دیروز`,
  /// `3 روز پیش`, or `ماه آینده`.
  ///
  /// When both dates have a time of day and are less than a day apart, the
  /// result is in hours, minutes, or `اکنون` under a minute. Otherwise it
  /// counts calendar days: days up to a week, then weeks while less than a
  /// whole month has passed, then months and years as
  /// [differenceInMonths] and [differenceInYears] count them.
  ///
  /// The words follow CLDR, as `Intl.RelativeTimeFormat('fa')` writes them
  /// in browsers. With [numeric], a number is always written (`1 روز پیش`
  /// instead of `دیروز`); with [persianDigits], it is written as ۰ to ۹.
  String relativeTo(
    PersianDate other, {
    bool numeric = false,
    bool persianDigits = false,
  }) {
    final text = _relativeTo(other, numeric);
    return persianDigits ? toPersianDigits(text) : text;
  }

  /// This date relative to [PersianDate.now], see [relativeTo].
  String fromNow({bool numeric = false, bool persianDigits = false}) =>
      relativeTo(PersianDate.now(),
          numeric: numeric, persianDigits: persianDigits);

  String _relativeTo(PersianDate other, bool numeric) {
    final time = _dateTime, otherTime = other._dateTime;
    if (time != null && otherTime != null) {
      final elapsed = time.difference(otherTime);
      if (elapsed.inDays == 0) {
        if (elapsed.inHours != 0) {
          return RelativeUnit.hour.format(elapsed.inHours, numeric: numeric);
        }
        if (elapsed.inMinutes != 0) {
          return RelativeUnit.minute
              .format(elapsed.inMinutes, numeric: numeric);
        }
        return RelativeUnit.second.format(
          numeric ? elapsed.inSeconds : 0,
          numeric: numeric,
        );
      }
    }
    final days = differenceInDays(other);
    if (days.abs() < 7) return RelativeUnit.day.format(days, numeric: numeric);
    final months = differenceInMonths(other);
    if (months == 0) {
      return RelativeUnit.week.format(days ~/ 7, numeric: numeric);
    }
    if (months.abs() < 12) {
      return RelativeUnit.month.format(months, numeric: numeric);
    }
    return RelativeUnit.year.format(months ~/ 12, numeric: numeric);
  }

  /// Whether this instance carries a time of day.
  ///
  /// True for dates created from a [DateTime] ([PersianDate.now],
  /// [PersianDate.fromDateTime], [PersianDate.fromGregorian],
  /// [PersianDate.fromGregorianString]) and from [PersianDate.withTime].
  /// False for [PersianDate.new] and for results of date arithmetic.
  bool get hasTime => _dateTime != null;

  DateTime get _time {
    final dateTime = _dateTime;
    if (dateTime == null) {
      throw StateError(
        'This PersianDate has no time of day; check hasTime first.',
      );
    }
    return dateTime;
  }

  /// Hour of the day, 0 to 23. Throws [StateError] when [hasTime] is false.
  int get hour => _time.hour;

  /// Minute of the hour, 0 to 59. Throws [StateError] when [hasTime] is
  /// false.
  int get minute => _time.minute;

  /// Second of the minute, 0 to 59. Throws [StateError] when [hasTime] is
  /// false.
  int get second => _time.second;

  /// Persian name of the part of the day, as CLDR divides it for `fa`:
  /// نیمه‌شب from 0:00, بامداد from 1:00, صبح from 4:00, ظهر from 12:00,
  /// عصر from 13:00, and شب from 19:00.
  ///
  /// The same as the `B` token of [format]. Throws [StateError] when
  /// [hasTime] is false.
  String get dayPeriod => switch (_time.hour) {
        0 => 'نیمه‌شب',
        < 4 => 'بامداد',
        < 12 => 'صبح',
        12 => 'ظهر',
        < 19 => 'عصر',
        _ => 'شب',
      };

  /// [year] in the Shahanshahi (Imperial) numbering, [year] plus 1180, so
  /// 1405 is 2585. See [JalaliEra].
  int get shahanshahiYear => year + JalaliEra.shahanshahi.offset;

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

  /// The lunar Hijri date of this day on [IranianHijri.official]; the same
  /// as [HijriDate.fromPersianDate].
  HijriDate toHijri() => HijriDate.fromPersianDate(this);

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

  /// Latin transliterations of [monthNames], from Farvardin to Esfand.
  static const List<String> monthNamesLatin = [
    'Farvardin',
    'Ordibehesht',
    'Khordad',
    'Tir',
    'Mordad',
    'Shahrivar',
    'Mehr',
    'Aban',
    'Azar',
    'Dey',
    'Bahman',
    'Esfand',
  ];

  /// Latin transliterations of [weekdayNames], indexed by ISO weekday minus
  /// one (Monday first).
  static const List<String> weekdayNamesLatin = [
    'Doshanbeh',
    'Seshanbeh',
    'Chaharshanbeh',
    'Panjshanbeh',
    'Jomeh',
    'Shanbeh',
    'Yekshanbeh',
  ];

  /// Dari month names used in Afghanistan, from Hamal to Hut.
  ///
  /// The months line up one to one with [monthNames]: حمل is Farvardin and
  /// حوت is Esfand.
  static const List<String> monthNamesDari = [
    'حمل',
    'ثور',
    'جوزا',
    'سرطان',
    'اسد',
    'سنبله',
    'میزان',
    'عقرب',
    'قوس',
    'جدی',
    'دلو',
    'حوت',
  ];

  /// Persian name of [month], for example `فروردین` for month 1.
  String get monthName => monthNames[month - 1];

  /// Dari name of [month] used in Afghanistan, for example `حمل` for
  /// month 1.
  String get monthNameDari => monthNamesDari[month - 1];

  /// Latin name of [month], for example `Farvardin` for month 1.
  String get monthNameLatin => monthNamesLatin[month - 1];

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

  /// Latin name of [weekday], for example `Shanbeh` for Saturday.
  String get weekdayNameLatin => weekdayNamesLatin[weekday - 1];

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

  /// Week of the year with Saturday-first weeks, 1 to 54.
  ///
  /// Week 1 is the week that contains 1 Farvardin, even when it starts in
  /// Esfand of the previous year. Week 54 only happens in a leap year that
  /// starts on a Friday, such as 1399.
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
  ///
  /// With [persianDigits], the digits are written as ۰ to ۹. The year is
  /// numbered in [era], Solar Hijri by default.
  @override
  String toString({
    bool showDate = true,
    bool showTime = false,
    bool showHour = true,
    bool showMinute = true,
    bool showSecond = true,
    bool persianDigits = false,
    JalaliEra era = JalaliEra.solarHijri,
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
      parts.add('${year + era.offset}/${twoDigits(month)}/${twoDigits(day)}');
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
          if (showHour) twoDigits(dateTime.hour),
          if (showMinute) twoDigits(dateTime.minute),
          if (showSecond) twoDigits(dateTime.second),
        ].join(':'),
      );
    }
    final text = parts.join(' ');
    return persianDigits ? toPersianDigits(text) : text;
  }

  /// Returns the date as `yyyy-MM-dd`, for JSON and other storage.
  ///
  /// The time of day is not included; store [toDateTime] instead when it
  /// matters. [PersianDate.fromJson] reads the result back.
  String toJson() => format('yyyy-MM-dd');

  static const _tokens = [
    'yyyy', 'yy', 'yw', 'MMMM', 'MM', 'M', 'dd', 'dw', 'd', 'EEEE', 'E', //
    'D', 'Q',
    'HH', 'H', 'hh', 'h', 'mm', 'm', 'ss', 's', 'a', 'BBBB', 'B',
  ];

  /// Formats this date with [pattern].
  ///
  /// | Token  | Output                                   |
  /// | ------ | ---------------------------------------- |
  /// | `yyyy` | year, at least four digits               |
  /// | `yy`   | last two digits of the year              |
  /// | `yw`   | year in Persian words                    |
  /// | `MMMM` | Persian month name                       |
  /// | `MM`   | month, two digits                        |
  /// | `M`    | month                                    |
  /// | `dd`   | day, two digits                          |
  /// | `d`    | day                                      |
  /// | `dw`   | ordinal day in Persian words, `یکم`      |
  /// | `EEEE` | Persian weekday name                     |
  /// | `E`    | one-letter Persian weekday name          |
  /// | `D`    | day of the year                          |
  /// | `Q`    | quarter, 1 to 4                          |
  /// | `HH`   | hour (0 to 23), two digits               |
  /// | `H`    | hour (0 to 23)                           |
  /// | `hh`   | hour (1 to 12), two digits               |
  /// | `h`    | hour (1 to 12)                           |
  /// | `mm`   | minute, two digits                       |
  /// | `m`    | minute                                   |
  /// | `ss`   | second, two digits                       |
  /// | `s`    | second                                   |
  /// | `a`    | ق.ظ before noon, ب.ظ from noon           |
  /// | `B`    | [dayPeriod], for example صبح or عصر      |
  /// | `BBBB` | [dayPeriod], with بعدازظهر for ظهر       |
  ///
  /// The longest token wins, and every other character is copied as is.
  /// Text in single quotes is copied without looking for tokens, and two
  /// single quotes write one: `format("'ساعت' HH:mm")` gives `ساعت 14:30`,
  /// and `format("d 'o''clock'")` gives `1 o'clock`. An unclosed quote runs
  /// to the end of the pattern.
  ///
  /// Throws [StateError] for a time token when [hasTime] is false.
  ///
  /// With [persianDigits], numbers produced by tokens are written as ۰ to ۹;
  /// literal text in [pattern] is copied unchanged.
  ///
  /// `yyyy`, `yy`, and `yw` number the year in [era], Solar Hijri by
  /// default: `format('yyyy', era: JalaliEra.shahanshahi)` gives `2585` for
  /// 1405. `format('EEEE dw MMMM yw')` writes the whole date in words, see
  /// [toPersianWords].
  String format(
    String pattern, {
    bool persianDigits = false,
    JalaliEra era = JalaliEra.solarHijri,
  }) =>
      formatPattern(
        pattern,
        _tokens,
        (token) => _formatToken(token, year + era.offset),
        persianDigits: persianDigits,
      );

  String _formatToken(String token, int eraYear) {
    switch (token) {
      case 'yyyy':
        return fourDigitYear(eraYear);
      case 'yy':
        return twoDigits(eraYear.remainder(100).abs());
      case 'yw':
        return toPersianWords(eraYear);
      case 'MMMM':
        return monthName;
      case 'MM':
        return twoDigits(month);
      case 'M':
        return '$month';
      case 'dd':
        return twoDigits(day);
      case 'd':
        return '$day';
      case 'dw':
        return toPersianWords(day, ordinal: true);
      case 'EEEE':
        return weekdayName;
      case 'E':
        return weekdayNameShort;
      case 'D':
        return '$dayOfYear';
      case 'Q':
        return '$quarter';
    }
    final time = _time;
    if (token == 'a') return time.hour < 12 ? 'ق.ظ' : 'ب.ظ';
    if (token == 'B') return dayPeriod;
    if (token == 'BBBB') return time.hour == 12 ? 'بعدازظهر' : dayPeriod;
    final value = switch (token[0]) {
      'H' => time.hour,
      'h' => time.hour % 12 == 0 ? 12 : time.hour % 12,
      'm' => time.minute,
      _ => time.second,
    };
    return token.length == 2 ? twoDigits(value) : '$value';
  }
}

/// Converts a [DateTime] to a [PersianDate] or a [HijriDate].
extension PersianDateTime on DateTime {
  /// Returns this moment as a [PersianDate], keeping the time of day; the
  /// same as [PersianDate.fromDateTime].
  PersianDate toPersianDate() => PersianDate.fromDateTime(this);

  /// Returns the lunar Hijri date of this calendar day; the same as
  /// [HijriDate.fromDateTime].
  HijriDate toHijriDate() => HijriDate.fromDateTime(this);
}
