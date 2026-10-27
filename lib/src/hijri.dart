import 'dart:math' as math;

import '../jalali_date.dart';
import 'hijri_table.dart';
import 'jalali_calc.dart';
import 'pattern.dart';

/// A day of the lunar Hijri (Islamic) calendar as Iran's official calendar
/// counts it.
///
/// Create one from Hijri values with [HijriDate.new], or convert with
/// [HijriDate.fromPersianDate], [HijriDate.fromDateTime],
/// `PersianDate.toHijri()`, or `DateTime.toHijriDate()`. All of them use
/// [IranianHijri.official]; use an [IranianHijri] with announced month
/// starts when the calculation is a day off.
///
/// Supports the Hijri dates of [PersianDate.min] to [PersianDate.max],
/// [HijriDate.min] to [HijriDate.max].
class HijriDate implements Comparable<HijriDate> {
  /// Hijri year, for example 1447. Years before the Hijra are 0 or negative.
  final int year;

  /// Month, 1 (Muharram) to 12 (Dhu al-Hijjah).
  final int month;

  /// Day of the month, 1 to [monthLength].
  final int day;

  /// Julian day number, fixed by the calendar that created this date.
  final int _julianDay;

  HijriDate._(this.year, this.month, this.day, this._julianDay);

  /// Creates a date from a Hijri year, month, and day on
  /// [IranianHijri.official].
  ///
  /// Throws [ArgumentError] when [month] is outside 1 to 12, [day] is
  /// outside the length of that month (29 or 30), or the date is outside
  /// [HijriDate.min] to [HijriDate.max].
  factory HijriDate(int year, int month, int day) =>
      IranianHijri.official.date(year, month, day);

  /// The Hijri date of [date] on [IranianHijri.official]; the time of day
  /// is ignored.
  factory HijriDate.fromPersianDate(PersianDate date) =>
      IranianHijri.official.fromPersianDate(date);

  /// The Hijri date of the calendar day of [dateTime] on
  /// [IranianHijri.official]; the time of day is ignored.
  ///
  /// Throws [ArgumentError] outside the supported range.
  factory HijriDate.fromDateTime(DateTime dateTime) =>
      IranianHijri.official.fromDateTime(dateTime);

  /// First supported date, the Hijri date of [PersianDate.min].
  static final HijriDate min = HijriDate.fromPersianDate(PersianDate.min);

  /// Last supported date, the Hijri date of [PersianDate.max].
  static final HijriDate max = HijriDate.fromPersianDate(PersianDate.max);

  /// Persian names of the Hijri months, as the Iranian calendar writes them,
  /// from Muharram to Dhu al-Hijjah.
  static const List<String> monthNames = [
    'محرم',
    'صفر',
    'ربیع الاول',
    'ربیع الثانی',
    'جمادی الاولی',
    'جمادی الثانیه',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذوالقعده',
    'ذوالحجه',
  ];

  /// Persian name of [month], for example `محرم` for month 1.
  String get monthName => monthNames[month - 1];

  /// Number of days in [month] of [year], 29 or 30, on
  /// [IranianHijri.official].
  int get monthLength => IranianHijri.official.monthLength(year, month);

  /// ISO weekday, 1 = Monday to 7 = Sunday, the same as
  /// [PersianDate.weekday].
  int get weekday => _julianDay % 7 + 1;

  /// Persian name of [weekday], for example `جمعه` for Friday.
  String get weekdayName => PersianDate.weekdayNames[weekday - 1];

  /// One-letter Persian name of [weekday], for example `ج` for Friday.
  String get weekdayNameShort => PersianDate.weekdayNamesShort[weekday - 1];

  /// The same day on the Jalali calendar, date-only.
  ///
  /// A date created by an [IranianHijri] with announced month starts keeps
  /// that calendar's day.
  PersianDate toPersianDate() => _persianDate(_julianDay);

  /// Local midnight of the same day.
  DateTime toDateTime() {
    final g = d2g(_julianDay);
    return DateTime(g.gy, g.gm, g.gd);
  }

  /// Equal when [year], [month], and [day] match.
  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Orders dates by [year], then [month], then [day].
  @override
  int compareTo(HijriDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  /// Whether this date is before [other].
  bool isBefore(HijriDate other) => compareTo(other) < 0;

  /// Whether this date is after [other].
  bool isAfter(HijriDate other) => compareTo(other) > 0;

  /// Whether this date is before [other]; see [compareTo].
  bool operator <(HijriDate other) => compareTo(other) < 0;

  /// Whether this date is before or the same day as [other].
  bool operator <=(HijriDate other) => compareTo(other) <= 0;

  /// Whether this date is after [other]; see [compareTo].
  bool operator >(HijriDate other) => compareTo(other) > 0;

  /// Whether this date is after or the same day as [other].
  bool operator >=(HijriDate other) => compareTo(other) >= 0;

  static const _tokens = [
    'yyyy', 'yy', 'MMMM', 'MM', 'M', 'dd', 'd', 'EEEE', 'E', //
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
  /// | `E`    | one-letter Persian weekday name |
  ///
  /// The longest token wins, every other character is copied as is, and
  /// quoting works like [PersianDate.format]: `format("d MMMM yyyy 'ق'")`
  /// gives `10 محرم 1448 ق`.
  ///
  /// With [persianDigits], numbers produced by tokens are written as ۰ to ۹;
  /// literal text in [pattern] is copied unchanged.
  String format(String pattern, {bool persianDigits = false}) =>
      formatPattern(pattern, _tokens, _formatToken,
          persianDigits: persianDigits);

  String _formatToken(String token) => switch (token) {
        'yyyy' => fourDigitYear(year),
        'yy' => twoDigits(year.remainder(100).abs()),
        'MMMM' => monthName,
        'MM' => twoDigits(month),
        'M' => '$month',
        'dd' => twoDigits(day),
        'd' => '$day',
        'EEEE' => weekdayName,
        _ => weekdayNameShort,
      };

  /// `day monthName year`, for example `1 شوال 1447`.
  @override
  String toString() => '$day $monthName $year';
}

/// The lunar Hijri calendar as Iran's official calendar uses it.
///
/// Month starts from Muharram 1265 (1848) to Shawwal 1448 (Jalali 1405/12)
/// come from the official record: the calendars of the University of
/// Tehran's Calendar Center from 1423 (2002) on, and historical sources
/// before that, as collected by the qamari project. Where the crescent was
/// seen on a different day than the calendar had predicted, the day it was
/// seen counts.
///
/// Later months start the day after the evening their new crescent can be
/// seen in Iran. The crescent is predicted from the positions of the Sun and
/// the Moon (truncated Meeus series) with Yallop's criterion at the
/// optical-aid limit (q >= -0.232), checked at several Iranian cities, and a
/// few months already published on time.ir are fixed by a table.
/// [monthStarts] add announcements of your own.
///
/// The prediction is a calculation, not an announcement: a month can still
/// move by a day when the crescent is or is not actually seen.
class IranianHijri {
  /// Creates the calendar. [monthStarts] maps a Hijri `(year, month)` to
  /// the Jalali day it starts on, for months where an announcement differs
  /// from the calculation; it wins over everything else.
  IranianHijri({Map<(int, int), PersianDate> monthStarts = const {}})
      : monthStarts = Map.unmodifiable(monthStarts),
        _corrections = {
          for (final MapEntry(key: (year, month), :value)
              in monthStarts.entries)
            year * 12 + month - 1: j2d(value.year, value.month, value.day),
        };

  /// The calendar with the built-in table and no announcements of your own.
  /// [HijriDate] uses it.
  static final IranianHijri official = IranianHijri();

  /// Announced month starts given to the constructor.
  final Map<(int, int), PersianDate> monthStarts;

  final Map<int, int> _corrections;

  static final _predicted = <int, int>{};

  /// Jalali day [month] (1 to 12) of Hijri [year] starts on.
  ///
  /// Throws [ArgumentError] when [month] is outside 1 to 12 or that day is
  /// outside the supported range.
  PersianDate monthStart(int year, int month) {
    _checkMonth(year, month);
    return _persianDate(_start(year, month));
  }

  /// Number of days in [month] (1 to 12) of Hijri [year], 29 or 30.
  ///
  /// Throws [ArgumentError] when [month] is outside 1 to 12 or [year] is
  /// outside the supported range.
  int monthLength(int year, int month) {
    _checkMonth(year, month);
    return _start(year + month ~/ 12, month % 12 + 1) - _start(year, month);
  }

  /// Creates a Hijri date on this calendar.
  ///
  /// Throws [ArgumentError] when [month] is outside 1 to 12, [day] is
  /// outside the length of that month, or the date is outside the supported
  /// range.
  HijriDate date(int year, int month, int day) {
    final length = monthLength(year, month);
    if (day < 1 || day > length) {
      throw ArgumentError.value(day, 'day', 'Must be in 1 to $length');
    }
    final jdn = _start(year, month) + day - 1;
    _checkRange(jdn);
    return HijriDate._(year, month, day, jdn);
  }

  /// The Hijri date of [date] on this calendar; the time of day is ignored.
  HijriDate fromPersianDate(PersianDate date) =>
      _fromJulianDay(j2d(date.year, date.month, date.day));

  /// The Hijri date of the calendar day of [dateTime] on this calendar; the
  /// time of day is ignored.
  ///
  /// Throws [ArgumentError] outside the supported range.
  HijriDate fromDateTime(DateTime dateTime) {
    final jdn = g2d(dateTime.year, dateTime.month, dateTime.day);
    _checkRange(jdn);
    return _fromJulianDay(jdn);
  }

  void _checkMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be in 1 to 12');
    }
    final first = HijriDate.min.year, last = HijriDate.max.year;
    if (year < first || year > last) {
      throw ArgumentError.value(year, 'year', 'Must be in $first to $last');
    }
  }

  /// Julian day number of the first day of [month] (1 to 12) of Hijri
  /// [year].
  int _start(int year, int month) {
    final index = year * 12 + month - 1;
    final corrected = _corrections[index];
    if (corrected != null) return corrected;
    if (index >= officialFirstMonth && index <= officialLastMonth) {
      return _recordedStarts[index - officialFirstMonth];
    }
    return _publishedStarts[index] ??
        _predicted.putIfAbsent(
          index,
          () => _predictedStart((index / 12).floor(), index % 12 + 1),
        );
  }

  HijriDate _fromJulianDay(int jdn) {
    // The tabular calendar is never more than a few days off.
    final tabular = _tabularFromJulianDay(jdn);
    var index = tabular.year * 12 + tabular.month - 1;
    while (jdn < _start((index / 12).floor(), index % 12 + 1)) {
      index--;
    }
    while (jdn >= _start(((index + 1) / 12).floor(), (index + 1) % 12 + 1)) {
      index++;
    }
    final year = (index / 12).floor(), month = index % 12 + 1;
    return HijriDate._(year, month, jdn - _start(year, month) + 1, jdn);
  }

  /// Julian day number of [day]/[month]/[year] on the arithmetic (tabular)
  /// Islamic calendar.
  static int _tabularToJulianDay(int year, int month, int day) =>
      day +
      (29.5 * (month - 1)).ceil() +
      (year - 1) * 354 +
      ((3 + 11 * year) / 30).floor() +
      1948439;

  static ({int year, int month}) _tabularFromJulianDay(int jdn) {
    final year = ((30 * (jdn - 1948440) + 10646) / 10631).floor();
    var month = ((jdn - _tabularToJulianDay(year, 1, 1)) / 29.5).floor() + 1;
    if (month > 12) month = 12;
    if (month < 1) month = 1;
    return (year: year, month: month);
  }

  static int _predictedStart(int year, int month) {
    final estimate = _tabularToJulianDay(year, month, 1);
    final conjunction = _conjunction(estimate - 1.0);
    // Local (Iran) civil day of the conjunction.
    final first = (conjunction + 0.5 + _iranOffset).floor();
    for (var evening = first; evening < first + 3; evening++) {
      if (_visibleInIran(evening)) return evening + 1;
    }
    return first + 3;
  }

  /// Iran Standard Time, UTC+3:30, as a fraction of a day.
  static const _iranOffset = 3.5 / 24;

  // Latitude and east longitude of cities across Iran; a crescent seen from
  // any of them starts the month.
  static const _cities = [
    (35.69, 51.39), // Tehran
    (36.30, 59.60), // Mashhad
    (29.61, 52.53), // Shiraz
    (34.31, 47.07), // Kermanshah
    (31.32, 48.67), // Ahvaz
    (27.18, 56.27), // Bandar Abbas
    (38.08, 46.29), // Tabriz
    (29.50, 60.86), // Zahedan
  ];

  // Yallop's q at or above this counts as seen (zone D, optical aid). With
  // it, the prediction alone matches 242 of the 259 months the University of
  // Tehran published from 1427 to 1448. Most misses are months the calendar
  // started although the crescent could not be seen from Iran (q about -0.3
  // to -0.6) while it waited after other evenings with the same q, so no
  // threshold separates them.
  static const _qVisible = -0.232;

  static bool _visibleInIran(int jdn) {
    for (final (lat, lon) in _cities) {
      final q = _yallopQ(jdn, lat, lon);
      if (q != null && q >= _qVisible) return true;
    }
    return false;
  }

  /// Yallop's q for the evening of civil day [jdn] at [lat], [lon], or null
  /// when the Moon sets before the Sun or the Moon is still before
  /// conjunction.
  static double? _yallopQ(int jdn, double lat, double lon) {
    // Local noon in UT, then sunset within the next 12 hours.
    final noon = jdn - lon / 360;
    final sunset =
        _crossing(noon, noon + 0.5, (t) => _sunAltitude(t, lat, lon) + 0.833);
    if (sunset == null) return null;
    if (_elongationSigned(sunset) <= 0) return null;
    if (_moonAltitude(sunset, lat, lon, topocentric: true) + 0.833 <= 0) {
      return null;
    }
    final moonset = _crossing(
      sunset,
      sunset + 0.25,
      (t) => _moonAltitude(t, lat, lon, topocentric: true) + 0.833,
    );
    if (moonset == null) return null;
    final best = sunset + (moonset - sunset) * 4 / 9;

    final moon = _moon(best);
    final sun = _sun(best);
    final arcv = _moonAltitude(best, lat, lon, topocentric: false) -
        _sunAltitude(best, lat, lon);
    final arcl = _acosDeg(_cos(moon.lat) * _cos(moon.lon - sun));
    final parallax = _asinDeg(6378.14 / moon.dist);
    final semidiameter = 0.27245 * parallax;
    final h = _moonAltitude(best, lat, lon, topocentric: true);
    final topoSd = semidiameter * (1 + _sin(h) * _sin(parallax));
    final w = topoSd * 60 * (1 - _cos(arcl));
    return (arcv -
            (11.8371 - 6.3226 * w + 0.7319 * w * w - 0.1018 * w * w * w)) /
        10;
  }

  /// Finds where [f] goes from positive to negative between [from] and [to].
  static double? _crossing(double from, double to, double Function(double) f) {
    const steps = 24;
    var a = from, fa = f(a);
    for (var i = 1; i <= steps; i++) {
      final b = from + (to - from) * i / steps, fb = f(b);
      if (fa > 0 && fb <= 0) {
        var lo = a, hi = b;
        for (var k = 0; k < 30; k++) {
          final mid = (lo + hi) / 2;
          if (f(mid) > 0) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return (lo + hi) / 2;
      }
      a = b;
      fa = fb;
    }
    return null;
  }

  /// Julian date (UT) of the new moon nearest to [near].
  static double _conjunction(double near) {
    var t = near;
    for (var i = 0; i < 8; i++) {
      t -= _elongationSigned(t) / 12.19;
    }
    return t;
  }

  /// Moon longitude minus Sun longitude, in -180 to 180 degrees.
  static double _elongationSigned(double jd) {
    final d = _moon(jd).lon - _sun(jd);
    return (d + 540) % 360 - 180;
  }

  static double _centuries(double jd) {
    final year = 2000 + (jd - 2451545) / 365.25;
    final t = year - 2000;
    // Delta T in seconds (Espenak and Meeus, 2005 to 2050), extended.
    final deltaT = 62.92 + 0.32217 * t + 0.005589 * t * t;
    return (jd + deltaT / 86400 - 2451545) / 36525;
  }

  /// Apparent ecliptic longitude of the Sun, in degrees.
  static double _sun(double jd) {
    final t = _centuries(jd);
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m) +
        (0.019993 - 0.000101 * t) * _sin(2 * m) +
        0.000289 * _sin(3 * m);
    final omega = 125.04 - 1934.136 * t;
    return (l0 + c - 0.00569 - 0.00478 * _sin(omega)) % 360;
  }

  /// Apparent ecliptic longitude and latitude of the Moon in degrees, and
  /// its distance in km (Meeus, chapter 47, main terms).
  static ({double lon, double lat, double dist}) _moon(double jd) {
    final t = _centuries(jd);
    final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t;
    final d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t;
    final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t;
    final mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t;
    final f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t * t;
    final a1 = 119.75 + 131.849 * t;
    final a2 = 53.09 + 479264.290 * t;
    final a3 = 313.45 + 481266.484 * t;
    final e = 1 - 0.002516 * t - 0.0000074 * t * t;

    var sl = 0.0, sr = 0.0, sb = 0.0;
    for (final (cd, cm, cmp, cf, l, r) in _lonDist) {
      final arg = cd * d + cm * m + cmp * mp + cf * f;
      final factor = cm == 0 ? 1.0 : (cm.abs() == 1 ? e : e * e);
      sl += l * factor * _sin(arg);
      sr += r * factor * _cos(arg);
    }
    for (final (cd, cm, cmp, cf, b) in _lat) {
      final factor = cm == 0 ? 1.0 : (cm.abs() == 1 ? e : e * e);
      sb += b * factor * _sin(cd * d + cm * m + cmp * mp + cf * f);
    }
    sl += 3958 * _sin(a1) + 1962 * _sin(lp - f) + 318 * _sin(a2);
    sb += -2235 * _sin(lp) +
        382 * _sin(a3) +
        175 * _sin(a1 - f) +
        175 * _sin(a1 + f) +
        127 * _sin(lp - mp) -
        115 * _sin(lp + mp);
    final omega = 125.04 - 1934.136 * t;
    return (
      lon: (lp + sl / 1e6 - 0.00478 * _sin(omega)) % 360,
      lat: sb / 1e6,
      dist: 385000.56 + sr / 1000,
    );
  }

  static double _sunAltitude(double jd, double lat, double lon) =>
      _altitude(jd, lat, lon, _sun(jd), 0);

  static double _moonAltitude(
    double jd,
    double lat,
    double lon, {
    required bool topocentric,
  }) {
    final moon = _moon(jd);
    final h = _altitude(jd, lat, lon, moon.lon, moon.lat);
    if (!topocentric) return h;
    return h - _asinDeg(6378.14 / moon.dist) * _cos(h);
  }

  /// Geocentric altitude of ecliptic [lambda], [beta] at [jd] seen from
  /// [lat], [lon], in degrees, without refraction.
  static double _altitude(
    double jd,
    double lat,
    double lon,
    double lambda,
    double beta,
  ) {
    final t = (jd - 2451545) / 36525;
    final eps = 23.439291 - 0.0130042 * t;
    final ra = math.atan2(
          _sin(lambda) * _cos(eps) - math.tan(beta * _rad) * _sin(eps),
          _cos(lambda),
        ) /
        _rad;
    final dec = _asinDeg(
      _sin(beta) * _cos(eps) + _cos(beta) * _sin(eps) * _sin(lambda),
    );
    final gmst = 280.46061837 + 360.98564736629 * (jd - 2451545);
    final hourAngle = gmst + lon - ra;
    return _asinDeg(
      _sin(lat) * _sin(dec) + _cos(lat) * _cos(dec) * _cos(hourAngle),
    );
  }

  /// Julian day numbers of the month starts in the official record, from
  /// [officialFirstMonth] to [officialLastMonth].
  static final List<int> _recordedStarts = () {
    final starts = [officialFirstDay];
    for (var i = 0; i < officialLastMonth - officialFirstMonth; i++) {
      final year = i ~/ 12;
      final mask = int.parse(
        officialMonthLengths.substring(year * 3, year * 3 + 3),
        radix: 16,
      );
      starts.add(starts.last + (mask >> i % 12 & 1 == 1 ? 30 : 29));
    }
    return starts;
  }();

  /// Month starts after the official record that the prediction misses,
  /// keyed by `year * 12 + month - 1`, as Julian day numbers, from the
  /// calendar time.ir publishes for Jalali 1406.
  static const Map<int, int> _publishedStarts = {
    1449 * 12 + 0: 2461564, // Muharram 1449
    1449 * 12 + 8: 2461800, // Ramadan 1449
  };

  // Meeus table 47.A: D, M, M', F, longitude (1e-6 degrees), distance (m).
  static const _lonDist = [
    (0, 0, 1, 0, 6288774, -20905355),
    (2, 0, -1, 0, 1274027, -3699111),
    (2, 0, 0, 0, 658314, -2955968),
    (0, 0, 2, 0, 213618, -569925),
    (0, 1, 0, 0, -185116, 48888),
    (0, 0, 0, 2, -114332, -3149),
    (2, 0, -2, 0, 58793, 246158),
    (2, -1, -1, 0, 57066, -152138),
    (2, 0, 1, 0, 53322, -170733),
    (2, -1, 0, 0, 45758, -204586),
    (0, 1, -1, 0, -40923, -129620),
    (1, 0, 0, 0, -34720, 108743),
    (0, 1, 1, 0, -30383, 104755),
    (2, 0, 0, -2, 15327, 10321),
    (0, 0, 1, 2, -12528, 0),
    (0, 0, 1, -2, 10980, 79661),
    (4, 0, -1, 0, 10675, -34782),
    (0, 0, 3, 0, 10034, -23210),
    (4, 0, -2, 0, 8548, -21636),
    (2, 1, -1, 0, -7888, 24208),
    (2, 1, 0, 0, -6766, 30824),
    (1, 0, -1, 0, -5163, -8379),
    (1, 1, 0, 0, 4987, -16675),
    (2, -1, 1, 0, 4036, -12831),
    (2, 0, 2, 0, 3994, -10445),
    (4, 0, 0, 0, 3861, -11650),
    (2, 0, -3, 0, 3665, 14403),
    (0, 1, -2, 0, -2689, -7003),
    (2, 0, -1, 2, -2602, 0),
    (2, -1, -2, 0, 2390, 10056),
    (1, 0, 1, 0, -2348, 6322),
    (2, -2, 0, 0, 2236, -9884),
  ];

  // Meeus table 47.B: D, M, M', F, latitude (1e-6 degrees).
  static const _lat = [
    (0, 0, 0, 1, 5128122),
    (0, 0, 1, 1, 280602),
    (0, 0, 1, -1, 277693),
    (2, 0, 0, -1, 173237),
    (2, 0, -1, 1, 55413),
    (2, 0, -1, -1, 46271),
    (2, 0, 0, 1, 32573),
    (0, 0, 2, 1, 17198),
    (2, 0, 1, -1, 9266),
    (0, 0, 2, -1, 8822),
    (2, -1, 0, -1, 8216),
    (2, 0, -2, -1, 4324),
    (2, 0, 1, 1, 4200),
    (2, 1, 0, -1, -3359),
    (2, -1, -1, 1, 2463),
    (2, -1, 0, 1, 2211),
    (2, -1, -1, -1, 2065),
    (0, 1, -1, -1, -1870),
    (4, 0, -1, -1, 1828),
    (0, 1, 0, 1, -1794),
  ];
}

const _rad = math.pi / 180;
double _sin(double degrees) => math.sin(degrees * _rad);
double _cos(double degrees) => math.cos(degrees * _rad);
double _asinDeg(double x) => math.asin(x.clamp(-1.0, 1.0)) / _rad;
double _acosDeg(double x) => math.acos(x.clamp(-1.0, 1.0)) / _rad;

final _firstDay = j2d(-61, 1, 1);
final _lastDay = j2d(3177, 10, 11);

void _checkRange(int jdn) {
  if (jdn < _firstDay || jdn > _lastDay) {
    throw ArgumentError(
      'Date must be in Jalali -61/01/01 to 3177/10/11 '
      '(Gregorian 560-03-20 to 3798-12-31)',
    );
  }
}

PersianDate _persianDate(int jdn) {
  _checkRange(jdn);
  final date = d2j(jdn);
  return PersianDate(date.jy, date.jm, date.jd);
}
