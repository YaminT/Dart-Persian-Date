## 0.1.2

* Importing only `toJalali` and `fromJalali` no longer bundles the Hijri table and the crescent calculation: 1.2 KB gzipped instead of 4.4 KB.
* Month starts predicted through Dhu al-Hijjah 1550 (past Jalali 1500) are stored instead of being calculated on first use: the first `holidaysOfYear(1420)` takes 2.5 ms instead of 87 ms in Node. Months after 1550 are still calculated, and every day is the same as before. `toHijri` and `holidaysOfYear` bundles grow by about 250 bytes gzipped.
* Validation no longer builds an array for every call.

## 0.1.1

* README: an npm badge, and a note that the holidays are calculated offline only, with a pointer to the Dart package for online sources.

## 0.1.0

* First release: Iran's official lunar Hijri calendar (`IranianHijri`, `toHijri`, `fromHijri`), the official holidays with Persian and English names (`holidaysOfYear`, `holidaysOn`), working days (`isWorkingDay`, `addWorkingDays`, `workingDaysBetween`), and Jalali conversion (`toJalali`, `fromJalali`). The same days as the Dart packages jalali_date 1.3.0 and iranian_holidays 0.5.0.
