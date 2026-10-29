## 0.5.1

### Changed

* README: the introduction says up front that holidays are calculated offline on the device or fetched from an online source, and the offline description says the Hijri dates come from the official calendars up to Jalali 1405.

## 0.5.0

### Added

* `isWorkingDay`, `addWorkingDays`, and `workingDaysBetween` on `OfflineHolidaySource`: working days around official holidays and a weekend you choose, Friday by default.

### Fixed

* Hijri holidays up to Jalali 1405 follow Iran's official record, through `jalali_date` 1.3.0. Some holidays in past years move by a day, for example 21 Ramadan in 1381, 1386, and 1390, and Ashura in 1383.

## 0.4.0

### Breaking

* `OfficialHoliday.iran` names the holidays in religiously neutral wording instead of the official text, so `OfflineHolidaySource` descriptions change.
  Honorifics are dropped, "رحلت" is "درگذشت", Shia Imams are named by their place among the Shia Imams, and the state holidays describe the event: `عاشورای حسینی` is now `عاشورا`, `پیروزی انقلاب اسلامی` is now `سالروز انقلاب ۱۳۵۷`.
  Pass your own `holidays` list to keep the official text. Online sources are unchanged.

## 0.3.0

### Breaking

* The package is renamed from `jalali_holidays` to `iranian_holidays`.
  Depend on `iranian_holidays` and import `package:iranian_holidays/iranian_holidays.dart`; the API is otherwise the same.
* `HijriDate` comes from `jalali_date` 1.2.0 and is re-exported unchanged in name: the constructor is no longer `const` and throws `ArgumentError` for a day that does not exist on Iran's official calendar.
  Use `HijriDate(1448, 1, 10)` instead of `const HijriDate(1448, 1, 10)`.

### Changed

* The Hijri calendar moved to `jalali_date` as `HijriDate` and `IranianHijri`; holiday dates are unchanged.
* Requires `jalali_date` ^1.2.0.

## 0.2.0

* `OfflineHolidaySource`: Iran's 26 official holidays and Fridays, calculated on the device with no network.
  Hijri holidays come from a predicted crescent sighting in Iran (Meeus positions, Yallop criterion), corrected to the published calendar from 1387 to 1406.
  `hijriMonthStarts` takes announced month starts, `holidays` a changed holiday list.
* `OfficialHoliday` and `OfficialHoliday.iran`, the list of official holidays.
* `HijriDate` and `OfflineHolidaySource.hijriDate` for the Iranian Hijri date of a day.
* `FallbackHolidaySource`: an online source first, another source when it fails.
* README lists the offline holidays of 1405 and 1406.

## 0.1.0

* `HolidaySource` interface, `HolidayDay`, and `HolidayEvent`.
* `HolidayApiIrSource` for the free holidayapi.ir service.
* `CalendarificSource` and `GoogleCalendarSource` for services that need your own API key, with `baseUri` for a proxy.
* `CachedHolidaySource` to avoid repeated requests.
