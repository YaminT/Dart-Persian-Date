# 06: Differences in months and years

## Why

Age, tenure, and contract terms are counted in Jalali months and years: someone born on 1370/12/30 turns 30 on 1400/12/29 when 1400 has no 30 Esfand.
`differenceInDays` cannot answer that.
date-fns-jalali `differenceInMonths` and `intervalToDuration`, Temporal `until({largestUnit: 'months'})` with the `persian` calendar, DNTPersianUtils.Core `GetAge`, and persianist `jalaliAge` all can.

## API

```dart
PersianDate(1405, 8, 5).differenceInMonths(PersianDate(1405, 2, 20)); // 5
PersianDate(1405, 8, 5).differenceInYears(PersianDate(1370, 12, 30)); // 34
PersianDate(1400, 12, 29).differenceInYears(PersianDate(1370, 12, 30)); // 30
```

- Whole months or years from `other` to this date, negative when this date is earlier, matching `differenceInDays`.
- A month is complete when `other.addMonths(n)` (which clamps) is not after this date, so the results agree with `addMonths` and `addYears` and with Temporal's `persian` calendar.
- Time of day is ignored, like the other comparisons.

## Done when

- Tests against Temporal (`temporal-polyfill/full`, calendar `persian`) for a sweep of date pairs around month ends and 30 Esfand, generated once and checked in as data.
- README rows.
