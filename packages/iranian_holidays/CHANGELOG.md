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
