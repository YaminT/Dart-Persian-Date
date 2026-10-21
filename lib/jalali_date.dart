library jalali_date;

/// Jalali Date for Dart
class PersianDate {
  late int day;
  late int month;
  late int year;
  late int ld;

  DateTime? _dateTime;
  static const monthsLength = [
    0,
    31,
    59,
    90,
    120,
    151,
    181,
    212,
    243,
    273,
    304,
    334,
  ];
  static const kabiseMonthsLength = [
    0,
    31,
    60,
    91,
    121,
    152,
    182,
    213,
    244,
    274,
    305,
    335,
  ];

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

  /// Gregorian to Jalali converter
  /// Thanks to breceivemail [breceivemail.android [AT] yahoo dot com] for java code
  /// TODO: add docs to this method
  void greToJal() {
    final dateTime = _dateTime!;
    int gregorieanYear = dateTime.year;
    if ((gregorieanYear % 4) != 0) {
      day = monthsLength[dateTime.month - 1] + dateTime.day;

      if (day > 79) {
        day = day - 79;
        if (day <= 186) {
          switch (day % 31) {
            case 0:
              month = day ~/ 31;
              day = 31;
              break;
            default:
              month = (day ~/ 31) + 1;
              day = (day % 31);
              break;
          }
          year = gregorieanYear - 621;
        } else {
          day = day - 186;

          switch (day % 30) {
            case 0:
              month = (day ~/ 30) + 6;
              day = 30;
              break;
            default:
              month = (day ~/ 30) + 7;
              day = (day % 30);
              break;
          }
          year = gregorieanYear - 621;
        }
      } else {
        if ((gregorieanYear > 1996) && (gregorieanYear % 4) == 1) {
          ld = 11;
        } else {
          ld = 10;
        }
        day = day + ld;

        switch (day % 30) {
          case 0:
            month = (day ~/ 30) + 9;
            day = 30;
            break;
          default:
            month = (day ~/ 30) + 10;
            day = (day % 30);
            break;
        }
        year = gregorieanYear - 622;
      }
    } else {
      day = kabiseMonthsLength[dateTime.month - 1] + dateTime.day;

      if (gregorieanYear >= 1996) {
        ld = 79;
      } else {
        ld = 80;
      }
      if (day > ld) {
        day = day - ld;

        if (day <= 186) {
          switch (day % 31) {
            case 0:
              month = (day ~/ 31);
              day = 31;
              break;
            default:
              month = (day ~/ 31) + 1;
              day = (day % 31);
              break;
          }
          year = gregorieanYear - 621;
        } else {
          day = day - 186;

          switch (day % 30) {
            case 0:
              month = (day ~/ 30) + 6;
              day = 30;
              break;
            default:
              month = (day ~/ 30) + 7;
              day = (day % 30);
              break;
          }
          year = gregorieanYear - 621;
        }
      } else {
        day = day + 10;

        switch (day % 30) {
          case 0:
            month = (day ~/ 30) + 9;
            day = 30;
            break;
          default:
            month = (day ~/ 30) + 10;
            day = (day % 30);
            break;
        }
        year = gregorieanYear - 622;
      }
    }
  }
}
