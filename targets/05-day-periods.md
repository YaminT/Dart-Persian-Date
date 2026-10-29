# 05: Day periods

## Why

`a` writes `ق.ظ` or `ب.ظ`, but spoken and written Persian usually says `۸ صبح`, `۴ عصر`, `۱۱ شب`.
ptime (Go) has `DayTime()` with eight periods; CLDR has `fa` day periods that `Intl.DateTimeFormat` uses with `dayPeriod`.

## API

```dart
PersianDate.withTime(1403, 1, 4, 8, 0).format('h B'); // 8 صبح
PersianDate.withTime(1403, 1, 4, 16, 0).format('h B'); // 4 عصر
PersianDate.withTime(1403, 1, 4, 23, 0).format('h B'); // 11 شب
PersianDate.withTime(1403, 1, 4, 12, 30).format('h:mm BBBB'); // 12:30 بعدازظهر
date.dayPeriod; // صبح
```

- Token `B` and getter `dayPeriod` from CLDR 49 `fa` (`dayPeriodRuleSet` and the abbreviated names), so the text matches `Intl.DateTimeFormat('fa', {dayPeriod: 'short'})`: نیمه‌شب 0 to 1, بامداد 1 to 4, صبح 4 to 12, ظهر 12 to 13, عصر 13 to 19, شب 19 to 24.
- Token `BBBB` uses the wide names, which differ only at 12 to 13 (بعدازظهر), matching `dayPeriod: 'long'`.
- Throws `StateError` on a date-only instance, like the other time tokens.
- `B` is a new token; quote it to keep it literal.

## Done when

- Tests at every boundary hour and for midnight and noon.
- README token table row.
