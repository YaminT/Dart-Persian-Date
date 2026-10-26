import 'package:jalali_date/jalali_date.dart';
import 'package:iranian_holidays/iranian_holidays.dart';

Future<void> main() async {
  // Offline: calculated on the device, no network.
  final offline = OfflineHolidaySource();
  for (final day in offline.holidaysOf(1405)) {
    print('${day.date} ${day.holidays.map((e) => e.description).join(', ')}');
  }
  print(offline.hijriDate(PersianDate(1405, 1, 1))); // 1 شوال 1447

  // Online first, offline when the request fails. Choose the online source
  // explicitly and read its notice first.
  final api = HolidayApiIrSource();
  print('${api.name}: ${api.notice}');
  final source = FallbackHolidaySource(CachedHolidaySource(api), offline);
  final nowruz = await source.day(PersianDate(1405, 1, 1));
  print('${nowruz.date} holiday: ${nowruz.isHoliday}');
  for (final event in nowruz.holidays) {
    print(event.description);
  }
  api.close();
}
