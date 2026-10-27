# 05: Day periods

## Why

`a` writes `ق.ظ` or `ب.ظ`, but spoken and written Persian usually says `۸ صبح`, `۴ عصر`, `۱۱ شب`.
ptime (Go) has `DayTime()` with eight periods; CLDR has `fa` day periods that `Intl.DateTimeFormat` uses with `dayPeriod`.

## API

```dart
PersianDate.withTime(1403, 1, 4, 8, 0).format('h B'); // 8 صبح
PersianDate.withTime(1403, 1, 4, 16, 0).format('h B'); // 4 بعدازظهر
PersianDate.withTime(1403, 1, 4, 23, 0).format('h B'); // 11 شب
date.dayPeriod; // صبح
```

- Token `B` and getter `dayPeriod`, from CLDR `fa` (`dayPeriodRules` and wide format names), so the text matches browsers: midnight `نیمه‌شب`, 04:00 to 12:00 `صبح`, noon `ظهر`, 12:00 to 17:00 `بعدازظهر`, 17:00 to 19:00 `عصر`, 19:00 to 04:00 `شب`.
  Check the current CLDR data before writing the table.
- Throws `StateError` on a date-only instance, like the other time tokens.
- `B` is a new token; quote it to keep it literal.

## Done when

- Tests at every boundary hour and for midnight and noon.
- README token table row.
