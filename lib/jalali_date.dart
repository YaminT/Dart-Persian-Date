library jalali_date;

import 'src/jalali_calc.dart';

/// Jalali Date for Dart
///
/// Supports Jalali years -61 to 3177, roughly Gregorian 560-03-20 to
/// 3798-12-31. Constructing from a Gregorian date after that range throws
/// [ArgumentError]; dates before it follow jalaali-js and are not
/// range-checked.
class PersianDate {
  late int day;
  late int month;
  late int year;

  DateTime? _dateTime;

  //TODO: Jalali to Gregorian
  //TODO: From

  ///Constructor from current date and time
  PersianDate.now() {
    _dateTime = DateTime.now();
    greToJal();
  }

  PersianDate.fromGregorianString(String datetime) {
    _dateTime = DateTime.parse(datetime);
    greToJal();
  }

  PersianDate.fromDateTime(DateTime datetime) : _dateTime = datetime {
    greToJal();
  }

  PersianDate.fromGregorian(int year, int month, int day) {
    _dateTime = DateTime(year, month, day);
    greToJal();
  }

  ///Default constructor from Jalali date
  PersianDate(this.year, this.month, this.day);

  /// Returns the date as `year/month/day`, optionally followed by the time.
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
      parts.add('$year/$month/$day');
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

  /// Gregorian to Jalali converter, backed by the jalaali-js port in
  /// `src/jalali_calc.dart`.
  void greToJal() {
    final dateTime = _dateTime!;
    final date = toJalali(dateTime.year, dateTime.month, dateTime.day);
    year = date.jy;
    month = date.jm;
    day = date.jd;
  }
}
