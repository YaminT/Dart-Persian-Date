import { d2g, d2j, j2d, jalaliMonthLength } from './jalali.js';
import {
  type DateFields,
  type GregorianInput,
  IranianHijri,
  firstSupportedDay,
  julianDay,
  lastSupportedDay,
} from './hijri.js';

/** One official holiday of Iran, on a fixed Jalali or Hijri date. */
export interface OfficialHoliday {
  /** Calendar of `month` and `day`. */
  readonly calendar: 'jalali' | 'hijri';
  readonly month: number;
  readonly day: number;
  /** Persian name, in religiously neutral wording rather than the official text. */
  readonly name: string;
  /** English name. */
  readonly nameEnglish: string;
}

const jalali = (month: number, day: number, name: string, nameEnglish: string): OfficialHoliday =>
  Object.freeze({ calendar: 'jalali', month, day, name, nameEnglish });
const hijri = (month: number, day: number, name: string, nameEnglish: string): OfficialHoliday =>
  Object.freeze({ calendar: 'hijri', month, day, name, nameEnglish });

/**
 * The 26 official holidays of Iran, besides Fridays. The same list as
 * `OfficialHoliday.iran` in the Dart package iranian_holidays.
 */
export const officialHolidays: readonly OfficialHoliday[] = Object.freeze([
  jalali(1, 1, 'جشن نوروز', 'Nowruz'),
  jalali(1, 2, 'تعطیلات نوروز', 'Nowruz holiday'),
  jalali(1, 3, 'تعطیلات نوروز', 'Nowruz holiday'),
  jalali(1, 4, 'تعطیلات نوروز', 'Nowruz holiday'),
  jalali(1, 12, 'سالروز همه‌پرسی ۱۳۵۸', 'Anniversary of the 1979 referendum'),
  jalali(1, 13, 'سیزده‌به‌در', 'Sizdah Bedar, Nature Day'),
  jalali(3, 14, 'سالروز درگذشت روح‌الله خمینی', "Anniversary of Ruhollah Khomeini's death"),
  jalali(3, 15, 'سالروز رویدادهای ۱۵ خرداد ۱۳۴۲', 'Anniversary of the events of 5 June 1963'),
  jalali(11, 22, 'سالروز انقلاب ۱۳۵۷', 'Anniversary of the 1979 revolution'),
  jalali(12, 29, 'روز ملی شدن صنعت نفت', 'Oil Nationalization Day'),
  hijri(1, 9, 'تاسوعا', 'Tasua'),
  hijri(1, 10, 'عاشورا', 'Ashura'),
  hijri(2, 20, 'اربعین', 'Arbaeen'),
  hijri(
    2,
    28,
    'سالروز درگذشت پیامبر اسلام و شهادت امام دوم شیعیان',
    'Anniversary of the death of the Prophet of Islam and the martyrdom of the second Shia Imam',
  ),
  hijri(2, 29, 'سالروز شهادت امام هشتم شیعیان', 'Martyrdom of the eighth Shia Imam'),
  hijri(3, 8, 'سالروز شهادت امام یازدهم شیعیان', 'Martyrdom of the eleventh Shia Imam'),
  hijri(3, 17, 'زادروز پیامبر اسلام و امام ششم شیعیان', 'Birthday of the Prophet of Islam and the sixth Shia Imam'),
  hijri(6, 3, 'سالروز شهادت فاطمه، دختر پیامبر اسلام', 'Martyrdom of Fatimah, daughter of the Prophet of Islam'),
  hijri(7, 13, 'زادروز امام اول شیعیان و روز پدر', "Birthday of the first Shia Imam, Father's Day"),
  hijri(7, 27, 'عید مبعث', "Mab'ath"),
  hijri(8, 15, 'نیمه شعبان', "Mid-Sha'ban"),
  hijri(9, 21, 'سالروز شهادت امام اول شیعیان', 'Martyrdom of the first Shia Imam'),
  hijri(10, 1, 'عید فطر', 'Eid al-Fitr'),
  hijri(10, 2, 'تعطیلی عید فطر', 'Eid al-Fitr holiday'),
  hijri(10, 25, 'سالروز شهادت امام ششم شیعیان', 'Martyrdom of the sixth Shia Imam'),
  hijri(12, 10, 'عید قربان', 'Eid al-Adha'),
  hijri(12, 18, 'عید غدیر', 'Eid al-Ghadir'),
]);

/** Options shared by the holiday functions. */
export interface HolidayOptions {
  /** The Hijri calendar, for announced month starts. Defaults to `IranianHijri.official`. */
  readonly calendar?: IranianHijri;
  /** The holidays to use. Defaults to {@link officialHolidays}. */
  readonly holidays?: readonly OfficialHoliday[];
}

/** One day with its official holidays. */
export interface HolidayDay {
  /** The Gregorian day. */
  readonly date: DateFields;
  /** The same day on the Jalali calendar. */
  readonly jalali: DateFields;
  readonly holidays: readonly OfficialHoliday[];
}

/** Every official holiday of Jalali `year` in order, without Fridays. */
export function holidaysOfYear(year: number, options: HolidayOptions = {}): HolidayDay[] {
  const days = yearHolidays(year, options);
  return [...days.keys()]
    .sort((a, b) => a - b)
    .map((jdn) => ({ date: d2g(jdn), jalali: d2j(jdn), holidays: days.get(jdn)! }));
}

/** The official holidays on a day, without Fridays; empty on other days. */
export function holidaysOn(date: GregorianInput, options: HolidayOptions = {}): readonly OfficialHoliday[] {
  const jdn = julianDay(date);
  return yearHolidays(d2j(jdn).year, options).get(jdn) ?? [];
}

/** Options for the working-day functions. */
export interface WorkingDayOptions extends HolidayOptions {
  /** Days off every week as ISO weekdays, 1 for Monday to 7 for Sunday. Defaults to `[5]`, Friday. */
  readonly weekend?: readonly number[];
}

/** Whether a day is neither an official holiday nor a day of `weekend`. */
export function isWorkingDay(date: GregorianInput, options: WorkingDayOptions = {}): boolean {
  return workingDay(julianDay(date), options);
}

/**
 * The Gregorian day `days` working days after `date`, or before it when
 * `days` is negative; `date` itself when `days` is 0.
 */
export function addWorkingDays(date: GregorianInput, days: number, options: WorkingDayOptions = {}): DateFields {
  if (!Number.isInteger(days)) throw new RangeError(`days must be an integer, got ${days}`);
  const weekend = options.weekend ?? friday;
  if ([1, 2, 3, 4, 5, 6, 7].every((d) => weekend.includes(d))) {
    throw new RangeError('weekend leaves no working day');
  }
  const step = days < 0 ? -1 : 1;
  let jdn = julianDay(date);
  for (let left = Math.abs(days); left > 0; ) {
    jdn += step;
    if (jdn < firstSupportedDay || jdn > lastSupportedDay) throw new RangeError('Result is outside the supported range');
    if (workingDay(jdn, options)) left--;
  }
  return d2g(jdn);
}

/**
 * Number of working days passed going from `start` to `end`, counting `end`
 * but not `start`, so it undoes {@link addWorkingDays}. Negative when `end` is
 * before `start`.
 */
export function workingDaysBetween(start: GregorianInput, end: GregorianInput, options: WorkingDayOptions = {}): number {
  const from = julianDay(start);
  const to = julianDay(end);
  const step = to < from ? -1 : 1;
  let count = 0;
  // Going back, the days counted are end to the day before start.
  for (let jdn = step > 0 ? from + 1 : to; step > 0 ? jdn <= to : jdn < from; jdn++) {
    if (workingDay(jdn, options)) count++;
  }
  return step * count;
}

const friday: readonly number[] = [5];

function workingDay(jdn: number, options: WorkingDayOptions): boolean {
  const weekday = (jdn % 7) + 1;
  if ((options.weekend ?? friday).includes(weekday)) return false;
  return !yearHolidays(d2j(jdn).year, options).has(jdn);
}

const cache = new WeakMap<IranianHijri, WeakMap<readonly OfficialHoliday[], Map<number, Map<number, OfficialHoliday[]>>>>();

/** Official holidays of Jalali `year` by Julian day number. */
function yearHolidays(year: number, options: HolidayOptions): Map<number, OfficialHoliday[]> {
  const calendar = options.calendar ?? IranianHijri.official;
  const holidays = options.holidays ?? officialHolidays;
  let byList = cache.get(calendar);
  if (!byList) cache.set(calendar, (byList = new WeakMap()));
  let byYear = byList.get(holidays);
  if (!byYear) byList.set(holidays, (byYear = new Map()));
  const cached = byYear.get(year);
  if (cached) return cached;

  const first = Math.max(j2d(year, 1, 1), firstSupportedDay);
  const last = Math.min(year === 3177 ? lastSupportedDay : j2d(year + 1, 1, 1) - 1, lastSupportedDay);
  const days = new Map<number, OfficialHoliday[]>();
  const add = (jdn: number, holiday: OfficialHoliday): void => {
    if (jdn < first || jdn > last) return;
    const list = days.get(jdn);
    if (list) list.push(holiday);
    else days.set(jdn, [holiday]);
  };
  const firstHijri = calendar.fromJulianDay(first).year;
  const lastHijri = calendar.fromJulianDay(last).year;
  for (const holiday of holidays) {
    if (holiday.calendar === 'jalali') {
      if (holiday.day <= jalaliMonthLength(year, holiday.month)) add(j2d(year, holiday.month, holiday.day), holiday);
      continue;
    }
    for (let hy = firstHijri; hy <= lastHijri; hy++) {
      if (holiday.day > calendar.monthLength(hy, holiday.month)) continue;
      add(calendar.monthStartJulianDay(hy, holiday.month) + holiday.day - 1, holiday);
    }
  }
  for (const list of days.values()) Object.freeze(list);
  byYear.set(year, days);
  return days;
}
