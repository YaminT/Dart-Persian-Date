## 1.1.0

### Added

* Date arithmetic: `addDays`, `addMonths`, `addYears` (months and years clamp the day), and `differenceInDays`.
* Comparisons: `isBefore`, `isAfter`, `isSameDay`, `isSameMonth`, `isSameYear`, `isToday`, and the `<`, `<=`, `>`, `>=` operators.
* Calendar anchors: `firstDayOfMonth`, `lastDayOfMonth`, `firstDayOfYear`, `lastDayOfYear`, `dayOfYear`, `daysInYear`, `quarter`, `season`, `seasonName`, and `seasonNames`.
* Persian week: `weekdayPersian` (1 is Saturday), `weekdayNameShort`, `weekdayNamesShort`, `isWeekend` (Friday), `startOfWeek`, `endOfWeek`, and `weekOfYear`.
* Parsing: `PersianDate.parse` and `PersianDate.tryParse` for `yyyy/MM/dd` and `yyyy-MM-dd` strings with an optional time and Persian or Arabic-Indic digits.
* Persian digits: `toPersianDigits`, `toLatinDigits`, and a `persianDigits` flag on `toString` and `format`.
* Bounds and copies: `PersianDate.min`, `PersianDate.max`, and `copyWith`.
* Time of day: `hasTime`, `hour`, `minute`, `second`, and `PersianDate.withTime`.
* JSON: `toJson` and `PersianDate.fromJson`.
* `DateTime.toPersianDate()` extension.
* `format` tokens `E`, `D`, `Q`, `hh`, `h`, and `a`, and single-quote escaping for literal text.
* Latin names: `monthNameLatin`, `weekdayNameLatin`, `monthNamesLatin`, and `weekdayNamesLatin`.
* `daysUntil` and `PersianDateRange` for day sequences and range pickers.
* README: Persian introduction, search keywords, a full quick reference, a date picker recipe, and notes for code generators.

### Changed

* `format` treats a single quote as the start of literal text, and `a`, `E`, `D`, `Q`, `h`, and `hh` are now tokens. Quote them to keep them literal.
* `weekday` is computed from the day number instead of building a `DateTime`; the values are unchanged.
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
