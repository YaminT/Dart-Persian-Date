# 09: Working days

Feature for `iranian_holidays`.

## Why

Delivery dates, deadlines, and SLAs in Iran are counted in working days.
DNTPersianUtils.Core has `PersianBusinessDaysContext`, and persianist has `addJalaliBusinessDays` and `diffJalaliBusinessDays`.
`iranian_holidays` already knows which days are off, offline, so it can do this without a network.

## API

```dart
final offline = OfflineHolidaySource();
offline.addWorkingDays(PersianDate(1405, 1, 1), 3); // 1405/01/08: 1 to 4 Farvardin are off, 7 is a Friday
offline.workingDaysBetween(PersianDate(1405, 1, 1), PersianDate(1405, 1, 8)); // 3
offline.isWorkingDay(PersianDate(1405, 1, 13)); // false, Nature Day
```

- Synchronous on `OfflineHolidaySource`; `weekend` is a set of `DateTime` weekdays, Friday by default, so offices that close on Thursdays pass `{DateTime.thursday, DateTime.friday}`.
- Negative counts go back.
- `workingDaysBetween` counts the end but not the start, in both directions, so it undoes `addWorkingDays`; the target first said inclusive start and exclusive end, which breaks that when the start is a day off.

## Done when

- Tests across Nowruz, a lunar holiday, and a year boundary.
- README section in `packages/iranian_holidays`.
