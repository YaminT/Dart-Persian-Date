# 02: Parsing with a pattern and month names

## Why

`parse` reads only `yyyy/MM/dd` with an optional time.
Real input often looks like `۴ فروردین ۱۴۰۳` or `1403 Farvardin 4`, sometimes typed with Arabic `ي` and `ك`.
date-fns-jalali `parse(text, 'd MMMM yyyy')`, moment-jalaali `moment(text, 'jYYYY/jM/jD')`, jdatetime `strptime`, verta `parseFormat`, and persianist `parseJalali` all read a pattern; verta and @doranjs also normalize Arabic letters first.
date-fns-jalali fails on Persian digits; this package would not.

## API

```dart
PersianDate.parseFormat('۴ فروردین ۱۴۰۳', 'd MMMM yyyy'); // 1403/01/04
PersianDate.parseFormat('1403 Farvardin 4', 'yyyy MMMM d'); // 1403/01/04
PersianDate.tryParseFormat('یکشنبه ۵ حمل ۱۴۰۳', 'EEEE d MMMM yyyy'); // 1403/01/05
PersianDate.parseFormat('1403/01/04 2:30 ب.ظ', 'yyyy/MM/dd h:mm a'); // with 14:30
```

- The pattern uses the `format` tokens and quoting, so `parseFormat(d.format(p), p) == d` for every pattern with year, month, and day.
- `MMMM` accepts Persian, Latin, and Dari month names, case-insensitive for Latin.
- `EEEE` and `E` are read and must agree with the date, or parsing fails.
- Digits may be ASCII, Persian, or Arabic-Indic. `ي`, `ك`, `ة`, zero-width non-joiners, and repeated spaces are normalized in both input and names.
- Takes `era` like `parse`.
- `parseFormat` throws `FormatException`; `tryParseFormat` returns null.

## Done when

- Round-trip tests over every token and both eras, plus tests for Arabic letters, ZWNJ, Latin names, and mismatched weekdays.
- README section and quick reference row.
