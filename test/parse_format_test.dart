import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  group('parseFormat', () {
    test('examples', () {
      expect(PersianDate.parseFormat('۴ فروردین ۱۴۰۳', 'd MMMM yyyy'),
          PersianDate(1403, 1, 4));
      expect(PersianDate.parseFormat('1403 Farvardin 4', 'yyyy MMMM d'),
          PersianDate(1403, 1, 4));
      expect(PersianDate.parseFormat('1403 farvardin 4', 'yyyy MMMM d'),
          PersianDate(1403, 1, 4));
      expect(PersianDate.parseFormat('۵ حمل ۱۴۰۳', 'd MMMM yyyy'),
          PersianDate(1403, 1, 5));
      expect(PersianDate.parseFormat('14030104', 'yyyyMMdd'),
          PersianDate(1403, 1, 4));
      final time =
          PersianDate.parseFormat('1403/01/04 2:30 ب.ظ', 'yyyy/MM/dd h:mm a');
      expect(time, PersianDate(1403, 1, 4));
      expect((time.hasTime, time.hour, time.minute, time.second),
          (true, 14, 30, 0));
      expect(
          PersianDate.parseFormat('1403/01/04', 'yyyy/MM/dd').hasTime, isFalse);
      expect(
          PersianDate.parseFormat('1403/01/04 2:30 ب.ظ.', 'yyyy/MM/dd h:mm a')
              .hour,
          14);
      expect(PersianDate.parseFormat('-0061/01/01', 'yyyy/MM/dd'),
          PersianDate.min);
    });

    test('round trip for every token, digit style, and era', () {
      const patterns = [
        'yyyy/MM/dd',
        'yyyy-M-d',
        'yyyyMMdd',
        'd MMMM yyyy',
        'EEEE d MMMM yyyy',
        'E d MMMM yyyy',
        "'روز' D 'سال' yyyy، d MMMM، Q",
        'yyyy/MM/dd HH:mm:ss',
        'yyyy/MM/dd H:m:s',
        'd MMMM yyyy hh:mm a',
        'd MMMM yyyy h:mm B',
        'd MMMM yyyy h:mm BBBB',
      ];
      var date = PersianDate.withTime(1399, 11, 27, 0, 7, 9);
      for (var i = 0; i < 60; i++) {
        for (final pattern in patterns) {
          for (final era in JalaliEra.values) {
            for (final persianDigits in [false, true]) {
              final text =
                  date.format(pattern, era: era, persianDigits: persianDigits);
              final parsed = PersianDate.parseFormat(text, pattern, era: era);
              final reason = '$pattern: $text';
              expect(parsed, date, reason: reason);
              if (pattern.contains('H') || pattern.contains('h')) {
                expect(parsed.hour, date.hour, reason: reason);
                expect(parsed.minute, date.minute, reason: reason);
              }
              if (pattern.contains('s')) {
                expect(parsed.second, date.second, reason: reason);
              }
            }
          }
        }
        date = PersianDate.fromDateTime(
            date.toDateTime().add(const Duration(days: 23, minutes: 437)));
      }
    });

    test('Arabic letters, zero-width non-joiners, and spaces', () {
      final d = PersianDate(1403, 1, 7); // a Tuesday
      expect(
          PersianDate.parseFormat('سه‌شنبه ۷ فروردین ۱۴۰۳', 'EEEE d MMMM yyyy'),
          d);
      expect(
          PersianDate.parseFormat('سه شنبه 7 فروردین 1403', 'EEEE d MMMM yyyy'),
          d);
      expect(
          PersianDate.parseFormat('سهشنبه 7 فروردین 1403', 'EEEE d MMMM yyyy'),
          d);
      expect(
          PersianDate.parseFormat('  7   فروردين   1403 ', 'd MMMM yyyy'), d);
      expect(PersianDate.parseFormat('٧ فروردین ١٤٠٣', 'd MMMM yyyy'), d);
      expect(PersianDate.parseFormat('2 دي 1403', 'd MMMM yyyy'),
          PersianDate(1403, 10, 2));
      expect(
          PersianDate.parseFormat('یكشنبه 5 فروردین 1403', 'EEEE d MMMM yyyy'),
          PersianDate(1403, 1, 5));
    });

    test('Shahanshahi years', () {
      expect(
          PersianDate.parseFormat('4 فروردین 2585', 'd MMMM yyyy',
              era: JalaliEra.shahanshahi),
          PersianDate(1405, 1, 4));
    });

    test('day periods choose the hour', () {
      PersianDate p(String text) =>
          PersianDate.parseFormat('1403/01/04 $text', 'yyyy/MM/dd h:mm B');
      expect(p('8:00 صبح').hour, 8);
      expect(p('4:00 عصر').hour, 16);
      expect(p('11:00 شب').hour, 23);
      expect(p('12:30 ظهر').hour, 12);
      expect(p('12:15 نیمه‌شب').hour, 0);
      expect(p('2:00 بامداد').hour, 2);
      expect(p('8:00 شب').hour, 20);
      expect(
          PersianDate.tryParseFormat(
              '1403/01/04 8:00 ظهر', 'yyyy/MM/dd h:mm B'),
          isNull);
    });

    test('invalid input', () {
      const p = 'EEEE d MMMM yyyy';
      expect(PersianDate.tryParseFormat('دوشنبه 7 فروردین 1403', p), isNull);
      expect(PersianDate.tryParseFormat('30 اسفند 1403', 'd MMMM yyyy'),
          isNotNull);
      expect(
          PersianDate.tryParseFormat('30 اسفند 1404', 'd MMMM yyyy'), isNull);
      expect(PersianDate.tryParseFormat('4 Farvardinn 1403', 'd MMMM yyyy'),
          isNull);
      expect(PersianDate.tryParseFormat('1403/1/04', 'yyyy/MM/dd'), isNull);
      expect(PersianDate.tryParseFormat('1403/01/04 x', 'yyyy/MM/dd'), isNull);
      expect(PersianDate.tryParseFormat('1403/01/04 24:00', 'yyyy/MM/dd HH:mm'),
          isNull);
      expect(
          PersianDate.tryParseFormat(
              '1403/01/04 13:00 ق.ظ', 'yyyy/MM/dd H:mm a'),
          isNull);
      expect(PersianDate.tryParseFormat('3178/01/01', 'yyyy/MM/dd'), isNull);
      expect(PersianDate.tryParseFormat('5 1403 فروردین 4', 'D yyyy MMMM d'),
          isNull);
      expect(() => PersianDate.parseFormat('x', 'd MMMM yyyy'),
          throwsFormatException);
    });

    test('patterns that cannot be parsed', () {
      expect(() => PersianDate.parseFormat('1403/01', 'yyyy/MM'),
          throwsArgumentError);
      expect(() => PersianDate.parseFormat('03/01/04', 'yy/MM/dd'),
          throwsArgumentError);
      expect(() => PersianDate.parseFormat('x', 'dw MMMM yyyy'),
          throwsArgumentError);
      expect(() => PersianDate.parseFormat('1403/01/04 2', 'yyyy/MM/dd h'),
          throwsArgumentError);
      expect(() => PersianDate.tryParseFormat('1403/01', 'yyyy/MM'),
          throwsArgumentError);
    });
  });
}
