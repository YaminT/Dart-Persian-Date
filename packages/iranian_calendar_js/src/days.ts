import { d2g, g2d, j2d, jalaliMonthLength } from './jalali.js';

/** A year, month (1 to 12), and day of the month. */
export interface DateFields {
  readonly year: number;
  readonly month: number;
  readonly day: number;
}

/**
 * A Temporal date or date-time (`Temporal.PlainDate`, `PlainDateTime`, or
 * `ZonedDateTime`), in any calendar. Only `withCalendar` is used.
 */
export interface TemporalLike {
  withCalendar(calendar: 'iso8601'): DateFields;
}

/**
 * A Gregorian day: a `Date` (its local calendar day), a Temporal date in any
 * calendar, or Gregorian `{ year, month, day }` with months 1 to 12.
 */
export type GregorianInput = Date | TemporalLike | DateFields;

/** First supported day, Jalali -61/01/01 (Gregorian 560-03-20). */
export const firstSupportedDay = /* @__PURE__ */ j2d(-61, 1, 1);
/** Last supported day, Jalali 3177/10/11 (Gregorian 3798-12-31). */
export const lastSupportedDay = /* @__PURE__ */ j2d(3177, 10, 11);

export function checkRange(jdn: number): number {
  if (!Number.isInteger(jdn) || jdn < firstSupportedDay || jdn > lastSupportedDay) {
    throw new RangeError('Date must be in Jalali -61/01/01 to 3177/10/11 (Gregorian 560-03-20 to 3798-12-31)');
  }
  return jdn;
}

/** Julian day number of a Gregorian day, range-checked. */
export function julianDay(date: GregorianInput): number {
  let fields: DateFields;
  if (date instanceof Date) {
    if (Number.isNaN(date.getTime())) throw new RangeError('Invalid Date');
    fields = { year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate() };
  } else if (typeof (date as TemporalLike).withCalendar === 'function') {
    fields = (date as TemporalLike).withCalendar('iso8601');
  } else {
    fields = date as DateFields;
  }
  const { year, month, day } = fields;
  if (!(Number.isInteger(year) && Number.isInteger(month) && Number.isInteger(day)) || month < 1 || month > 12 || day < 1 || day > 31) {
    throw new RangeError(`Not a Gregorian date: ${year}-${month}-${day}`);
  }
  const jdn = g2d(year, month, day);
  const back = d2g(jdn);
  if (back.year !== year || back.month !== month || back.day !== day) {
    throw new RangeError(`Not a Gregorian date: ${year}-${month}-${day}`);
  }
  return checkRange(jdn);
}

/** Julian day number of a Jalali day, range-checked. */
export function jalaliJulianDay(date: DateFields): number {
  const { year, month, day } = date;
  if (
    !(Number.isInteger(year) && Number.isInteger(month) && Number.isInteger(day)) ||
    year < -61 ||
    year > 3177 ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > jalaliMonthLength(year, month)
  ) {
    throw new RangeError(`Not a Jalali date: ${year}/${month}/${day}`);
  }
  return checkRange(j2d(year, month, day));
}
