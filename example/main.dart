import 'package:jalali_date/jalali_date.dart';

void main() {
  // Gregorian to Jalali.
  final nowruz = PersianDate.fromGregorian(2021, 3, 21);
  print(nowruz); // 1400/01/01
  print(nowruz.format('EEEE d MMMM yyyy')); // یکشنبه 1 فروردین 1400
  print(nowruz.toString(persianDigits: true)); // ۱۴۰۰/۰۱/۰۱

  // Jalali to Gregorian.
  print(PersianDate(1357, 11, 22).toDateTime()); // 1979-02-11 00:00:00.000

  // Parsing, with Persian or Latin digits.
  final parsed = PersianDate.parse('۱۴۰۳/۰۶/۳۱');
  print(parsed.addMonths(1)); // 1403/07/30, the day is clamped

  // Leap years, month lengths, and anchors.
  final esfand = PersianDate(1399, 12, 1);
  print(esfand.isLeapYear); // true
  print(esfand.monthLength); // 30
  print(esfand.lastDayOfMonth); // 1399/12/30

  // A month grid for a date picker, Saturday first.
  final first = PersianDate(1403, 7, 1);
  final blanks = first.weekdayPersian - 1;
  print(
      '${first.format('MMMM yyyy')}: $blanks blank, ${first.monthLength} days');

  // Ranges.
  final range =
      PersianDateRange(PersianDate(1403, 1, 1), PersianDate(1403, 1, 13));
  print('${range.length} days of Nowruz holidays');

  // Current date and time.
  print(DateTime.now().toPersianDate().format("yyyy/MM/dd 'ساعت' HH:mm"));
}
