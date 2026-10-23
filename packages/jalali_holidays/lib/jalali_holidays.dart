/// Iranian holidays and events for `jalali_date` dates.
///
/// Pick a [HolidaySource] explicitly; none is built in by default. Read its
/// [HolidaySource.notice] first.
///
/// ```dart
/// final source = CachedHolidaySource(HolidayApiIrSource());
/// final day = await source.day(PersianDate(1403, 1, 1));
/// print(day.isHoliday); // true
/// print(day.holidays.first.description); // جشن نوروز/جشن سال نو
/// ```
library jalali_holidays;

export 'src/cached_holiday_source.dart';
export 'src/holiday.dart';
export 'src/holiday_source.dart';
export 'src/holidayapi_ir.dart';
