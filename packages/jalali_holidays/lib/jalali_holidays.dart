/// Iranian holidays and events for `jalali_date` dates.
///
/// Pick a [HolidaySource] explicitly and read its [HolidaySource.notice]
/// first. [OfflineHolidaySource] calculates the official holidays on the
/// device, including the lunar Hijri ones. [HolidayApiIrSource] needs no
/// key; [CalendarificSource] and [GoogleCalendarSource] need your own API
/// key. [FallbackHolidaySource] combines an online and the offline source.
///
/// ```dart
/// final offline = OfflineHolidaySource();
/// print(offline.dayOf(PersianDate(1405, 4, 4)).holidays.first.description);
/// // عاشورای حسینی
///
/// final source = CachedHolidaySource(HolidayApiIrSource());
/// final day = await source.day(PersianDate(1403, 1, 1));
/// print(day.isHoliday); // true
/// print(day.holidays.first.description); // جشن نوروز/جشن سال نو
/// ```
library jalali_holidays;

export 'package:jalali_date/jalali_date.dart' show HijriDate;

export 'src/cached_holiday_source.dart';
export 'src/calendarific.dart';
export 'src/fallback_holiday_source.dart';
export 'src/holiday.dart';
export 'src/holiday_source.dart';
export 'src/google_calendar.dart';
export 'src/holidayapi_ir.dart';
export 'src/offline.dart';
