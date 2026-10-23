import 'package:jalali_date/jalali_date.dart';
import 'package:jalali_holidays/jalali_holidays.dart';

Future<void> main() async {
  // Choose the source explicitly and read its notice first.
  final api = HolidayApiIrSource();
  print('${api.name}: ${api.notice}');

  final source = CachedHolidaySource(api);
  final nowruz = await source.day(PersianDate(1403, 1, 1));
  print('${nowruz.date} holiday: ${nowruz.isHoliday}');
  for (final event in nowruz.holidays) {
    print(event.description);
  }
  api.close();
}
