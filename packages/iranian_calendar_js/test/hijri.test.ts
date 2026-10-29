import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { Temporal } from 'temporal-polyfill/full';
import {
  IranianHijri,
  fromHijri,
  fromJalali,
  hijriMonthNames,
  isLeapJalaliYear,
  toHijri,
  toJalali,
} from '../src/index.js';

// Compiled to build/test/, so the package root is two levels up.
const packageFile = (path: string): string => readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8');

const iso = (d: { year: number; month: number; day: number }): string =>
  `${String(d.year).padStart(4, '0')}-${String(d.month).padStart(2, '0')}-${String(d.day).padStart(2, '0')}`;

test('known days', () => {
  assert.deepEqual(toHijri({ year: 2026, month: 3, day: 21 }), { year: 1447, month: 10, day: 1 });
  assert.deepEqual(IranianHijri.official.fromJalali({ year: 1405, month: 4, day: 4 }), { year: 1448, month: 1, day: 10 });
  assert.deepEqual(fromHijri({ year: 1448, month: 1, day: 10 }), { year: 2026, month: 6, day: 25 });
  assert.deepEqual(IranianHijri.official.toJalali({ year: 1448, month: 5, day: 1 }), { year: 1405, month: 7, day: 20 });
  assert.equal(hijriMonthNames[0], 'محرم');
});

test('every month start matches the Dart package, 1200 to 1600', () => {
  const { firstYear, starts } = JSON.parse(packageFile('test/data/month_starts.json')) as {
    firstYear: number;
    starts: string[];
  };
  starts.forEach((expected, i) => {
    const year = firstYear + Math.floor(i / 12);
    const month = (i % 12) + 1;
    assert.equal(iso(IranianHijri.official.monthStart(year, month)), expected, `${year}/${month}`);
  });
});

test('every month start matches the official record', () => {
  let months = 0;
  for (const file of ['../../test/data/qamari_consolidated.txt', '../../test/data/hijri_supplement.txt']) {
    for (const line of packageFile(file).split('\n')) {
      const m = /^\*?(\d+)\/(\d+) (\d{4}-\d{2}-\d{2})/.exec(line);
      if (!m) continue;
      assert.equal(iso(IranianHijri.official.monthStart(Number(m[1]), Number(m[2]))), m[3], line);
      months++;
    }
  }
  assert.equal(months, 2206);
});

test('round trip and day sequence over two centuries', () => {
  const calendar = IranianHijri.official;
  let previous = calendar.fromGregorian({ year: 1921, month: 3, day: 21 });
  for (let t = Date.UTC(1921, 2, 22); t < Date.UTC(2121, 2, 21); t += 86_400_000) {
    const d = new Date(t);
    const day = { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate() };
    const hijri = calendar.fromGregorian(day);
    assert.deepEqual(calendar.toGregorian(hijri), day);
    if (hijri.day === 1) {
      assert.equal(previous.day, calendar.monthLength(previous.year, previous.month), iso(day));
      assert.equal(hijri.month, (previous.month % 12) + 1, iso(day));
    } else {
      assert.equal(hijri.day, previous.day + 1, iso(day));
    }
    previous = hijri;
  }
});

test('inputs: Date, Temporal in any calendar, and plain objects', () => {
  const expected = { year: 1448, month: 1, day: 10 };
  assert.deepEqual(toHijri(new Date(2026, 5, 25, 23, 59)), expected);
  assert.deepEqual(toHijri(Temporal.PlainDate.from('2026-06-25')), expected);
  assert.deepEqual(toHijri(Temporal.PlainDate.from('2026-06-25').withCalendar('persian')), expected);
  assert.deepEqual(toHijri(Temporal.ZonedDateTime.from('2026-06-25T23:30[Asia/Tehran]')), expected);
  const date = IranianHijri.official.toDate(expected);
  assert.equal(date.getFullYear(), 2026);
  assert.equal(date.getMonth(), 5);
  assert.equal(date.getDate(), 25);
  assert.equal(date.getHours(), 0);
});

test('invalid input throws RangeError', () => {
  assert.throws(() => toHijri({ year: 2026, month: 2, day: 30 }), RangeError);
  assert.throws(() => toHijri(new Date(Number.NaN)), RangeError);
  assert.throws(() => toHijri({ year: 3799, month: 1, day: 1 }), RangeError);
  assert.throws(() => fromHijri({ year: 1447, month: 12, day: 30 }), RangeError); // 29 days
  assert.throws(() => IranianHijri.official.monthStart(1447, 13), RangeError);
  assert.throws(() => fromJalali({ year: 1404, month: 12, day: 30 }), RangeError);
  assert.equal(IranianHijri.official.isValid({ year: 1447, month: 12, day: 30 }), false);
  assert.equal(IranianHijri.official.isValid({ year: 1447, month: 12, day: 29 }), true);
});

test('announced month starts win over the calculation', () => {
  const announced = new IranianHijri({
    monthStarts: [{ year: 1448, month: 1, start: { year: 2026, month: 6, day: 17 } }],
  });
  assert.deepEqual(announced.fromGregorian({ year: 2026, month: 6, day: 26 }), { year: 1448, month: 1, day: 10 });
  assert.equal(announced.monthLength(1447, 12), 30);
  assert.deepEqual(IranianHijri.official.fromGregorian({ year: 2026, month: 6, day: 26 }), {
    year: 1448,
    month: 1,
    day: 11,
  });
});

test('supported range', () => {
  const first = toHijri({ year: 560, month: 3, day: 20 });
  const last = toHijri({ year: 3798, month: 12, day: 31 });
  assert.ok(first.year < 0);
  assert.deepEqual(fromHijri(first), { year: 560, month: 3, day: 20 });
  assert.deepEqual(fromHijri(last), { year: 3798, month: 12, day: 31 });
  assert.throws(() => toHijri({ year: 560, month: 3, day: 19 }), RangeError);
});

test('Jalali conversion', () => {
  assert.deepEqual(toJalali({ year: 2021, month: 3, day: 21 }), { year: 1400, month: 1, day: 1 });
  assert.deepEqual(fromJalali({ year: 1357, month: 11, day: 22 }), { year: 1979, month: 2, day: 11 });
  assert.equal(isLeapJalaliYear(1403), true);
  assert.equal(isLeapJalaliYear(1404), false);
});
