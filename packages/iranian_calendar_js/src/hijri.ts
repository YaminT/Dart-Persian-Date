import {
  type DateFields,
  type GregorianInput,
  checkRange,
  firstSupportedDay,
  jalaliJulianDay,
  julianDay,
  lastSupportedDay,
} from './days.js';
import { d2g, d2j } from './jalali.js';
import { predictedStart, tabularFromJulianDay } from './predict.js';
import { officialFirstDay, officialFirstMonth, officialLastMonth, officialMonthLengths, predictedLastMonth, predictedMonthLengths } from './table.js';

export {
  type DateFields,
  type GregorianInput,
  type TemporalLike,
  firstSupportedDay,
  jalaliJulianDay,
  julianDay,
  lastSupportedDay,
} from './days.js';

/** Persian names of the Hijri months, from Muharram to Dhu al-Hijjah. */
export const hijriMonthNames: readonly string[] = Object.freeze([
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
]);

/** English names of the Hijri months, from Muharram to Dhu al-Hijjah. */
export const hijriMonthNamesEnglish: readonly string[] = Object.freeze([
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  'Jumada al-Ula',
  'Jumada al-Thaniyah',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qa'dah",
  'Dhu al-Hijjah',
]);

/** Options for {@link IranianHijri}. */
export interface IranianHijriOptions {
  /**
   * Month starts announced after the calculation, which win over it: the
   * Hijri `year` and `month` and the Gregorian day the month starts on.
   */
  readonly monthStarts?: ReadonlyArray<{ year: number; month: number; start: GregorianInput }>;
}

/**
 * The lunar Hijri calendar as Iran's official calendar uses it.
 *
 * Month starts from Muharram 1265 (1848) to Shawwal 1448 (Jalali 1405/12)
 * come from the official record: the calendars of the University of Tehran's
 * Calendar Center from 1423 (2002) on, and historical sources before that, as
 * collected by the qamari project. Later months start the day after the
 * evening their new crescent can be seen in Iran, by calculation. Pass
 * `monthStarts` for months whose announced start differs.
 */
export class IranianHijri {
  /** The calendar with the official record and no announcements of your own. */
  static readonly official = new IranianHijri();

  readonly #corrections = new Map<number, number>();

  constructor(options: IranianHijriOptions = {}) {
    for (const { year, month, start } of options.monthStarts ?? []) {
      checkMonth(month);
      this.#corrections.set(year * 12 + month - 1, julianDay(start));
    }
  }

  /** The Hijri date of a Gregorian day. Throws `RangeError` outside the supported range. */
  fromGregorian(date: GregorianInput): DateFields {
    return this.fromJulianDay(julianDay(date));
  }

  /** The Hijri date of a Jalali day such as `{ year: 1405, month: 4, day: 4 }`. */
  fromJalali(date: DateFields): DateFields {
    return this.fromJulianDay(jalaliJulianDay(date));
  }

  /** The Gregorian day of a Hijri date. */
  toGregorian(date: DateFields): DateFields {
    return d2g(this.toJulianDay(date));
  }

  /** The Jalali day of a Hijri date. */
  toJalali(date: DateFields): DateFields {
    return d2j(this.toJulianDay(date));
  }

  /** Local midnight of the day of a Hijri date. */
  toDate(date: DateFields): Date {
    const g = this.toGregorian(date);
    const result = new Date(g.year, g.month - 1, g.day);
    result.setFullYear(g.year); // Years 0 to 99 would otherwise mean 1900 to 1999.
    return result;
  }

  /** Gregorian day that `month` (1 to 12) of Hijri `year` starts on. */
  monthStart(year: number, month: number): DateFields {
    checkMonth(month);
    return d2g(checkRange(this.#start(year * 12 + month - 1)));
  }

  /** Julian day number of the first day of `month` (1 to 12) of Hijri `year`. */
  monthStartJulianDay(year: number, month: number): number {
    checkMonth(month);
    return this.#start(year * 12 + month - 1);
  }

  /** Number of days in `month` (1 to 12) of Hijri `year`, 29 or 30. */
  monthLength(year: number, month: number): number {
    checkMonth(month);
    const index = year * 12 + month - 1;
    return this.#start(index + 1) - this.#start(index);
  }

  /** Whether `date` is a day of this calendar within the supported range. */
  isValid(date: DateFields): boolean {
    const { year, month, day } = date;
    if (!(Number.isInteger(year) && Number.isInteger(month) && Number.isInteger(day)) || month < 1 || month > 12) return false;
    if (day < 1 || day > this.monthLength(year, month)) return false;
    const jdn = this.#start(year * 12 + month - 1) + day - 1;
    return jdn >= firstSupportedDay && jdn <= lastSupportedDay;
  }

  /** Julian day number of a Hijri date. Throws `RangeError` for a day that does not exist. */
  toJulianDay(date: DateFields): number {
    if (!this.isValid(date)) {
      throw new RangeError(`Not a Hijri day in the supported range: ${date.year}/${date.month}/${date.day}`);
    }
    return this.#start(date.year * 12 + date.month - 1) + date.day - 1;
  }

  /** The Hijri date of Julian day number `jdn`. */
  fromJulianDay(jdn: number): DateFields {
    checkRange(jdn);
    // The tabular calendar is never more than a few days off.
    const tabular = tabularFromJulianDay(jdn);
    let index = tabular.year * 12 + tabular.month - 1;
    while (jdn < this.#start(index)) index--;
    while (jdn >= this.#start(index + 1)) index++;
    return { year: Math.floor(index / 12), month: (index % 12 + 12) % 12 + 1, day: jdn - this.#start(index) + 1 };
  }

  /** Julian day number of the first day of month `index` (`year * 12 + month - 1`). */
  #start(index: number): number {
    const corrected = this.#corrections.get(index);
    if (corrected !== undefined) return corrected;
    if (index >= officialFirstMonth && index <= officialLastMonth) {
      return recordedStarts()[index - officialFirstMonth];
    }
    if (index > officialLastMonth && index <= predictedLastMonth) {
      return predictedStarts()[index - officialLastMonth];
    }
    const published = publishedStarts.get(index);
    if (published !== undefined) return published;
    let start = predicted.get(index);
    if (start === undefined) {
      start = predictedStart(Math.floor(index / 12), ((index % 12) + 12) % 12 + 1);
      predicted.set(index, start);
    }
    return start;
  }
}

/**
 * Month starts after the official record that the prediction misses, keyed by
 * `year * 12 + month - 1`, as Julian day numbers, from the calendar time.ir
 * publishes for Jalali 1406. The same as `_publishedStarts` in the Dart package.
 */
const publishedStarts = new Map<number, number>([
  [1449 * 12 + 0, 2461564], // Muharram 1449
  [1449 * 12 + 8, 2461800], // Ramadan 1449
]);

const predicted = new Map<number, number>();

let recorded: number[] | undefined;
let predictedRecorded: number[] | undefined;

function predictedStarts(): number[] {
  if (predictedRecorded) return predictedRecorded;
  const starts = [recordedStarts().at(-1)!];
  for (let i = 0; i < predictedLastMonth - officialLastMonth; i++) {
    const nibble = parseInt(predictedMonthLengths[i >> 2], 16);
    starts.push(starts[i] + ((nibble >> (i & 3)) & 1 ? 30 : 29));
  }
  return (predictedRecorded = starts);
}

/** Julian day numbers of the month starts in the official record. */
function recordedStarts(): number[] {
  if (recorded) return recorded;
  const starts = [officialFirstDay];
  for (let i = 0; i < officialLastMonth - officialFirstMonth; i++) {
    const year = Math.floor(i / 12);
    const mask = parseInt(officialMonthLengths.slice(year * 3, year * 3 + 3), 16);
    starts.push(starts[starts.length - 1] + ((mask >> i % 12) & 1 ? 30 : 29));
  }
  return (recorded = starts);
}

function checkMonth(month: number): void {
  if (!Number.isInteger(month) || month < 1 || month > 12) {
    throw new RangeError(`Month must be an integer in 1 to 12, got ${month}`);
  }
}

