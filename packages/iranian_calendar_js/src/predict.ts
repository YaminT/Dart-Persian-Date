// The crescent prediction for months after the official record, ported from
// the Dart package jalali_date (lib/src/hijri.dart) so both give the same
// days.
/**
 * Julian day number of the first day of `month` (1 to 12) of Hijri `year`:
 * the day after the first evening the new crescent can be seen in Iran.
 *
 * The crescent is predicted from the positions of the Sun and the Moon
 * (truncated Meeus series) with Yallop's criterion at the optical-aid limit
 * (q >= -0.232), checked at eight Iranian cities.
 */
export function predictedStart(year: number, month: number): number {
  const estimate = tabularToJulianDay(year, month, 1);
  const conjunction = conjunctionNear(estimate - 1.0);
  // Local (Iran) civil day of the conjunction.
  const first = Math.floor(conjunction + 0.5 + iranOffset);
  for (let evening = first; evening < first + 3; evening++) {
    if (visibleInIran(evening)) return evening + 1;
  }
  return first + 3;
}

/** Julian day number of `day`/`month`/`year` on the arithmetic (tabular) Islamic calendar. */
export const tabularToJulianDay = (year: number, month: number, day: number): number =>
  day + Math.ceil(29.5 * (month - 1)) + (year - 1) * 354 + Math.floor((3 + 11 * year) / 30) + 1948439;

/** Year and month on the tabular Islamic calendar of Julian day number `jdn`. */
export function tabularFromJulianDay(jdn: number): { year: number; month: number } {
  const year = Math.floor((30 * (jdn - 1948440) + 10646) / 10631);
  let month = Math.floor((jdn - tabularToJulianDay(year, 1, 1)) / 29.5) + 1;
  if (month > 12) month = 12;
  if (month < 1) month = 1;
  return { year, month };
}

/** Iran Standard Time, UTC+3:30, as a fraction of a day. */
const iranOffset = 3.5 / 24;

// Latitude and east longitude of cities across Iran; a crescent seen from any
// of them starts the month.
const cities: ReadonlyArray<readonly [number, number]> = [
  [35.69, 51.39], // Tehran
  [36.3, 59.6], // Mashhad
  [29.61, 52.53], // Shiraz
  [34.31, 47.07], // Kermanshah
  [31.32, 48.67], // Ahvaz
  [27.18, 56.27], // Bandar Abbas
  [38.08, 46.29], // Tabriz
  [29.5, 60.86], // Zahedan
];

// Yallop's q at or above this counts as seen (zone D, optical aid).
const qVisible = -0.232;

function visibleInIran(jdn: number): boolean {
  for (const [lat, lon] of cities) {
    const q = yallopQ(jdn, lat, lon);
    if (q !== null && q >= qVisible) return true;
  }
  return false;
}

/**
 * Yallop's q for the evening of civil day `jdn` at `lat`, `lon`, or null when
 * the Moon sets before the Sun or is still before conjunction.
 */
function yallopQ(jdn: number, lat: number, lon: number): number | null {
  // Local noon in UT, then sunset within the next 12 hours.
  const noon = jdn - lon / 360;
  const sunset = crossing(noon, noon + 0.5, (t) => sunAltitude(t, lat, lon) + 0.833);
  if (sunset === null) return null;
  if (elongationSigned(sunset) <= 0) return null;
  if (moonAltitude(sunset, lat, lon, true) + 0.833 <= 0) return null;
  const moonset = crossing(sunset, sunset + 0.25, (t) => moonAltitude(t, lat, lon, true) + 0.833);
  if (moonset === null) return null;
  const best = sunset + ((moonset - sunset) * 4) / 9;

  const m = moon(best);
  const s = sun(best);
  const arcv = moonAltitude(best, lat, lon, false) - sunAltitude(best, lat, lon);
  const arcl = acosDeg(cos(m.lat) * cos(m.lon - s));
  const parallax = asinDeg(6378.14 / m.dist);
  const semidiameter = 0.27245 * parallax;
  const h = moonAltitude(best, lat, lon, true);
  const topoSd = semidiameter * (1 + sin(h) * sin(parallax));
  const w = topoSd * 60 * (1 - cos(arcl));
  return (arcv - (11.8371 - 6.3226 * w + 0.7319 * w * w - 0.1018 * w * w * w)) / 10;
}

/** Finds where `f` goes from positive to negative between `from` and `to`. */
function crossing(from: number, to: number, f: (t: number) => number): number | null {
  const steps = 24;
  let a = from;
  let fa = f(a);
  for (let i = 1; i <= steps; i++) {
    const b = from + ((to - from) * i) / steps;
    const fb = f(b);
    if (fa > 0 && fb <= 0) {
      let lo = a;
      let hi = b;
      for (let k = 0; k < 30; k++) {
        const mid = (lo + hi) / 2;
        if (f(mid) > 0) lo = mid;
        else hi = mid;
      }
      return (lo + hi) / 2;
    }
    a = b;
    fa = fb;
  }
  return null;
}

/** Julian date (UT) of the new moon nearest to `near`. */
function conjunctionNear(near: number): number {
  let t = near;
  for (let i = 0; i < 8; i++) t -= elongationSigned(t) / 12.19;
  return t;
}

/** Moon longitude minus Sun longitude, in -180 to 180 degrees. */
function elongationSigned(jd: number): number {
  const d = moon(jd).lon - sun(jd);
  return dartMod(d + 540, 360) - 180;
}

function centuries(jd: number): number {
  const year = 2000 + (jd - 2451545) / 365.25;
  const t = year - 2000;
  // Delta T in seconds (Espenak and Meeus, 2005 to 2050), extended.
  const deltaT = 62.92 + 0.32217 * t + 0.005589 * t * t;
  return (jd + deltaT / 86400 - 2451545) / 36525;
}

/** Apparent ecliptic longitude of the Sun, in degrees. */
function sun(jd: number): number {
  const t = centuries(jd);
  const l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  const m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  const c =
    (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(m) +
    (0.019993 - 0.000101 * t) * sin(2 * m) +
    0.000289 * sin(3 * m);
  const omega = 125.04 - 1934.136 * t;
  return dartMod(l0 + c - 0.00569 - 0.00478 * sin(omega), 360);
}

/**
 * Apparent ecliptic longitude and latitude of the Moon in degrees, and its
 * distance in km (Meeus, chapter 47, main terms).
 */
function moon(jd: number): { lon: number; lat: number; dist: number } {
  const t = centuries(jd);
  const lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t;
  const d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t;
  const m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t;
  const mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t;
  const f = 93.272095 + 483202.0175233 * t - 0.0036539 * t * t;
  const a1 = 119.75 + 131.849 * t;
  const a2 = 53.09 + 479264.29 * t;
  const a3 = 313.45 + 481266.484 * t;
  const e = 1 - 0.002516 * t - 0.0000074 * t * t;

  let sl = 0;
  let sr = 0;
  let sb = 0;
  for (const [cd, cm, cmp, cf, l, r] of lonDist) {
    const arg = cd * d + cm * m + cmp * mp + cf * f;
    const factor = cm === 0 ? 1.0 : Math.abs(cm) === 1 ? e : e * e;
    sl += l * factor * sin(arg);
    sr += r * factor * cos(arg);
  }
  for (const [cd, cm, cmp, cf, b] of latTerms) {
    const factor = cm === 0 ? 1.0 : Math.abs(cm) === 1 ? e : e * e;
    sb += b * factor * sin(cd * d + cm * m + cmp * mp + cf * f);
  }
  sl += 3958 * sin(a1) + 1962 * sin(lp - f) + 318 * sin(a2);
  sb +=
    -2235 * sin(lp) +
    382 * sin(a3) +
    175 * sin(a1 - f) +
    175 * sin(a1 + f) +
    127 * sin(lp - mp) -
    115 * sin(lp + mp);
  const omega = 125.04 - 1934.136 * t;
  return {
    lon: dartMod(lp + sl / 1e6 - 0.00478 * sin(omega), 360),
    lat: sb / 1e6,
    dist: 385000.56 + sr / 1000,
  };
}

const sunAltitude = (jd: number, lat: number, lon: number): number =>
  altitude(jd, lat, lon, sun(jd), 0);

function moonAltitude(jd: number, lat: number, lon: number, topocentric: boolean): number {
  const m = moon(jd);
  const h = altitude(jd, lat, lon, m.lon, m.lat);
  if (!topocentric) return h;
  return h - asinDeg(6378.14 / m.dist) * cos(h);
}

/**
 * Geocentric altitude of ecliptic `lambda`, `beta` at `jd` seen from `lat`,
 * `lon`, in degrees, without refraction.
 */
function altitude(jd: number, lat: number, lon: number, lambda: number, beta: number): number {
  const t = (jd - 2451545) / 36525;
  const eps = 23.439291 - 0.0130042 * t;
  const ra = Math.atan2(sin(lambda) * cos(eps) - Math.tan(beta * rad) * sin(eps), cos(lambda)) / rad;
  const dec = asinDeg(sin(beta) * cos(eps) + cos(beta) * sin(eps) * sin(lambda));
  const gmst = 280.46061837 + 360.98564736629 * (jd - 2451545);
  const hourAngle = gmst + lon - ra;
  return asinDeg(sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(hourAngle));
}

// Meeus table 47.A: D, M, M', F, longitude (1e-6 degrees), distance (m).
const lonDist: ReadonlyArray<readonly [number, number, number, number, number, number]> = [
  [0, 0, 1, 0, 6288774, -20905355],
  [2, 0, -1, 0, 1274027, -3699111],
  [2, 0, 0, 0, 658314, -2955968],
  [0, 0, 2, 0, 213618, -569925],
  [0, 1, 0, 0, -185116, 48888],
  [0, 0, 0, 2, -114332, -3149],
  [2, 0, -2, 0, 58793, 246158],
  [2, -1, -1, 0, 57066, -152138],
  [2, 0, 1, 0, 53322, -170733],
  [2, -1, 0, 0, 45758, -204586],
  [0, 1, -1, 0, -40923, -129620],
  [1, 0, 0, 0, -34720, 108743],
  [0, 1, 1, 0, -30383, 104755],
  [2, 0, 0, -2, 15327, 10321],
  [0, 0, 1, 2, -12528, 0],
  [0, 0, 1, -2, 10980, 79661],
  [4, 0, -1, 0, 10675, -34782],
  [0, 0, 3, 0, 10034, -23210],
  [4, 0, -2, 0, 8548, -21636],
  [2, 1, -1, 0, -7888, 24208],
  [2, 1, 0, 0, -6766, 30824],
  [1, 0, -1, 0, -5163, -8379],
  [1, 1, 0, 0, 4987, -16675],
  [2, -1, 1, 0, 4036, -12831],
  [2, 0, 2, 0, 3994, -10445],
  [4, 0, 0, 0, 3861, -11650],
  [2, 0, -3, 0, 3665, 14403],
  [0, 1, -2, 0, -2689, -7003],
  [2, 0, -1, 2, -2602, 0],
  [2, -1, -2, 0, 2390, 10056],
  [1, 0, 1, 0, -2348, 6322],
  [2, -2, 0, 0, 2236, -9884],
];

// Meeus table 47.B: D, M, M', F, latitude (1e-6 degrees).
const latTerms: ReadonlyArray<readonly [number, number, number, number, number]> = [
  [0, 0, 0, 1, 5128122],
  [0, 0, 1, 1, 280602],
  [0, 0, 1, -1, 277693],
  [2, 0, 0, -1, 173237],
  [2, 0, -1, 1, 55413],
  [2, 0, -1, -1, 46271],
  [2, 0, 0, 1, 32573],
  [0, 0, 2, 1, 17198],
  [2, 0, 1, -1, 9266],
  [0, 0, 2, -1, 8822],
  [2, -1, 0, -1, 8216],
  [2, 0, -2, -1, 4324],
  [2, 0, 1, 1, 4200],
  [2, 1, 0, -1, -3359],
  [2, -1, -1, 1, 2463],
  [2, -1, 0, 1, 2211],
  [2, -1, -1, -1, 2065],
  [0, 1, -1, -1, -1870],
  [4, 0, -1, -1, 1828],
  [0, 1, 0, 1, -1794],
];

const rad = Math.PI / 180;
const sin = (degrees: number): number => Math.sin(degrees * rad);
const cos = (degrees: number): number => Math.cos(degrees * rad);
const asinDeg = (x: number): number => Math.asin(Math.min(1, Math.max(-1, x))) / rad;
const acosDeg = (x: number): number => Math.acos(Math.min(1, Math.max(-1, x))) / rad;
/** Dart's `%` for doubles: the result has the sign of the divisor. */
const dartMod = (a: number, b: number): number => ((a % b) + b) % b;

