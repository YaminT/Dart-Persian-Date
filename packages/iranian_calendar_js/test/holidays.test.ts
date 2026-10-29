import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import {
  IranianHijri,
  addWorkingDays,
  fromJalali,
  holidaysOfYear,
  holidaysOn,
  isWorkingDay,
  workingDaysBetween,
} from '../src/index.js';

const j = (year: number, month: number, day: number) => fromJalali({ year, month, day });
const iso = (d: { year: number; month: number; day: number }): string =>
  `${String(d.year).padStart(4, '0')}-${String(d.month).padStart(2, '0')}-${String(d.day).padStart(2, '0')}`;

test('holidays match the Dart package, 1395 to 1410', () => {
  const expected = JSON.parse(readFileSync(new URL('../../test/data/holidays.json', import.meta.url), 'utf8')) as Record<
    string,
    string[][]
  >;
  for (const [year, days] of Object.entries(expected)) {
    const actual = holidaysOfYear(Number(year)).map((d) => [iso(d.date), ...d.holidays.map((h) => h.name)]);
    assert.deepEqual(actual, days, year);
  }
});

test('holidaysOn', () => {
  assert.deepEqual(
    holidaysOn(j(1405, 1, 1)).map((h) => h.nameEnglish),
    ['Nowruz', 'Eid al-Fitr'],
  );
  assert.deepEqual(holidaysOn(j(1405, 4, 4)).map((h) => h.name), ['عاشورا']);
  assert.deepEqual(holidaysOn(j(1405, 1, 15)), []);
});

test('isWorkingDay', () => {
  assert.equal(isWorkingDay(j(1405, 1, 13)), false); // Sizdah Bedar
  assert.equal(isWorkingDay(j(1405, 1, 15)), true);
  assert.equal(isWorkingDay(j(1405, 1, 21)), false); // a Friday
  assert.equal(isWorkingDay(j(1405, 1, 20)), true); // a Thursday
  assert.equal(isWorkingDay(j(1405, 1, 20), { weekend: [4, 5] }), false);
  assert.equal(isWorkingDay(j(1405, 1, 21), { weekend: [] }), true);
});

test('addWorkingDays and workingDaysBetween', () => {
  // 1 to 4 Farvardin are Nowruz, 7 is a Friday.
  assert.deepEqual(addWorkingDays(j(1405, 1, 1), 3), j(1405, 1, 8));
  assert.deepEqual(addWorkingDays(j(1405, 1, 8), -3), j(1404, 12, 28));
  assert.deepEqual(addWorkingDays(j(1405, 1, 1), 0), j(1405, 1, 1));
  assert.equal(workingDaysBetween(j(1405, 1, 1), j(1405, 1, 8)), 3);
  assert.equal(workingDaysBetween(j(1405, 1, 8), j(1405, 1, 1)), -2);
  assert.equal(workingDaysBetween(j(1405, 1, 8), j(1405, 1, 8)), 0);
  assert.throws(() => addWorkingDays(j(1405, 1, 1), 1, { weekend: [1, 2, 3, 4, 5, 6, 7] }), RangeError);
  for (let d = 0; d < 40; d++) {
    const start = new Date(2026, 2, 11 + d);
    for (const n of [-12, -1, 1, 5, 30]) {
      assert.equal(workingDaysBetween(start, addWorkingDays(start, n)), n, `${start.toDateString()} + ${n}`);
    }
  }
});

test('announced month starts move Hijri holidays', () => {
  const calendar = new IranianHijri({
    monthStarts: [{ year: 1448, month: 1, start: j(1405, 3, 27) }],
  });
  assert.deepEqual(holidaysOn(j(1405, 4, 5), { calendar }).map((h) => h.nameEnglish), ['Ashura']);
  assert.deepEqual(holidaysOn(j(1405, 4, 4), { calendar }).map((h) => h.nameEnglish), ['Tasua']);
});
