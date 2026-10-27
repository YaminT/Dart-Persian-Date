# 04: Numbers and dates in Persian words

## Why

Formal Persian text, invoices, and contracts write dates in words: `دوشنبه بیست و چهارم مرداد هزار و چهارصد و سه`.
verta `formatWord`, persian_number_utility `toPersianDateStr(strDay: true)`, persian-tools `numberToWords(n, ordinal: true)`, and DNTPersianUtils.Core `NumberToText` have it.
No Dart date package combines it with its own formatter.

## API

```dart
toPersianWords(1403); // هزار و چهارصد و سه
toPersianWords(24, ordinal: true); // بیست و چهارم
toPersianWords(1, ordinal: true); // یکم
PersianDate(1403, 5, 24).format('EEEE dw MMMM yw'); // چهارشنبه بیست و چهارم مرداد هزار و چهارصد و سه
```

- `toPersianWords(int, {ordinal})` for any `int`, including zero and negative numbers (`منفی`).
- Ordinals: `یکم` (not `اول`) as official letters write dates, `سی‌ام` with a ZWNJ after vowel-final words, `سوم`, `سی و سوم`.
- New `format` tokens: `dw` (ordinal day in words) and `yw` (year in words); `yw` follows `era`.
  `w` is not a token today, so a pattern with literal `dw` or `yw` changes; the CHANGELOG says to quote it, as 1.1.0 did for `Q` and `E`.
- `HijriDate.format` gets `dw` and `yw` too.

## Done when

- Tests for 0 to 1000 against a hand-checked list of tricky values (11 to 19, hundreds such as دویست and سیصد, thousands, ordinals of 2, 3, and 30).
- README section and quick reference rows.
