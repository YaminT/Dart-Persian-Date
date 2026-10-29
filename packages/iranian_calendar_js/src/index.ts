/**
 * Iran's official lunar Hijri calendar and Iranian holidays, offline.
 *
 * @packageDocumentation
 */
import { type DateFields, type GregorianInput, IranianHijri, jalaliJulianDay, julianDay } from './hijri.js';
import { d2g, d2j, isLeapJalaliYear, jalaliMonthLength } from './jalali.js';

export {
  type DateFields,
  type GregorianInput,
  type IranianHijriOptions,
  type TemporalLike,
  IranianHijri,
  hijriMonthNames,
  hijriMonthNamesEnglish,
} from './hijri.js';
export {
  type HolidayDay,
  type HolidayOptions,
  type OfficialHoliday,
  type WorkingDayOptions,
  addWorkingDays,
  holidaysOfYear,
  holidaysOn,
  isWorkingDay,
  officialHolidays,
  workingDaysBetween,
} from './holidays.js';
export { isLeapJalaliYear, jalaliMonthLength };

/** The Hijri date of a Gregorian day on Iran's official calendar. */
export const toHijri = (date: GregorianInput): DateFields => IranianHijri.official.fromGregorian(date);

/** The Gregorian day of a Hijri date on Iran's official calendar. */
export const fromHijri = (date: DateFields): DateFields => IranianHijri.official.toGregorian(date);

/** The Jalali date of a Gregorian day. */
export const toJalali = (date: GregorianInput): DateFields => d2j(julianDay(date));

/** The Gregorian day of a Jalali date. */
export const fromJalali = (date: DateFields): DateFields => d2g(jalaliJulianDay(date));
