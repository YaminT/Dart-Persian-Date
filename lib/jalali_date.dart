library jalali_date;

import 'src/jalali_calc.dart';

/// Jalali Date for Dart
///
/// Supports Jalali -61/01/01 to 3177/10/11, which is Gregorian 560-03-20 to
/// 3798-12-31. Every constructor throws [ArgumentError] outside that range.
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
