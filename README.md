# jalali_date

[![pub package](https://img.shields.io/pub/v/jalali_date.svg)](https://pub.dev/packages/jalali_date)
[![CI](https://github.com/YaminT/Dart-Persian-Date/actions/workflows/ci.yml/badge.svg)](https://github.com/YaminT/Dart-Persian-Date/actions/workflows/ci.yml)

Persian (Jalali, Shamsi) calendar for Dart.
It converts between Gregorian and Jalali dates in both directions, knows leap years and month lengths, does date arithmetic, parses and formats dates with Persian month and weekday names and Persian digits, and has everything a date picker needs: Saturday-first weeks, month anchors, day ranges, and bounds.
The conversion is a port of [jalaali-js](https://github.com/jalaali/jalaali-js), so century years and leap cycles are handled correctly.
It also gives the lunar Hijri date as Iran's official calendar counts it, and writes and reads years in the Shahanshahi numbering when you ask for it.
It is pure Dart with no dependencies and works on the Web, Flutter, and the Dart VM.

Also known as the Shamsi, Khorshidi, Solar Hijri, Hijri Shamsi, or Iranian calendar.
Keywords: تقویم شمسی، تقویم جلالی، تقویم خورشیدی، هجری شمسی، هجری قمری، سال شاهنشاهی، تاریخ فارسی، تبدیل تاریخ میلادی به شمسی و شمسی به میلادی.

## معرفی به فارسی

`jalali_date` یک بسته‌ی خالص Dart برای تقویم هجری شمسی (جلالی، خورشیدی) است.
تاریخ میلادی را به شمسی و شمسی را به میلادی تبدیل می‌کند، سال کبیسه و طول ماه‌ها را می‌داند و تاریخ را با نام فارسی ماه‌ها و روزهای هفته و ارقام فارسی نمایش می‌دهد.
جمع و تفریق روز و ماه و سال، خواندن تاریخ از متن (با ارقام فارسی یا لاتین)، هفته‌ی شنبه تا جمعه و بازه‌ی تاریخ را هم دارد و برای ساختن انتخابگر تاریخ (date picker) آماده است.
تاریخ هجری قمری را مطابق تقویم رسمی ایران هم می‌دهد و در صورت نیاز سال را به شاهنشاهی می‌نویسد و می‌خواند.
الگوریتم تبدیل از [jalaali-js](https://github.com/jalaali/jalaali-js) گرفته شده و برای سال‌های قرن میلادی و چرخه‌های کبیسه درست کار می‌کند.
به Flutter وابسته نیست و روی وب، Flutter و Dart VM اجرا می‌شود.

```dart
final date = PersianDate.fromGregorian(2021, 3, 21);
print(date); // 1400/01/01
print(date.format('EEEE d MMMM yyyy')); // یکشنبه 1 فروردین 1400
print(date.toString(persianDigits: true)); // ۱۴۰۰/۰۱/۰۱
print(PersianDate.parse('۱۳۵۷/۱۱/۲۲').toDateTime()); // 1979-02-11 00:00:00.000
```

## Installation

```sh
dart pub add jalali_date
```

Or with Flutter:

```sh
flutter pub add jalali_date
```

Then import the single library:

```dart
import 'package:jalali_date/jalali_date.dart';
```

## Quick reference

Everything is exported from `package:jalali_date/jalali_date.dart`: the immutable `PersianDate` class, the `PersianDateRange` class, the `HijriDate` and `IranianHijri` classes, the `toPersianDigits` and `toLatinDigits` functions, the `JalaliEra` enum, and the `DateTime.toPersianDate()` and `DateTime.toHijriDate()` extensions.

### Creating

| Member | Description |
| ------ | ----------- |
| `PersianDate(int year, int month, int day)` | From Jalali values, date-only; throws `ArgumentError` for an invalid date |
| `PersianDate.withTime(year, month, day, [hour, minute, second])` | From Jalali values with a local time of day |
| `PersianDate.now()` | Current local date and time |
| `PersianDate.fromDateTime(DateTime)` | From a `DateTime`; keeps time of day and time zone |
| `DateTime.toPersianDate()` | Extension, the same as `fromDateTime` |
| `PersianDate.fromGregorian(int year, int month, int day)` | From Gregorian values; overflow rolls over like `DateTime` |
| `PersianDate.fromGregorianString(String)` | From an ISO 8601 Gregorian string, via `DateTime.parse` |
| `PersianDate.parse(String, {era})`, `tryParse(String, {era})` | From a Jalali string such as `1403/01/01` or `۱۴۰۳-۱-۱ ۱۴:۳۰` |
| `PersianDate.fromJson(String)`, `toJson()` | `yyyy-MM-dd` for storage and `jsonEncode` |
| `PersianDate.min`, `PersianDate.max` | First and last supported day |
| `copyWith({year, month, day})` | Copy with fields replaced; validates, never clamps |

### Reading

| Member | Description |
| ------ | ----------- |
| `year`, `month`, `day` | Jalali year, month (1 to 12), and day of month |
| `shahanshahiYear` | `year` plus 1180, the Shahanshahi (Imperial) year |
| `hasTime`, `hour`, `minute`, `second` | Time of day; the getters throw `StateError` when `hasTime` is false |
| `isLeapYear`, `daysInYear` | Whether Esfand has 30 days; 365 or 366 |
| `monthLength` | 31, 30, or 29 |
| `dayOfYear` | 1 to 366 |
| `quarter`, `season`, `seasonName` | 1 to 4, and `بهار` to `زمستان` |
| `monthName`, `monthNameLatin`, `monthNameDari` | `فروردین`, `Farvardin`, `حمل` (Afghanistan) |
| `weekday` | ISO weekday, 1 is Monday and 7 is Sunday, like `DateTime.weekday` |
| `weekdayPersian` | 1 is Saturday and 7 is Friday, the column in a Persian calendar grid |
| `weekdayName`, `weekdayNameShort`, `weekdayNameLatin` | `شنبه`, `ش`, `Shanbeh` |
| `weekOfYear` | Saturday-first week number, week 1 contains 1 Farvardin |
| `isWeekend` | Friday |
| `isToday` | Same day as `PersianDate.now()` |
| `monthNames`, `monthNamesLatin`, `monthNamesDari`, `weekdayNames`, `weekdayNamesShort`, `weekdayNamesLatin`, `seasonNames` | Static name lists; weekday lists are indexed by ISO weekday minus one |

### Calculating

| Member | Description |
| ------ | ----------- |
| `addDays(int)`, `addMonths(int)`, `addYears(int)` | Negative values go back; months and years clamp the day |
| `differenceInDays(PersianDate)` | Whole days from the other date to this one |
| `firstDayOfMonth`, `lastDayOfMonth`, `firstDayOfYear`, `lastDayOfYear` | Anchors |
| `startOfWeek()`, `endOfWeek()` | Saturday and Friday of the same week |
| `daysUntil(PersianDate end, {inclusive})` | Lazy sequence of days |
| `PersianDateRange(start, end)` | Inclusive range with `length`, `days`, `contains`, `overlaps` |

### Comparing and converting

| Member | Description |
| ------ | ----------- |
| `==`, `compareTo`, `<`, `<=`, `>`, `>=` | By day only; the time of day is ignored |
| `isBefore`, `isAfter`, `isSameDay`, `isSameMonth`, `isSameYear` | Readable comparisons |
| `toDateTime()` | Gregorian `DateTime` |
| `toHijri()` | Lunar Hijri date, see [Hijri calendar](#hijri-calendar) |
| `toString({showDate, showTime, showHour, showMinute, showSecond, persianDigits, era})` | `yyyy/MM/dd`, optionally with `HH:mm:ss` |
| `format(String pattern, {persianDigits, era})` | Custom string, tokens listed below |
| `toPersianDigits(String)`, `toLatinDigits(String)` | Digit conversion, Persian and Arabic-Indic input |

Supported range: Jalali -61/01/01 to 3177/10/11, which is Gregorian 560-03-20 to 3798-12-31.

## Usage

### Creating dates

```dart
// From Jalali values. Throws ArgumentError for invalid dates.
final a = PersianDate(1400, 1, 1);

// From Jalali values with a local time of day.
final b = PersianDate.withTime(1400, 1, 1, 14, 30);

// From the current date and time.
final c = PersianDate.now();

// From a DateTime. The time of day and time zone are kept.
final d = PersianDate.fromDateTime(DateTime.utc(2018, 7, 7, 21, 43, 44));
final e = DateTime.now().toPersianDate();

// From Gregorian values. Out-of-range values roll over like DateTime.
final f = PersianDate.fromGregorian(2021, 3, 21);

// From an ISO 8601 Gregorian string, parsed with DateTime.parse.
final g = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');

print(a.year); // 1400
print(a.month); // 1
print(a.day); // 1
```

### Date-only and time of day

A `PersianDate` is either date-only or carries a time of day.
Dates made with `PersianDate(...)`, `parse` without a time, `copyWith`, arithmetic, and the anchors are date-only.
Dates made from a `DateTime`, with `PersianDate.withTime`, or by `parse` with a time carry one.

```dart
final date = PersianDate.withTime(1403, 1, 4, 9, 5);
print(date.hasTime); // true
print(date.hour); // 9
print(date.addDays(1).hasTime); // false
print(PersianDate(1403, 1, 4).hasTime); // false
```

`hour`, `minute`, `second`, `toString(showTime: true)`, and the time tokens of `format` throw `StateError` on a date-only instance.

### Jalali to Gregorian

```dart
print(PersianDate(1357, 11, 22).toDateTime()); // 1979-02-11 00:00:00.000
```

A date created from a `DateTime` returns that exact `DateTime`, with its time and time zone.
A date-only instance returns local midnight of that day.

### Parsing

```dart
PersianDate.parse('1403/01/01'); // date-only
PersianDate.parse('1403-1-1'); // date-only
PersianDate.parse('۱۴۰۳/۰۱/۰۱ ۱۴:۳۰'); // with a local time of day
PersianDate.parse('1403-01-01T14:30:15'); // with seconds
PersianDate.tryParse('1400/12/30'); // null, 1400 is not a leap year
```

`parse` accepts `/` or `-` between the parts (the same one twice), one- or two-digit month and day, an optional `HH:mm` or `HH:mm:ss`, and ASCII, Persian, or Arabic-Indic digits.
It throws `FormatException` for anything else, including invalid dates; `tryParse` returns null instead.
The output of `toString`, `toJson`, and `format('yyyy/MM/dd')` parses back.

### Date arithmetic

```dart
final date = PersianDate(1403, 6, 31);
print(date.addDays(1)); // 1403/07/01
print(date.addMonths(1)); // 1403/07/30, the day is clamped
print(PersianDate(1403, 12, 30).addYears(1)); // 1404/12/29
print(PersianDate(1404, 1, 1).differenceInDays(PersianDate(1403, 1, 1))); // 366
```

`addMonths` and `addYears` clamp the day to the length of the target month.
This differs from `DateTime`, which rolls over into the next month.
Results are date-only and throw `ArgumentError` outside the supported range.

### Comparing dates

```dart
final last = PersianDate(1399, 12, 30);
final first = PersianDate(1400, 1, 1);
print(last < first); // true
print(last.isBefore(first)); // true
print(first == PersianDate.fromGregorian(2021, 3, 21)); // true
print(first.isSameMonth(PersianDate(1400, 1, 31))); // true
```

Equality and ordering use the day only; the time of day is ignored.
Lists of `PersianDate` sort with `list.sort()`.

### Leap years, months, and seasons

```dart
final date = PersianDate(1403, 7, 1);
print(date.isLeapYear); // true
print(date.monthLength); // 30
print(date.dayOfYear); // 187
print(date.quarter); // 3
print(date.seasonName); // پاییز
print(date.lastDayOfMonth); // 1403/07/30
print(date.lastDayOfYear); // 1403/12/30
```

### Persian names

```dart
final date = PersianDate.fromGregorian(1979, 2, 11);
print(date.monthName); // بهمن
print(date.monthNameLatin); // Bahman
print(date.monthNameDari); // دلو, the Dari name used in Afghanistan
print(date.weekday); // 7 (DateTime.sunday)
print(date.weekdayPersian); // 2, Sunday is the second day of the Persian week
print(date.weekdayName); // یکشنبه
print(date.weekdayNameShort); // ی
```

`weekday` follows `DateTime.weekday` (1 is Monday, 7 is Sunday), so it compares with `DateTime.friday` and friends.
`weekdayPersian` counts from Saturday, which is what a Persian calendar grid needs.
The static weekday name lists are indexed by `weekday - 1`.

### Persian digits

```dart
final date = PersianDate(1403, 1, 4);
print(date.toString(persianDigits: true)); // ۱۴۰۳/۰۱/۰۴
print(date.format('d MMMM yyyy', persianDigits: true)); // ۴ فروردین ۱۴۰۳
print(toPersianDigits('12:30')); // ۱۲:۳۰
print(toLatinDigits('۱۴۰۳')); // 1403
```

### toString

```dart
final date = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
print(date.toString()); // 1397/04/16
print(date.toString(showTime: true)); // 1397/04/16 21:43:44
print(date.toString(showTime: true, showSecond: false)); // 1397/04/16 21:43
print(date.toString(showDate: false, showTime: true)); // 21:43:44
```

The flags are `showDate`, `showTime`, `showHour`, `showMinute`, `showSecond`, and `persianDigits`.
Every part is zero-padded to two digits.
Hiding everything throws `ArgumentError`.

### format

```dart
final date = PersianDate.withTime(1400, 1, 1, 14, 5);
print(date.format('d MMMM yyyy')); // 1 فروردین 1400
print(date.format('EEEE yyyy/MM/dd')); // یکشنبه 1400/01/01
print(date.format('h:mm a')); // 2:05 ب.ظ
print(date.format("'ساعت' HH:mm")); // ساعت 14:05
```

| Token  | Output                             |
| ------ | ---------------------------------- |
| `yyyy` | year, at least four digits         |
| `yy`   | last two digits of the year        |
| `MMMM` | Persian month name                 |
| `MM`   | month, two digits                  |
| `M`    | month                              |
| `dd`   | day, two digits                    |
| `d`    | day                                |
| `EEEE` | Persian weekday name               |
| `E`    | one-letter Persian weekday name    |
| `D`    | day of the year                    |
| `Q`    | quarter, 1 to 4                    |
| `HH`   | hour (0 to 23), two digits         |
| `H`    | hour (0 to 23)                     |
| `hh`   | hour (1 to 12), two digits         |
| `h`    | hour (1 to 12)                     |
| `mm`   | minute, two digits                 |
| `m`    | minute                             |
| `ss`   | second, two digits                 |
| `s`    | second                             |
| `a`    | `ق.ظ` before noon, `ب.ظ` from noon |

The longest token wins, and every other character is copied as is.
Put literal text in single quotes, and write two single quotes for one: `format("d 'o''clock'")` gives `1 o'clock`.
Time tokens throw `StateError` on a date-only instance.

### Shahanshahi years

```dart
final date = PersianDate(1405, 1, 4);
print(date.shahanshahiYear); // 2585
print(date.format('d MMMM yyyy', era: JalaliEra.shahanshahi)); // 4 فروردین 2585
print(date.toString(era: JalaliEra.shahanshahi)); // 2585/01/04
print(PersianDate.parse('2585/01/04', era: JalaliEra.shahanshahi)); // 1405/01/04
```

The Shahanshahi (شاهنشاهی, Imperial) numbering is the Solar Hijri year plus 1180.
Pass `era: JalaliEra.shahanshahi` to `format`, `toString`, `parse`, or `tryParse` to write or read years that way.
Only the year tokens `yyyy` and `yy` change; months, days, and names are the same in both eras.
`year` always holds the Solar Hijri year, and `toJson` always writes it.
No era name is printed; add one as quoted text, for example `format("yyyy 'شاهنشاهی'", era: JalaliEra.shahanshahi)`.
`parse` with the Shahanshahi era accepts years 1119 to 4357 and throws `FormatException` outside them.

### JSON

```dart
final date = PersianDate(1403, 1, 4);
print(jsonEncode({'date': date})); // {"date":"1403-01-04"}
print(PersianDate.fromJson('1403-01-04')); // 1403/01/04
```

`toJson` writes `yyyy-MM-dd` and drops the time of day; store `toDateTime().toIso8601String()` when the time matters.
`json_serializable` uses `PersianDate.fromJson` and `toJson` for `PersianDate` fields without any annotation.

### Hijri calendar

```dart
final ashura = PersianDate(1405, 4, 4).toHijri();
print(ashura); // 10 محرم 1448
print(ashura.format('EEEE d MMMM yyyy')); // پنجشنبه 10 محرم 1448
print(HijriDate(1447, 10, 1).toPersianDate()); // 1405/01/01
print(DateTime(2026, 6, 25).toHijriDate().format('yyyy/MM/dd')); // 1448/01/10
print(HijriDate(1447, 12, 1).monthLength); // 29
```

`HijriDate` is the lunar Hijri (قمری) date as Iran's official calendar counts it.
A month starts the day after the evening its new crescent can be seen in Iran.
The start is calculated from the positions of the Sun and the Moon with Yallop's visibility criterion at eight Iranian cities, and a built-in table corrects the months where the published calendar differs.
Checked against the calendar published on time.ir for every month with a holiday from Jalali 1387 to 1406, the result matches all of them.

What it cannot do:

- A month officially starts when the crescent is actually seen, which is announced only days before.
  The calculation can be one day off from that announcement.
  Pass the announced start to an `IranianHijri` of your own:

  ```dart
  final announced = IranianHijri(
    // 1 Muharram 1448 announced for 1405/03/27.
    monthStarts: {(1448, 1): PersianDate(1405, 3, 27)},
  );
  print(announced.fromPersianDate(PersianDate(1405, 4, 5))); // 10 محرم 1448
  ```

- Only Iran's calendar is implemented; Umm al-Qura and the tabular Islamic calendar are not.
- Far from today the dates are a calculation only, with nothing to check them against.

| Member | Description |
| ------ | ----------- |
| `HijriDate(int year, int month, int day)` | From Hijri values; throws `ArgumentError` for a day that does not exist |
| `HijriDate.fromPersianDate(PersianDate)`, `PersianDate.toHijri()` | From a Jalali date |
| `HijriDate.fromDateTime(DateTime)`, `DateTime.toHijriDate()` | From the calendar day of a `DateTime` |
| `year`, `month`, `day` | Hijri year, month (1 is Muharram), and day |
| `monthName`, `monthNames` | `محرم` to `ذوالحجه` |
| `monthLength` | 29 or 30 |
| `weekday`, `weekdayName`, `weekdayNameShort` | ISO weekday and Persian names, like `PersianDate` |
| `toPersianDate()`, `toDateTime()` | Jalali date, and local midnight of the day |
| `==`, `compareTo`, `<`, `<=`, `>`, `>=`, `isBefore`, `isAfter` | By year, month, and day |
| `format(String pattern, {persianDigits})` | Tokens `yyyy`, `yy`, `MMMM`, `MM`, `M`, `dd`, `d`, `EEEE`, `E`, quoting like `PersianDate.format` |
| `toString()` | `day monthName year`, for example `10 محرم 1448` |
| `HijriDate.min`, `HijriDate.max` | The Hijri dates of `PersianDate.min` and `PersianDate.max` |
| `IranianHijri.official` | The calendar every `HijriDate` conversion uses |
| `IranianHijri({monthStarts})` | A calendar with announced month starts; `fromPersianDate`, `fromDateTime`, `date`, `monthStart`, `monthLength` |

A `HijriDate` created by a calendar with announced starts keeps that calendar's day in `toPersianDate`, `toDateTime`, and `weekday`.
Equality and ordering compare year, month, and day only.

### Ranges

```dart
final range = PersianDateRange(PersianDate(1403, 1, 1), PersianDate(1403, 1, 13));
print(range.length); // 13
print(range.contains(PersianDate(1403, 1, 4))); // true
for (final day in range.days) {
  print(day.format('E d'));
}
print(PersianDate(1403, 12, 29).daysUntil(PersianDate(1404, 1, 1)).length); // 3
```

## Building a date picker

The package has no widgets, but it has the calendar logic a picker needs.
A month grid with Saturday in the first column:

```dart
List<PersianDate?> monthCells(int year, int month) {
  final first = PersianDate(year, month, 1);
  return [
    for (var i = 1; i < first.weekdayPersian; i++) null, // leading blanks
    ...first.daysUntil(first.lastDayOfMonth),
  ];
}

final header = [
  for (var i = 0; i < 7; i++) PersianDate(1403, 1, 4).addDays(i).weekdayNameShort,
]; // ش ی د س چ پ ج, 1403/01/04 is a Saturday
```

Other building blocks:

- Navigation: `addMonths(1)`, `addMonths(-1)`, `addYears(1)`; the day is clamped, so moving from 1403/06/31 lands on 1403/07/30.
- Selection limits: `PersianDate.min`, `PersianDate.max`, `isBefore`, `isAfter`, or a `PersianDateRange` and `contains`.
- Highlights: `isToday`, `isWeekend` (Friday), `isSameDay` for the selected day.
- Range selection: `PersianDateRange` with `overlaps` and `days`.
- Text input: `PersianDate.tryParse` accepts Persian digits from a Persian keyboard.
- Labels: `monthName`, `weekdayNameShort`, `format('MMMM yyyy', persianDigits: true)`.
- Right-to-left layout is the widget's job; in Flutter, wrap the grid in `Directionality(textDirection: TextDirection.rtl, ...)`.

## Related packages

These live in this repository under `packages/` and are released separately.

- [iranian_holidays](https://pub.dev/packages/iranian_holidays): Iranian official holidays, calculated offline including the lunar Hijri ones, or from an online source you choose (holidayapi.ir, Calendarific, or Google Calendar).
- [jalali_date_picker](packages/jalali_date_picker): Material 3 date picker and range picker for Flutter. In development and not published yet.

## Notes for code generators and AI assistants

- Import only `package:jalali_date/jalali_date.dart`; never import from `src/`.
- `PersianDate` is immutable; there are no setters. Use `copyWith`, `addDays`, `addMonths`, or a constructor.
- `PersianDate(y, m, d)` takes Jalali values; use `PersianDate.fromGregorian(y, m, d)` for Gregorian values.
- Months are 1 to 12, never 0-based.
- `weekday` is ISO (Monday is 1); use `weekdayPersian` for Saturday-first numbering. The name lists are indexed by `weekday - 1`.
- `==` ignores the time of day; compare `toDateTime()` when the moment matters.
- Check `hasTime` before reading `hour`, `minute`, `second`, or using time tokens.
- `addMonths` clamps; it never rolls over like `DateTime`.
- Esfand has 30 days only in leap years; use `monthLength` instead of hard-coding 29.
- `parse` already accepts Persian digits; use `persianDigits: true` or `toPersianDigits` for output.

## Supported range

Jalali -61/01/01 to 3177/10/11, which is Gregorian 560-03-20 to 3798-12-31.
In the Shahanshahi numbering that is 1119/01/01 to 4357/10/11, and in the lunar Hijri calendar -64/10/05 to 3274/12/10.
Every constructor, `parse`, and the arithmetic methods throw outside that range.

## Migrating

### From 1.0.x

- `format` treats a single quote as the start of literal text, and `a`, `E`, `D`, `Q`, `h`, and `hh` are now tokens.
  Quote them to keep them literal: `format("'Q' Q")`.

### From 0.1.x

- Dart 3 is required, and the package no longer depends on Flutter.
- `toString()` pads the date, so `1396/1/1` is now `1396/01/01`.
- `year`, `month`, and `day` are final; create a new `PersianDate` instead of changing them.
- `PersianDate(year, month, day)` throws `ArgumentError` for invalid dates.
- The `ld` field, the `monthsLength` and `kabiseMonthsLength` tables, and the public `greToJal()` are gone.
  Use `isLeapYear` and `monthLength` instead.
- Conversion results changed for some dates, because 0.1.x was wrong around Gregorian century years and Jalali leap cycles.

## Credits

- The conversion algorithm is a port of [jalaali-js](https://github.com/jalaali/jalaali-js) v1.2.8, MIT, Copyright (c) 2020 Behrang Norouzinia.
  See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- The first version was based on Java code by breceivemail.
- Time-part flags on `toString` by [AliRn76](https://github.com/AliRn76).

## License

Apache-2.0.
See [LICENSE](LICENSE).
