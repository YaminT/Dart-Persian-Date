import 'dart:math' as math;

/// A day of the lunar Hijri calendar as Iran's official calendar counts it.
class HijriDate {
  /// Hijri year, for example 1447.
  final int year;

  /// Month, 1 (Muharram) to 12 (Dhu al-Hijjah).
  final int month;

  /// Day of the month, 1 to 30.
  final int day;

  /// Creates a Hijri date. It is not validated.
  const HijriDate(this.year, this.month, this.day);

  /// Persian name of [month], as the Iranian calendar writes it.
  String get monthName => IranianHijri.monthNames[month - 1];

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// `day monthName year`, for example `1 شوال 1447`.
  @override
  String toString() => '$day $monthName $year';
}

/// The lunar Hijri calendar as Iran's official calendar uses it.
///
/// A month starts the day after the evening its new crescent can be seen in
/// Iran. The crescent is predicted from the positions of the Sun and the Moon
/// (truncated Meeus series) with Yallop's criterion at the optical-aid limit
/// (q >= -0.232), checked at several Iranian cities. Months where the
/// published calendar differs from the prediction are fixed by
/// [_officialStarts], and callers can add [corrections] of their own.
///
/// The prediction is a calculation, not an announcement: a month can still
/// move by a day when the crescent is or is not actually seen.
class IranianHijri {
  /// Creates the calendar. [corrections] maps `year * 12 + month - 1` to the
  /// Julian day number of that month's first day and wins over everything
  /// else.
  IranianHijri([this.corrections = const {}]);

  /// Month starts given by the caller.
  final Map<int, int> corrections;

  static final _predicted = <int, int>{};

  /// Julian day number of the first day of [month] (1 to 12) of Hijri
  /// [year].
  int monthStart(int year, int month) {
    final index = year * 12 + month - 1;
    return corrections[index] ??
        _officialStarts[index] ??
        _predicted.putIfAbsent(
          index,
          () => _predictedStart((index / 12).floor(), index % 12 + 1),
        );
  }

  /// The Hijri date of Julian day number [jdn].
  HijriDate fromJulianDay(int jdn) {
    // The tabular calendar is never more than a few days off.
    final tabular = _tabularFromJulianDay(jdn);
    var index = tabular.year * 12 + tabular.month - 1;
    while (jdn < monthStart((index / 12).floor(), index % 12 + 1)) {
      index--;
    }
    while (
        jdn >= monthStart(((index + 1) / 12).floor(), (index + 1) % 12 + 1)) {
      index++;
    }
    final year = (index / 12).floor(), month = index % 12 + 1;
    return HijriDate(year, month, jdn - monthStart(year, month) + 1);
  }

  /// Persian names of the Hijri months, as the Iranian calendar writes them.
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
  // it, 109 of the 112 months with a holiday from 1395 to 1406 match the
  // published calendar.
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

  /// Hijri month starts in Iran's official calendar that the prediction
  /// misses, keyed by `year * 12 + month - 1`, as Julian day numbers.
  ///
  /// Checked for every month with a holiday from Rajab 1429 to the end of
  /// Jalali 1406, against the calendar published on time.ir.
  static const Map<int, int> _officialStarts = {
    1429 * 12 + 6: 2454652, // Rajab 1429
    1429 * 12 + 9: 2454741, // Shawwal 1429
    1430 * 12 + 9: 2455095, // Shawwal 1430
    1432 * 12 + 6: 2455717, // Rajab 1432
    1432 * 12 + 8: 2455775, // Ramadan 1432
    1433 * 12 + 9: 2456159, // Shawwal 1433
    1435 * 12 + 1: 2456631, // Safar 1435
    1435 * 12 + 7: 2456808, // Shaban 1435
    1436 * 12 + 2: 2457016, // Rabi al-Awwal 1436
    1443 * 12 + 9: 2459703, // Shawwal 1443
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
