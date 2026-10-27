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
offline.workingDaysBetween(PersianDate(1405, 1, 1), PersianDate(1405, 1, 31)); // count
offline.isWorkingDay(PersianDate(1405, 1, 13)); // false, Nature Day
```

- Synchronous on `OfflineHolidaySource`; the weekend is Friday by default, with an option for Thursday and Friday since many offices close on Thursdays.
- Negative counts go back.
- Ranges are inclusive at the start and exclusive at the end, and the doc comment says so.

## Done when

- Tests across Nowruz, a lunar holiday, and a year boundary.
- README section in `packages/iranian_holidays`.
