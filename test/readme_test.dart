// Pins the outputs shown in README.md and the library doc.
import 'dart:convert';

import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  test('Persian section and library doc', () {
    final date = PersianDate.fromGregorian(2021, 3, 21);
    expect('$date', '1400/01/01');
    expect(date.format('EEEE d MMMM yyyy'), 'یکشنبه 1 فروردین 1400');
    expect(date.toString(persianDigits: true), '۱۴۰۰/۰۱/۰۱');
    expect(date.addMonths(1).toString(persianDigits: true), '۱۴۰۰/۰۲/۰۱');
    expect(PersianDate.parse('۱۳۵۷/۱۱/۲۲').toDateTime(), DateTime(1979, 2, 11));
    expect(PersianDate.parse('1357/11/22').toDateTime(), DateTime(1979, 2, 11));
  });

  test('date-only and time of day', () {
    final date = PersianDate.withTime(1403, 1, 4, 9, 5);
    expect(date.hasTime, isTrue);
    expect(date.hour, 9);
    expect(date.addDays(1).hasTime, isFalse);
    expect(PersianDate(1403, 1, 4).hasTime, isFalse);
  });

  test('parsing', () {
    expect(PersianDate.parse('1403/01/01').hasTime, isFalse);
    expect(PersianDate.parse('1403-1-1').hasTime, isFalse);
    expect(PersianDate.parse('۱۴۰۳/۰۱/۰۱ ۱۴:۳۰').hasTime, isTrue);
    expect(PersianDate.parse('1403-01-01T14:30:15').second, 15);
    expect(PersianDate.tryParse('1400/12/30'), isNull);
    final d = PersianDate(1403, 1, 4);
    expect(PersianDate.parse(d.format('yyyy/MM/dd')), d);
    expect(PersianDate.parse(d.toJson()), d);
  });

  test('date arithmetic', () {
    final date = PersianDate(1403, 6, 31);
    expect('${date.addDays(1)}', '1403/07/01');
    expect('${date.addMonths(1)}', '1403/07/30');
    expect('${PersianDate(1403, 12, 30).addYears(1)}', '1404/12/29');
    expect(
        PersianDate(1404, 1, 1).differenceInDays(PersianDate(1403, 1, 1)), 366);
    expect(PersianDate(1405, 8, 5).differenceInMonths(PersianDate(1405, 2, 20)),
        5);
    expect(
        PersianDate(1400, 12, 29).differenceInYears(PersianDate(1370, 12, 30)),
        30);
  });

  test('relative time', () {
    final today = PersianDate(1405, 8, 5);
    expect(PersianDate(1405, 8, 4).relativeTo(today), 'دیروز');
    expect(PersianDate(1405, 8, 2).relativeTo(today), '3 روز پیش');
    expect(PersianDate(1405, 9, 5).relativeTo(today), 'ماه آینده');
    expect(PersianDate(1403, 8, 5).relativeTo(today, persianDigits: true),
        '۲ سال پیش');
    expect(
        PersianDate(1405, 8, 4).relativeTo(today, numeric: true), '1 روز پیش');
    expect(
        PersianDate.withTime(1405, 8, 5, 9, 30)
            .relativeTo(PersianDate.withTime(1405, 8, 5, 12, 0)),
        '2 ساعت پیش');
  });

  test('comparing dates', () {
    final last = PersianDate(1399, 12, 30);
    final first = PersianDate(1400, 1, 1);
    expect(last < first, isTrue);
    expect(last.isBefore(first), isTrue);
    expect(first == PersianDate.fromGregorian(2021, 3, 21), isTrue);
    expect(first.isSameMonth(PersianDate(1400, 1, 31)), isTrue);
  });

  test('leap years, months, and seasons', () {
    final date = PersianDate(1403, 7, 1);
    expect(date.isLeapYear, isTrue);
    expect(date.monthLength, 30);
    expect(date.dayOfYear, 187);
    expect(date.quarter, 3);
    expect(date.seasonName, 'پاییز');
    expect('${date.lastDayOfMonth}', '1403/07/30');
    expect('${date.lastDayOfYear}', '1403/12/30');
  });

  test('Persian names', () {
    final date = PersianDate.fromGregorian(1979, 2, 11);
    expect(date.monthName, 'بهمن');
    expect(date.monthNameLatin, 'Bahman');
    expect(date.monthNameDari, 'دلو');
    expect(date.weekday, 7);
    expect(date.weekdayPersian, 2);
    expect(date.weekdayName, 'یکشنبه');
    expect(date.weekdayNameShort, 'ی');
  });

  test('Persian digits', () {
    final date = PersianDate(1403, 1, 4);
    expect(date.toString(persianDigits: true), '۱۴۰۳/۰۱/۰۴');
    expect(date.format('d MMMM yyyy', persianDigits: true), '۴ فروردین ۱۴۰۳');
    expect(toPersianDigits('12:30'), '۱۲:۳۰');
    expect(toLatinDigits('۱۴۰۳'), '1403');
  });

  test('Persian words', () {
    expect(PersianDate(1403, 5, 24).format('EEEE dw MMMM yw'),
        'چهارشنبه بیست و چهارم مرداد هزار و چهارصد و سه');
    expect(toPersianWords(1403), 'هزار و چهارصد و سه');
    expect(toPersianWords(30, ordinal: true), 'سی‌ام');
  });

  test('format', () {
    final date = PersianDate.withTime(1400, 1, 1, 14, 5);
    expect(date.format('d MMMM yyyy'), '1 فروردین 1400');
    expect(date.format('EEEE yyyy/MM/dd'), 'یکشنبه 1400/01/01');
    expect(date.format('h:mm a'), '2:05 ب.ظ');
    expect(date.format("'ساعت' HH:mm"), 'ساعت 14:05');
    expect(date.format("d 'o''clock'"), "1 o'clock");
    expect(date.format("'Q' Q"), 'Q 1');
  });

  test('Shahanshahi years', () {
    final date = PersianDate(1405, 1, 4);
    expect(date.shahanshahiYear, 2585);
    expect(date.format('d MMMM yyyy', era: JalaliEra.shahanshahi),
        '4 فروردین 2585');
    expect(date.toString(era: JalaliEra.shahanshahi), '2585/01/04');
    expect('${PersianDate.parse('2585/01/04', era: JalaliEra.shahanshahi)}',
        '1405/01/04');
    expect(date.format("yyyy 'شاهنشاهی'", era: JalaliEra.shahanshahi),
        '2585 شاهنشاهی');
  });

  test('Hijri calendar', () {
    final ashura = PersianDate(1405, 4, 4).toHijri();
    expect('$ashura', '10 محرم 1448');
    expect(ashura.format('EEEE d MMMM yyyy'), 'پنجشنبه 10 محرم 1448');
    expect('${HijriDate(1447, 10, 1).toPersianDate()}', '1405/01/01');
    expect(
        DateTime(2026, 6, 25).toHijriDate().format('yyyy/MM/dd'), '1448/01/10');
    expect(HijriDate(1447, 12, 1).monthLength, 29);
    final announced = IranianHijri(
      monthStarts: {(1448, 1): PersianDate(1405, 3, 27)},
    );
    expect('${announced.fromPersianDate(PersianDate(1405, 4, 5))}',
        '10 محرم 1448');
    expect(HijriDate.min.format('yyyy/MM/dd'), '-0064/10/05');
    expect(HijriDate.max.format('yyyy/MM/dd'), '3274/12/10');
  });

  test('JSON', () {
    final date = PersianDate(1403, 1, 4);
    expect(jsonEncode({'date': date}), '{"date":"1403-01-04"}');
    expect('${PersianDate.fromJson('1403-01-04')}', '1403/01/04');
  });

  test('ranges', () {
    final range =
        PersianDateRange(PersianDate(1403, 1, 1), PersianDate(1403, 1, 13));
    expect(range.length, 13);
    expect(range.contains(PersianDate(1403, 1, 4)), isTrue);
    expect(range.days.first.format('E d'), 'چ 1');
    expect(
        PersianDate(1403, 12, 29).daysUntil(PersianDate(1404, 1, 1)).length, 3);
  });

  test('date picker recipe', () {
    List<PersianDate?> monthCells(int year, int month) {
      final first = PersianDate(year, month, 1);
      return [
        for (var i = 1; i < first.weekdayPersian; i++) null,
        ...first.daysUntil(first.lastDayOfMonth),
      ];
    }

    final header = [
      for (var i = 0; i < 7; i++)
        PersianDate(1403, 1, 4).addDays(i).weekdayNameShort,
    ];
    expect(header, ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']);
    // 1403/07/01 is a Sunday: one blank, then 30 days.
    final cells = monthCells(1403, 7);
    expect(cells.first, isNull);
    expect(cells[1], PersianDate(1403, 7, 1));
    expect(cells.length, 31);
    // 1403/01/01 is a Wednesday: four blanks.
    expect(monthCells(1403, 1).takeWhile((c) => c == null).length, 4);
  });
}
