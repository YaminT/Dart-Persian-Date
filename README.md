# jalali_date

[![pub package](https://img.shields.io/pub/v/jalali_date.svg)](https://pub.dev/packages/jalali_date)
[![CI](https://github.com/YaminT/Dart-Persian-Date/actions/workflows/ci.yml/badge.svg)](https://github.com/YaminT/Dart-Persian-Date/actions/workflows/ci.yml)

Persian (Jalali, Shamsi) calendar for Dart.
It converts between Gregorian and Jalali dates in both directions, knows leap years and month lengths, and formats dates with Persian month and weekday names.
The conversion is a port of [jalaali-js](https://github.com/jalaali/jalaali-js), so century years and leap cycles are handled correctly.
It is pure Dart and works on the Web, Flutter, and the Dart VM.

## Installation

```sh
dart pub add jalali_date
```

Or with Flutter:

```sh
flutter pub add jalali_date
```

## Usage

```dart
import 'package:jalali_date/jalali_date.dart';
```

### Creating dates

```dart
// From Jalali values. Throws ArgumentError for invalid dates.
final a = PersianDate(1400, 1, 1);

// From the current date and time.
final b = PersianDate.now();

// From a DateTime. The time of day and time zone are kept.
final c = PersianDate.fromDateTime(DateTime.utc(2018, 7, 7, 21, 43, 44));

// From Gregorian values. Out-of-range values roll over like DateTime.
final d = PersianDate.fromGregorian(2021, 3, 21);

// From an ISO 8601 string, parsed with DateTime.parse.
final e = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');

print(a.year); // 1400
print(a.month); // 1
print(a.day); // 1
```

### Jalali to Gregorian

```dart
print(PersianDate(1357, 11, 22).toDateTime()); // 1979-02-11 00:00:00.000
```

A date created from a `DateTime` returns that exact `DateTime`, with its time and time zone.
A date created from Jalali values returns local midnight of that day.

### Leap years and month lengths

```dart
final date = PersianDate(1399, 12, 1);
print(date.isLeapYear); // true
print(date.monthLength); // 30
```

### Comparing dates

```dart
final last = PersianDate(1399, 12, 30);
final first = PersianDate(1400, 1, 1);
print(last.compareTo(first) < 0); // true
print(first == PersianDate.fromGregorian(2021, 3, 21)); // true
```

Equality and ordering use the day only; the time of day is ignored.

### Persian names

```dart
final date = PersianDate.fromGregorian(1979, 2, 11);
print(date.monthName); // بهمن
print(date.weekday); // 7 (DateTime.sunday)
print(date.weekdayName); // یکشنبه
```

`weekday` follows `DateTime.weekday` (1 is Monday, 7 is Sunday), even though the Persian week starts on Saturday.
`PersianDate.monthNames` and `PersianDate.weekdayNames` hold the full lists.

### toString

```dart
final date = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
print(date.toString()); // 1397/04/16
print(date.toString(showTime: true)); // 1397/04/16 21:43:44
print(date.toString(showTime: true, showSecond: false)); // 1397/04/16 21:43
print(date.toString(showDate: false, showTime: true)); // 21:43:44
```

The flags are `showDate`, `showTime`, `showHour`, `showMinute`, and `showSecond`.
Every part is zero-padded to two digits.
Hiding everything throws `ArgumentError`.
Showing the time of a date created from Jalali values throws `StateError`, because it has no time of day.

### format

```dart
final date = PersianDate.fromGregorian(2021, 3, 21);
print(date.format('d MMMM yyyy')); // 1 فروردین 1400
print(date.format('EEEE yyyy/MM/dd')); // یکشنبه 1400/01/01
```

| Token  | Output                      |
| ------ | --------------------------- |
| `yyyy` | year, at least four digits  |
| `yy`   | last two digits of the year |
| `MMMM` | Persian month name          |
| `MM`   | month, two digits           |
| `M`    | month                       |
| `dd`   | day, two digits             |
| `d`    | day                         |
| `EEEE` | Persian weekday name        |
| `HH`   | hour (0 to 23), two digits  |
| `H`    | hour (0 to 23)              |
| `mm`   | minute, two digits          |
| `m`    | minute                      |
| `ss`   | second, two digits          |
| `s`    | second                      |

The longest token wins, and every other character is copied as is.
There is no escaping, so letters that form a token are always replaced: `format('Month')` gives `1onth`.
Time tokens throw `StateError` for a date created from Jalali values.

### In fromJson

```dart
class Item {
  final String text;
  final String? date;

  Item(this.text, this.date);

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String?;
    return Item(
      json['text'] as String,
      rawDate == null
          ? null
          : PersianDate.fromDateTime(DateTime.parse(rawDate).toLocal())
              .format('yyyy/MM/dd HH:mm'),
    );
  }
}
```

## Supported range

Jalali -61/01/01 to 3177/10/11, which is Gregorian 560-03-20 to 3798-12-31.
Every constructor throws `ArgumentError` outside that range.

## Migrating from 0.1.x

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
