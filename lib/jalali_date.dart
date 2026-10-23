library jalali_date;

import 'src/jalali_calc.dart';

/// Jalali Date for Dart
///
/// Supports Jalali years -61 to 3177, roughly Gregorian 560-03-20 to
/// 3798-12-31. Constructing from a Gregorian date after that range throws
/// [ArgumentError]; dates before it follow jalaali-js and are not
/// range-checked.
class PersianDate implements Comparable<PersianDate> {
  final int year;
  final int month;
  final int day;

  final DateTime? _dateTime;

  /// Creates a date from the current local date and time.
  factory PersianDate.now() => PersianDate.fromDateTime(DateTime.now());

  /// Creates a date from an ISO 8601 string, parsed with [DateTime.parse].
  factory PersianDate.fromGregorianString(String datetime) =>
      PersianDate.fromDateTime(DateTime.parse(datetime));

  /// Creates a date from [datetime], keeping its time of day and time zone.
  factory PersianDate.fromDateTime(DateTime datetime) {
    final date = toJalali(datetime.year, datetime.month, datetime.day);
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
  /// Throws [ArgumentError] when [year] is outside -61 to 3177, [month] is
  /// outside 1 to 12, or [day] is outside the length of that month.
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
  }

  PersianDate._(this.year, this.month, this.day, this._dateTime);

  /// Whether [year] is a Jalali leap year, with 30 days in Esfand.
  bool get isLeapYear => isLeapJalaliYear(year);

  /// Number of days in [month] of [year].
  int get monthLength => jalaliMonthLength(year, month);

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

  /// ISO weekday, 1 = Monday to 7 = Sunday, the same as [DateTime.weekday].
  ///
  /// The Persian week starts on Saturday, but the number follows [DateTime]
  /// so it can be compared with [DateTime.monday] and friends directly.
  int get weekday => toDateTime().weekday;

  /// Persian name of [weekday], for example `شنبه` for Saturday.
  String get weekdayName => weekdayNames[weekday - 1];

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

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
