import 'dart:math' as math;

import 'nowruz_data.dart';

/// Moment of the March equinox of Gregorian [year], in UTC.
///
/// The Sun's apparent longitude comes from VSOP87D (truncated), the main
/// terms of the IAU 1980 nutation, and the annual aberration (Meeus,
/// Astronomical Algorithms, chapters 22, 25, and 27). The result is
/// converted from Terrestrial Time to UTC with observed Delta T for the
/// years [deltaT] covers, and Morrison and Stephenson's parabola joined to
/// it outside them.
DateTime marchEquinox(int year) {
  final jde = _equinoxJde(year);
  final ut = jde - _deltaT(year + 0.22) / 86400;
  return DateTime.fromMillisecondsSinceEpoch(
    ((ut - 2440587.5) * 86400000).round(),
    isUtc: true,
  );
}

/// Julian Ephemeris Day of the March equinox of [year].
double _equinoxJde(int year) {
  // Meeus table 27.B as the first guess, then Newton steps on the Sun's
  // apparent longitude, which moves about 360/365.24 degrees a day.
  final y = (year - 2000) / 1000;
  var jde = 2451623.80984 +
      365242.37404 * y +
      0.05169 * y * y -
      0.00411 * y * y * y -
      0.00057 * y * y * y * y;
  for (var i = 0; i < 10; i++) {
    final longitude = _apparentSunLongitude(jde);
    final offset = longitude < 180 ? -longitude : 360 - longitude;
    final step = 58 * math.sin(offset * _rad);
    jde += step;
    if (step.abs() < 1e-7) break;
  }
  return jde;
}

/// Apparent geocentric longitude of the Sun at [jde], in degrees, 0 to 360.
double _apparentSunLongitude(double jde) {
  final tau = (jde - 2451545) / 365250;
  final longitude = _series(earthLongitude, tau) / _rad + 180;
  final radius = _series(earthRadius, tau);
  const fk5 = -0.09033 / 3600;
  final aberration = -20.4898 / 3600 / radius;
  return (longitude + fk5 + _nutationInLongitude(tau * 10) + aberration) % 360;
}

double _series(List<List<(double, double, double)>> powers, double tau) {
  var total = 0.0, factor = 1.0;
  for (final terms in powers) {
    var sum = 0.0;
    for (final (amplitude, phase, frequency) in terms) {
      sum += amplitude * math.cos(phase + frequency * tau);
    }
    total += sum * factor;
    factor *= tau;
  }
  return total;
}

/// Nutation in longitude at [t] Julian centuries from J2000, in degrees,
/// from the largest terms of the IAU 1980 series (Meeus table 22.A).
double _nutationInLongitude(double t) {
  final d = 297.85036 + 445267.111480 * t - 0.0019142 * t * t;
  final m = 357.52772 + 35999.050340 * t - 0.0001603 * t * t;
  final mp = 134.96298 + 477198.867398 * t + 0.0086972 * t * t;
  final f = 93.27191 + 483202.017538 * t - 0.0036825 * t * t;
  final omega = 125.04452 - 1934.136261 * t + 0.0020708 * t * t;
  var sum = 0.0;
  for (final (cd, cm, cmp, cf, co, a, b) in _nutation) {
    final argument = cd * d + cm * m + cmp * mp + cf * f + co * omega;
    sum += (a + b * t) * math.sin(argument * _rad);
  }
  return sum / 10000 / 3600;
}

// D, M, M', F, Omega, and the coefficient of the sine in 0.0001 arcseconds
// with its change per century.
const _nutation = [
  (0, 0, 0, 0, 1, -171996.0, -174.2),
  (-2, 0, 0, 2, 2, -13187.0, -1.6),
  (0, 0, 0, 2, 2, -2274.0, -0.2),
  (0, 0, 0, 0, 2, 2062.0, 0.2),
  (0, 1, 0, 0, 0, 1426.0, -3.4),
  (0, 0, 1, 0, 0, 712.0, 0.1),
  (-2, 1, 0, 2, 2, -517.0, 1.2),
  (0, 0, 0, 2, 1, -386.0, -0.4),
  (0, 0, 1, 2, 2, -301.0, 0.0),
  (-2, -1, 0, 2, 2, 217.0, -0.5),
  (-2, 0, 1, 0, 0, -158.0, 0.0),
  (-2, 0, 0, 2, 1, 129.0, 0.1),
  (0, 0, -1, 2, 2, 123.0, 0.0),
  (2, 0, 0, 0, 0, 63.0, 0.0),
  (0, 0, 1, 0, 1, 63.0, 0.1),
  (2, 0, -1, 2, 2, -59.0, 0.0),
  (0, 0, -1, 0, 1, -58.0, -0.1),
  (0, 0, 1, 2, 1, -51.0, 0.0),
];

/// Delta T (TT - UT1) in seconds at the fractional [year].
///
/// Observed values inside [deltaT]; outside, Morrison and Stephenson's
/// long-term parabola, shifted to meet the first or last observed value and
/// joining the plain parabola over a century.
double _deltaT(double year) {
  final first = deltaTFirstYear;
  final last = deltaTFirstYear + deltaT.length - 1;
  if (year < first) {
    final shift = deltaT.first - _parabola(first.toDouble());
    final weight = ((year - (first - 100)) / 100).clamp(0.0, 1.0);
    return _parabola(year) + shift * weight;
  }
  if (year >= last) {
    final shift = deltaT.last - _parabola(last.toDouble());
    final weight = ((last + 100 - year) / 100).clamp(0.0, 1.0);
    return _parabola(year) + shift * weight;
  }
  final index = (year - first).floor();
  final fraction = year - first - index;
  return deltaT[index] + (deltaT[index + 1] - deltaT[index]) * fraction;
}

double _parabola(double year) {
  final u = (year - 1820) / 100;
  return -20 + 32 * u * u;
}

const _rad = math.pi / 180;
