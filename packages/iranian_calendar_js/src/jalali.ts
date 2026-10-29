// Calendar arithmetic ported from jalaali-js v1.2.8 through the Dart package
// jalali_date (lib/src/jalali_calc.dart).
// https://github.com/jalaali/jalaali-js
// MIT License, Copyright (c) 2020 Behrang Norouzinia. The full license text
// is in THIRD_PARTY_NOTICES.md.

const breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394,
  2456, 3178,
];

const div = (a: number, b: number): number => Math.trunc(a / b);

function checkYear(jy: number): void {
  if (!Number.isInteger(jy) || jy < breaks[0] || jy >= breaks[breaks.length - 1]) {
    throw new RangeError(`Jalali year must be an integer in -61 to 3177, got ${jy}`);
  }
}

/** Leap information and the Gregorian March day of 1 Farvardin. */
function jalCal(jy: number): { leap: number; gy: number; march: number } {
  checkYear(jy);
  const gy = jy + 621;
  let leapJ = -14;
  let jp = breaks[0];
  let jump = 0;
  for (let i = 1; i < breaks.length; i++) {
    const jm = breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += div(jump, 33) * 8 + div(jump % 33, 4);
    jp = jm;
  }
  let n = jy - jp;
  leapJ += div(n, 33) * 8 + div((n % 33) + 3, 4);
  if (jump % 33 === 4 && jump - n === 4) leapJ++;
  const leapG = div(gy, 4) - div((div(gy, 100) + 1) * 3, 4) - 150;
  const march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + div(jump + 4, 33) * 33;
  let leap = (((n + 1) % 33) - 1) % 4;
  if (leap === -1) leap = 4;
  return { leap, gy, march };
}

/** Whether Jalali year `jy` has 30 days in Esfand. */
export const isLeapJalaliYear = (jy: number): boolean => jalCal(jy).leap === 0;

/** Days in month `jm` of Jalali year `jy`. */
export const jalaliMonthLength = (jy: number, jm: number): number =>
  jm <= 6 ? 31 : jm <= 11 ? 30 : isLeapJalaliYear(jy) ? 30 : 29;

/** Gregorian date to Julian day number. */
export function g2d(gy: number, gm: number, gd: number): number {
  let d =
    div((gy + div(gm - 8, 6) + 100100) * 1461, 4) +
    div(153 * ((gm + 9) % 12) + 2, 5) +
    gd -
    34840408;
  d = d - div(div(gy + 100100 + div(gm - 8, 6), 100) * 3, 4) + 752;
  return d;
}

/** Julian day number to Gregorian date. */
export function d2g(jdn: number): { year: number; month: number; day: number } {
  let j = 4 * jdn + 139361631;
  j = j + div(div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  const i = div(j % 1461, 4) * 5 + 308;
  const day = div(i % 153, 5) + 1;
  const month = (div(i, 153) % 12) + 1;
  const year = div(j, 1461) - 100100 + div(8 - month, 6);
  return { year, month, day };
}

/** Jalali date to Julian day number. */
export function j2d(jy: number, jm: number, jd: number): number {
  const r = jalCal(jy);
  return g2d(r.gy, 3, r.march) + (jm - 1) * 31 - div(jm, 7) * (jm - 7) + jd - 1;
}

/** Julian day number to Jalali date. */
export function d2j(jdn: number): { year: number; month: number; day: number } {
  const gy = d2g(jdn).year;
  let jy = gy - 621;
  const r = jalCal(jy);
  let k = jdn - g2d(gy, 3, r.march);
  if (k >= 0) {
    if (k <= 185) return { year: jy, month: 1 + div(k, 31), day: (k % 31) + 1 };
    k -= 186;
  } else {
    jy--;
    k += 179;
    if (r.leap === 1) k++;
  }
  return { year: jy, month: 7 + div(k, 30), day: (k % 30) + 1 };
}
