// Calendar arithmetic ported from jalaali-js v1.2.8.
// https://github.com/jalaali/jalaali-js
// MIT License, Copyright (c) 2020 Behrang Norouzinia.
// The full license text is in THIRD_PARTY_NOTICES.md at the repository root.
//
// Port notes: jalaali-js div(a, b) truncates toward zero, which matches
// Dart's ~/; its mod(a, b) is the JS-style signed remainder, which matches
// a.remainder(b) and not Dart's %.

const _breaks = [
  -61,
  9,
  38,
  199,
  426,
  686,
  756,
  818,
  1111,
  1181,
  1210,
  1635,
  2060,
  2097,
  2192,
  2262,
  2324,
  2394,
  2456,
  3178,
];

void _checkJalaliYear(int jy) {
  if (jy < _breaks.first || jy >= _breaks.last) {
    throw ArgumentError.value(jy, 'jy', 'Jalali year must be in [-61, 3178)');
  }
}

/// Leap information and the Gregorian March day of Farvardin 1.
///
/// Supports Jalali years from -61 (inclusive) to 3178 (exclusive).
/// A [leap] value of zero denotes a leap year.
({int leap, int gy, int march}) jalCal(int jy) {
  _checkJalaliYear(jy);
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _breaks.first;
  var jump = 0;
  for (var i = 1; i < _breaks.length; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += (jump ~/ 33) * 8 + (jump.remainder(33) ~/ 4);
    jp = jm;
  }
  var n = jy - jp;
  leapJ += (n ~/ 33) * 8 + ((n.remainder(33) + 3) ~/ 4);
  if (jump.remainder(33) == 4 && jump - n == 4) leapJ++;
  final leapG = (gy ~/ 4) - (((gy ~/ 100) + 1) * 3 ~/ 4) - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
  var leap = ((n + 1).remainder(33) - 1).remainder(4);
  if (leap == -1) leap = 4;
  return (leap: leap, gy: gy, march: march);
}

/// Number of years since the last Jalali leap year, zero meaning a leap year.
///
/// Fast path of [jalCal] that skips the March day arithmetic, ported from
/// jalCalLeap in jalaali-js.
int _jalCalLeap(int jy) {
  _checkJalaliYear(jy);
  var jp = _breaks.first;
  var jump = 0;
  for (var i = 1; i < _breaks.length; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    jp = jm;
  }
  var n = jy - jp;
  if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
  var leap = ((n + 1).remainder(33) - 1).remainder(4);
  if (leap == -1) leap = 4;
  return leap;
}

bool isLeapJalaliYear(int jy) => _jalCalLeap(jy) == 0;

int jalaliMonthLength(int jy, int jm) => jm <= 6
    ? 31
    : jm <= 11
        ? 30
        : isLeapJalaliYear(jy)
            ? 30
            : 29;

/// Gregorian date to Julian day number.
int g2d(int gy, int gm, int gd) {
  var d = ((gy + ((gm - 8) ~/ 6) + 100100) * 1461 ~/ 4) +
      ((153 * (gm + 9).remainder(12) + 2) ~/ 5) +
      gd -
      34840408;
  d = d - (((gy + 100100 + ((gm - 8) ~/ 6)) ~/ 100) * 3 ~/ 4) + 752;
  return d;
}

/// Julian day number to Gregorian date.
({int gy, int gm, int gd}) d2g(int jdn) {
  var j = 4 * jdn + 139361631;
  j = j + (((4 * jdn + 183187720) ~/ 146097) * 3 ~/ 4) * 4 - 3908;
  final i = (j.remainder(1461) ~/ 4) * 5 + 308;
  final gd = (i.remainder(153) ~/ 5) + 1;
  final gm = (i ~/ 153).remainder(12) + 1;
  final gy = (j ~/ 1461) - 100100 + ((8 - gm) ~/ 6);
  return (gy: gy, gm: gm, gd: gd);
}

/// Jalali date to Julian day number.
int j2d(int jy, int jm, int jd) {
  final r = jalCal(jy);
  return g2d(r.gy, 3, r.march) + (jm - 1) * 31 - (jm ~/ 7) * (jm - 7) + jd - 1;
}

/// Julian day number to Jalali date.
///
/// Matches jalaali-js at the edges of the supported range: days from
/// Gregorian 3799-01-01 on throw [ArgumentError] because the break table
/// ends at Jalali 3178, and days before Gregorian 560-03-20 return Jalali
/// years below -61 unchecked.
({int jy, int jm, int jd}) d2j(int jdn) {
  final gy = d2g(jdn).gy;
  var jy = gy - 621;
  final r = jalCal(jy);
  final jdn1f = g2d(gy, 3, r.march);
  var k = jdn - jdn1f;
  if (k >= 0) {
    if (k <= 185) {
      return (jy: jy, jm: 1 + (k ~/ 31), jd: k.remainder(31) + 1);
    }
    k -= 186;
  } else {
    jy--;
    k += 179;
    if (r.leap == 1) k++;
  }
  return (jy: jy, jm: 7 + (k ~/ 30), jd: k.remainder(30) + 1);
}

/// Gregorian date to Jalali date.
({int jy, int jm, int jd}) toJalali(int gy, int gm, int gd) =>
    d2j(g2d(gy, gm, gd));
