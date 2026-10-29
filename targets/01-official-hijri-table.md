# 01: Official Hijri month table

Bug fix in `lib/src/hijri.dart`.

Status: done, released with jalali_date 1.3.0 and iranian_holidays 0.5.0.
Step 3 changed nothing: no threshold or city set does better, because the published calendar sometimes starts a month when the crescent cannot be seen from Iran (Yallop q about -0.3 to -0.6) and waits after other evenings with the same q.
Every month the prediction gets late from 1427 on matches Umm al-Qura instead; with too few cases to model, this stays a note.

## Problem

`HijriDate` starts some months a day off from Iran's official calendar.
The University of Tehran's 1405 calendar starts Jumada al-Ula 1448 on 1405/07/20; the package says 1405/07/21, which moves Hazrat Zeinab's birthday (Nurse's Day).
The built-in table was checked only for months with a holiday, so months without one were never compared.

Against [roozbehp/qamari](https://github.com/roozbehp/qamari) `consolidated.txt` (CC0, 1265/1 to 1447/10, University of Tehran calendars since 1423) and the 1405 calendar, 17 months since 1423 differ by one day:

- Package one day late: 1428/9, 1430/5, 1431/11, 1434/11, 1436/11, 1437/11, 1446/5, 1447/5, 1448/5.
- Package one day early: 1423/9, 1424/2, 1424/12, 1425/5, 1425/8, 1426/1, 1426/11, 1432/9.

Before 1423, 265 more months differ; the sources there are newspapers and historical records.

## Change

1. Store the official record as data, independent of the prediction: the first day of 1265/1 and one 12-bit month-length mask per Hijri year, through the start of 1448/10.
   The prediction is used only outside that range, and month starts announced later than the University of Tehran calendar (the 1449 rows already in the table) stay as single corrections.
2. Where qamari marks a month with `*`, the day the month was actually observed wins over the precalculated calendar, because that is the day holidays were kept.
   This moves Ramadan 1432 from 1390/05/10 to 1390/05/11.
3. Re-tune the visibility threshold `_qVisible` and the city list against the official months 1427 to 1448, where every miss so far is the package being late.
   Keep the change only if it improves the match without losing months it matches today.
4. A tool, `tool/hijri_table/`, that regenerates the table from `consolidated.txt` plus a supplement file for months after it, so a new University of Tehran calendar is one line per month.
5. A test that checks every month start against a copy of `consolidated.txt` under `test/`, and the 1405 months.
6. README and doc comments: say where the table comes from, its range, and that before 1423 the data comes from historical sources; credit qamari in THIRD_PARTY_NOTICES.md.

## Done when

- Every month start from 1265/1 to 1448/10 matches the official record.
- `dart test` and `dart analyze` pass, and the iranian_holidays tests still pass (some holiday days before 1430 may move by a day; check each one).
- The CHANGELOG says which dates moved.
