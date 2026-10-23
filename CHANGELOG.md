## 1.0.1

* Homepage moved to https://nodets.com/jalali.

## 1.0.0

### Breaking

* Requires Dart 3. The Flutter dependency is gone; the package is pure Dart.
* The `ld` field and the public `monthsLength` and `kabiseMonthsLength` tables are removed.
* `year`, `month`, and `day` are final; `greToJal` is no longer public.
* `toString` pads the date to `yyyy/MM/dd` and the time to `HH:mm:ss`.
* `PersianDate(year, month, day)` validates its arguments and throws `ArgumentError`.
* `toString` throws `ArgumentError` instead of a generic `Exception` when nothing would be shown.

### Fixed

* Gregorian to Jalali conversion is correct for Gregorian century years and across Jalali leap cycles (port of jalaali-js).

### Added

* `toDateTime()` for Jalali to Gregorian conversion.
* `isLeapYear` and `monthLength`.
* Equality on `(year, month, day)` and `Comparable` ordering.
* `monthName`, `monthNames`, `weekday`, `weekdayName`, and `weekdayNames`.
* `showHour`, `showMinute`, and `showSecond` flags on `toString`.
* `format(pattern)` for custom date strings.

## [0.0.1] - July 10 2018

* Convert Gregorian date to Jalali date
