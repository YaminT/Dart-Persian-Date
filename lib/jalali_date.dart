library jalali_date;

/// Jalali Date for Dart
class PersianDate {
  int day;
  int month;
  int year;
  int ld;

  DateTime _dateTime;
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
    334
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
    335
  ];

  //TODO: Jalali to Gregorian
  //TODO: From

  ///Constructor from current date and time
  PersianDate.now() {
    _dateTime = new DateTime.now();
    try {
      greToJal();
    } catch (e) {
      print(e.toString());
    }
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
  PersianDate(int year, int month, int day)
      : year = year,
        month = month,
        day = day;

  ///returns date in string
  String toString({
    bool showDate = true,
    bool showTime = false,
    bool hour = true,
    bool minute = true,
    bool second = true,
  }) {
    if (!(showDate || showTime)) {
      throw new Exception(
          'At least one of arguments [showDate or showTime] must be true');
    }
    String stringDate = '';

    if (showDate) {
      stringDate =
          year.toString() + '/' + month.toString() + '/' + day.toString();
      if (showTime) {
        stringDate += ' ';
      }
    }
    if (showTime) {
      String _hour;
      String _minute;
      String _second;

      hour    ? _hour   = _dateTime.hour.toString()   : _hour   = '';
      minute  ? _minute = _dateTime.minute.toString() : _minute = '';
      second  ? _second = _dateTime.second.toString() : _second = '';

      _hour.length == 1 ? _hour = '0' + _hour : '';

      _minute.length == 1 ? _minute = ':0' + _minute :
          _minute.length == 2 ? _minute = ':' + _minute : _minute = '';

      _second.length == 1 ? _second = ':0' + _second :
          _second.length == 2 ? _second = ':' + _second : _second = '';


      stringDate += _hour + _minute + _second;
    }
    return stringDate;
  }

  /// Gregorian to Jalali converter
  /// Thanks to breceivemail [breceivemail.android [AT] yahoo dot com] for java code
  /// TODO: add docs to this method
  greToJal() {
    int gregorieanYear = _dateTime.year;
    if ((gregorieanYear % 4) != 0) {
      day = monthsLength[_dateTime.month - 1] + _dateTime.day;

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
      day = kabiseMonthsLength[_dateTime.month - 1] + _dateTime.day;

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
