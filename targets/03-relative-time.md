# 03: Relative time in Persian

## Why

"۳ روز پیش", "دیروز", "ماه آینده" is the most common date text in Persian apps.
verta `formatDifference`, morilog `ago()`, DNTPersianUtils.Core `ToFriendlyPersianDateTextify`, persian_number_utility `getDifferenceDateString`, persianist `fromNow`, and persian-tools `timeAgo` all have it.
In Dart there is no `Intl.RelativeTimeFormat`, so Flutter apps write it by hand.

## API

```dart
final today = PersianDate(1405, 8, 5);
PersianDate(1405, 8, 4).relativeTo(today); // دیروز
PersianDate(1405, 8, 2).relativeTo(today); // 3 روز پیش
PersianDate(1405, 9, 5).relativeTo(today); // ماه آینده
PersianDate(1403, 8, 5).relativeTo(today, persianDigits: true); // ۲ سال پیش
date.fromNow(); // relativeTo(PersianDate.now())
```

- Date-only dates count calendar days: today, yesterday (دیروز), tomorrow (فردا), the day before yesterday (پریروز), the day after tomorrow (پس‌فردا), then days, weeks, months, and years, with months and years counted on the Jalali calendar (target 06).
- When both dates have a time, differences under a day use seconds, minutes, and hours: `همین الان`, `۵ دقیقه پیش`, `۲ ساعت بعد`.
- Wording follows CLDR `fa` relative time (`پیش`, `بعد`, `دیروز`, `فردا`, `ماه گذشته`, `ماه آینده`) so it reads like `Intl.RelativeTimeFormat('fa')` in browsers.
  CLDR 49 writes future days with `دیگر` (`3 روز دیگر`) and future weeks, months, and years with `بعد`; every string was checked against Node's `Intl`.
- `numeric: true` always writes a number (`1 روز پیش` instead of `دیروز`), like `Intl.RelativeTimeFormat`'s `numeric: 'always'`.

## Done when

- Tests at each unit boundary, in both directions, and with and without time.
- README section.
