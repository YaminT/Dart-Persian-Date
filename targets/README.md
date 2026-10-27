# Targets

Work planned after surveying Persian and lunar Hijri date libraries for Dart, JavaScript, Python, PHP, .NET, Go, Rust, Java/Kotlin, and Swift (October 2026).
Each file is one target with its reason, the API it adds, and when it is done.

## jalali_date (Dart)

| # | Target | Kind |
| - | ------ | ---- |
| 01 | [Official Hijri month table](01-official-hijri-table.md) | Bug fix, done |
| 02 | [Parsing with a pattern and month names](02-pattern-parsing.md) | Feature, done |
| 03 | [Relative time in Persian](03-relative-time.md) | Feature, done |
| 04 | [Numbers and dates in Persian words](04-persian-words.md) | Feature, done |
| 05 | [Day periods](05-day-periods.md) | Feature, done |
| 06 | [Differences in months and years](06-month-year-difference.md) | Feature, done |
| 07 | [Moment of Nowruz](07-nowruz-moment.md) | Feature, done |
| 08 | [Leap years after 1500](08-leap-year-notes.md) | Documentation, done |

## iranian_holidays (Dart)

| # | Target | Kind |
| - | ------ | ---- |
| 09 | [Working days](09-working-days.md) | Feature |

## npm

| # | Target | Kind |
| - | ------ | ---- |
| 10 | [iranian-calendar for npm](10-npm-iranian-calendar.md) | New package |

## Considered and not adopted

- Time zones (ptime, persian-date-native, @doranjs/core): Dart has no time zone database, and Iran has kept UTC+3:30 all year only since 2022, so a fixed offset would be wrong for older dates. `PersianDate.fromDateTime` already keeps whatever zone the `DateTime` has.
- A leap-year rule option (persian-date, jalali-js `engine: 'astronomical'`): the rules agree with the University of Tehran for every published year; see [08](08-leap-year-notes.md).
- Umm al-Qura and tabular Hijri calendars (hijri, hijridate, ICU): the package is about Iran's calendar, and the `hijri` package covers Umm al-Qura for Dart.
- Natural-language parsing such as `دو هفته دیگر` (@doranjs/nlp): large, ambiguous, and better as a separate package if anyone asks.
- Laravel or ASP.NET style validation rules (verta, DNTPersianUtils.Core): `tryParse` is the validation primitive in Dart; form packages can call it.
- Pashto and Kurdish month names (hekmatinasser/jalali): no source to check the spellings against; revisit when a user who reads them asks.
- Locale objects with replaceable names (react-date-object): `format` with quoted literals and the static name lists already cover custom labels.
