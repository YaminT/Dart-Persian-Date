import 'package:jalali_date/jalali_date.dart';

void main() {
  // Gregorian to Jalali.
  final nowruz = PersianDate.fromGregorian(2021, 3, 21);
  print(nowruz); // 1400/01/01
  print(nowruz.format('EEEE d MMMM yyyy')); // یکشنبه 1 فروردین 1400

  // Jalali to Gregorian.
  final date = PersianDate(1357, 11, 22);
  print(date.toDateTime()); // 1979-02-11 00:00:00.000

  // Leap years and month lengths.
  print(PersianDate(1399, 12, 1).isLeapYear); // true
  print(PersianDate(1399, 12, 1).monthLength); // 30

  // Current date and time.
  print(PersianDate.now().toString(showTime: true));
}
