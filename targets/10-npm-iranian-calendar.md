# 10: iranian-calendar for npm

New package. Start only after target 01 is done, so the port carries the corrected table.

Status: built in `packages/iranian_calendar_js/` as version 0.1.0. Changes from the plan:
- No dependencies at all: the Jalali conversion is the same jalaali-js port as the Dart package, a few dozen lines.
- No `@internationalized/date` calendar: React Aria formats calendar cells with `Intl` and the calendar's identifier, so a custom Hijri calendar would show `Intl`'s day numbers, not Iran's. The README says so.
- The cross-language fixtures are every month start from 1200 to 1600 and the holidays of 1395 to 1410, written by `tool/npm_fixtures`; the npm tests match them exactly.

## Does JavaScript need it?

Not as another Jalali date library:

- `Intl.DateTimeFormat` formats `fa-IR` Jalali dates and matches this package for every day from 1300 to 1500.
- Temporal (Chrome 144, Firefox 139, Node 26; Safari still in preview) does Jalali arithmetic with `calendar: 'persian'`.
- `Intl.RelativeTimeFormat('fa')` writes relative time.
- jalaali-js (about 660k weekly downloads) and date-fns-jalali (about 13M weekly, through react-day-picker) cover conversion, formatting, and parsing.

What JavaScript lacks is Iran's official lunar Hijri calendar and the holidays that depend on it:

- None of the `Intl` and Temporal Islamic calendars matches Iran: for 2026-03-21, which Iran counts as 1 Shawwal 1447, they give 2 or 3 Shawwal.
- `date-holidays` (about 625k weekly downloads) puts Eid al-Fitr 1447 on 2026-03-20, a day early for Iran.
- Developers scrape time.ir or hard-code yearly JSON: Stack Overflow 77423818 and 61188618, many small scraper repositories, and holiday requests in react-multi-date-picker #224, #333, #7 and jalali-moment #141.
- The npm packages with Iran data (iran-hijri, iran-holidays, @doranjs/holidays, @jalali-js/holidays, @avan-persian/holidays) each get under 150 weekly downloads, cover a few years from a table, and fall back to tabular or single-city estimates.
  None calculates crescent visibility at several cities with Yallop's criterion, and none has an API for announced month starts.

So the package is scoped to what the platform and existing packages do not do.

## Scope

1. `IranianHijri`: the official month table (target 01), the crescent prediction beyond it, and announced month starts.
   - Conversion to and from Jalali and Gregorian.
   - `monthStart`, `monthLength`, and Persian month names.
2. Offline Iranian holidays: the same list and rules as `OfflineHolidaySource`, with Fridays optional, plus working days (target 09).
3. Interop instead of a new date type:
   - Accepts and returns `{year, month, day}` objects, `Date`, and `Temporal.PlainDate` when Temporal exists.
   - An `@internationalized/date` custom `Calendar` (`IranianHijriCalendar`), so React Aria and React Spectrum pickers can show it.
4. Jalali arithmetic comes from jalaali-js (dependency) or the platform; the package does not ship its own Jalali formatter.

Out of scope: a Jalali `Date` wrapper, a pattern formatter, a picker, and online holiday sources.
Those exist already, or are thin wrappers that users can write themselves.

## Shape

- Name: `iranian-calendar` (free on npm on 2026-10-27; `iranian-hijri` and `iranian-holidays` are also free).
- TypeScript, ESM only, `sideEffects: false`, no dependencies except jalaali-js. The crescent code is only loaded when a date outside the table is asked for, if bundlers can split it.
- Lives in this repository under `packages/iranian_calendar_js/` so both ports share test data.
  A generated JSON of every month start from 1265 to 1500 (table plus prediction) is the cross-language fixture, and both test suites check against it.
- Apache-2.0, like the Dart packages.

## Done when

- Every month start matches the Dart package from 1265 to 1500, and the official record exactly.
- Holidays for Jalali 1400 to 1410 match `OfflineHolidaySource`.
- The README has a short Persian introduction like the Dart one and examples for plain objects, Temporal, and `@internationalized/date`.
- CI runs the tests, and publishing uses npm provenance from GitHub Actions.
