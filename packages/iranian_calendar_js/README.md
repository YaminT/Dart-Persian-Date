# iranian-calendar

Iran's official lunar Hijri (قمری) calendar and Iranian holidays for JavaScript and TypeScript, offline.

- Hijri dates as Iran's official calendar counts them, which `Intl` and Temporal do not: their Islamic calendars put 1405/01/01 (2026-03-21) on 2 or 3 Shawwal 1447, while Iran's calendar has 1 Shawwal.
- Month starts from 1848 to the end of Jalali 1405 come from the official record; later months are calculated from the first sighting of the new crescent in Iran.
- The 26 official holidays, with Persian and English names, and working days around them.
- Jalali (Shamsi) conversion as a convenience.
- No dependencies, ESM, TypeScript types, and it works in browsers, Node, Deno, and Bun.

It is the JavaScript port of the Dart packages [jalali_date](https://pub.dev/packages/jalali_date) and [iranian_holidays](https://pub.dev/packages/iranian_holidays), and gives the same days.

## معرفی به فارسی

`iranian-calendar` تاریخ هجری قمری را مطابق تقویم رسمی ایران و تعطیلات رسمی ایران را بدون اینترنت محاسبه می‌کند.
آغاز ماه‌های قمری تا پایان سال ۱۴۰۵ از تقویم‌های منتشرشده (مرکز تقویم دانشگاه تهران و منابع تاریخی) گرفته شده و برای سال‌های بعد از روی رؤیت هلال در ایران محاسبه می‌شود.
روزهای کاری، تبدیل تاریخ شمسی و میلادی و نام فارسی و انگلیسی تعطیلات را هم دارد.

## Installation

```sh
npm install iranian-calendar
```

## Hijri dates

```js
import { IranianHijri, fromHijri, hijriMonthNames, toHijri } from 'iranian-calendar';

toHijri(new Date(2026, 5, 25)); // { year: 1448, month: 1, day: 10 }, Ashura
toHijri({ year: 2026, month: 3, day: 21 }); // { year: 1447, month: 10, day: 1 }
fromHijri({ year: 1448, month: 1, day: 10 }); // { year: 2026, month: 6, day: 25 }

const calendar = IranianHijri.official;
calendar.fromJalali({ year: 1405, month: 4, day: 4 }); // { year: 1448, month: 1, day: 10 }
calendar.toJalali({ year: 1448, month: 5, day: 1 }); // { year: 1405, month: 7, day: 20 }
calendar.monthStart(1448, 1); // { year: 2026, month: 6, day: 16 }
calendar.monthLength(1447, 12); // 29
hijriMonthNames[0]; // 'محرم'
```

Gregorian days can be given as a `Date` (its local calendar day), as `{ year, month, day }` with months from 1 to 12, or as a Temporal date in any calendar.
Results are plain `{ year, month, day }` objects; `toDate` gives local midnight as a `Date`.
Invalid days and days outside the supported range throw `RangeError`.

### Temporal

```js
toHijri(Temporal.PlainDate.from('2026-06-25')); // { year: 1448, month: 1, day: 10 }
toHijri(Temporal.Now.plainDateISO('Asia/Tehran')); // today in Iran
```

Any object with `withCalendar`, such as `Temporal.PlainDate`, `PlainDateTime`, or `ZonedDateTime`, is read through `withCalendar('iso8601')`, so a date in the `persian` calendar works too.

### How the months are counted

A Hijri month starts the day after the evening its new crescent is seen in Iran.

- From Muharram 1265 (1848) to Shawwal 1448 (Jalali 1405/12), every month starts on the day of the official record: the calendars of the University of Tehran's Calendar Center from 1423 (2002) on, and historical sources before that, as collected by [qamari](https://github.com/roozbehp/qamari). Where the crescent was seen on a different day than predicted, the day it was seen counts.
- Later months are calculated: the positions of the Sun and the Moon, and Yallop's visibility criterion at eight Iranian cities. Against the 259 months published from 1427 to 1448, the calculation alone gets 242 right and is one day off for 17.

A month officially starts when the crescent is seen, which is announced only days before.
Pass the announced start to a calendar of your own:

```js
const announced = new IranianHijri({
  monthStarts: [{ year: 1448, month: 1, start: { year: 2026, month: 6, day: 17 } }],
});
announced.fromGregorian({ year: 2026, month: 6, day: 26 }); // { year: 1448, month: 1, day: 10 }
```

Supported range: Gregorian 560-03-20 to 3798-12-31 (Jalali -61/01/01 to 3177/10/11).

## Holidays

```js
import { holidaysOfYear, holidaysOn } from 'iranian-calendar';

holidaysOn({ year: 2026, month: 3, day: 21 }).map((h) => h.nameEnglish); // ['Nowruz', 'Eid al-Fitr']

for (const day of holidaysOfYear(1405)) {
  console.log(day.jalali, day.date, day.holidays.map((h) => h.name).join('، '));
}
```

`holidaysOfYear` lists the official holidays of a Jalali year in order, and `holidaysOn` those of one day; Fridays are not included.
Each holiday has a Persian `name`, in religiously neutral wording rather than the official text, an English `nameEnglish`, and its `calendar`, `month`, and `day`.
Pass `holidays` to use your own list, and `calendar` for announced month starts.

## Working days

```js
import { addWorkingDays, isWorkingDay, workingDaysBetween } from 'iranian-calendar';

isWorkingDay({ year: 2026, month: 4, day: 2 }); // false, Sizdah Bedar
addWorkingDays({ year: 2026, month: 3, day: 21 }, 3); // { year: 2026, month: 3, day: 28 }
workingDaysBetween({ year: 2026, month: 3, day: 21 }, { year: 2026, month: 3, day: 28 }); // 3
isWorkingDay({ year: 2026, month: 4, day: 9 }, { weekend: [4, 5] }); // false, a Thursday
```

A working day is neither an official holiday nor a day of `weekend`, given as ISO weekdays (1 is Monday, 7 is Sunday) and Friday unless you pass others.
`workingDaysBetween` counts the second day but not the first, so it undoes `addWorkingDays`.

## Jalali dates

```js
import { fromJalali, isLeapJalaliYear, toJalali } from 'iranian-calendar';

toJalali({ year: 2021, month: 3, day: 21 }); // { year: 1400, month: 1, day: 1 }
fromJalali({ year: 1357, month: 11, day: 22 }); // { year: 1979, month: 2, day: 11 }
isLeapJalaliYear(1403); // true
```

For formatting and arithmetic on Jalali dates, use `Intl.DateTimeFormat` with the `persian` calendar, Temporal, or a library such as date-fns-jalali.

## React Aria and `@internationalized/date`

There is no custom `Calendar` for `@internationalized/date` on purpose: React Aria formats calendar cells with `Intl` and the calendar's identifier, so a custom Hijri calendar would compute Iran's dates but display `Intl`'s day numbers.
Use the functions above to mark holidays or show the Hijri date next to a Jalali or Gregorian picker.

## License

Apache-2.0. The Jalali conversion is ported from [jalaali-js](https://github.com/jalaali/jalaali-js) (MIT); see THIRD_PARTY_NOTICES.md.
