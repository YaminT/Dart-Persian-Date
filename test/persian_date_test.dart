import 'dart:convert';

import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  group('validation', () {
    test('rejects months outside 1 to 12', () {
      expect(() => PersianDate(1400, 0, 1), throwsArgumentError);
      expect(() => PersianDate(1400, 13, 1), throwsArgumentError);
    });

    test('rejects days outside the month', () {
      expect(() => PersianDate(1400, 1, 0), throwsArgumentError);
      expect(() => PersianDate(1400, 1, 32), throwsArgumentError);
      expect(() => PersianDate(1400, 7, 31), throwsArgumentError);
    });

    test('accepts Esfand 30 only in leap years', () {
      expect(() => PersianDate(1400, 12, 30), throwsArgumentError);
      expect(() => PersianDate(1399, 12, 30), returnsNormally);
    });

    test('rejects years outside the supported range', () {
      expect(() => PersianDate(-62, 1, 1), throwsArgumentError);
      expect(() => PersianDate(-61, 1, 1), returnsNormally);
      expect(() => PersianDate(3177, 1, 1), returnsNormally);
      expect(() => PersianDate(3178, 1, 1), throwsArgumentError);
    });

    test('range ends match in both directions', () {
      expect(PersianDate(3177, 10, 11).toDateTime(), DateTime(3798, 12, 31));
      expect(() => PersianDate(3177, 10, 12), throwsArgumentError);
      expect(
          PersianDate.fromGregorian(3798, 12, 31), PersianDate(3177, 10, 11));
      expect(() => PersianDate.fromGregorian(3799, 1, 1), throwsArgumentError);
      expect(PersianDate.fromGregorian(560, 3, 20), PersianDate(-61, 1, 1));
      expect(() => PersianDate.fromGregorian(560, 3, 19), throwsArgumentError);
    });
  });

  group('toDateTime', () {
    const pairs = [
      (2017, 3, 21, 1396, 1, 1),
      (2009, 6, 2, 1388, 3, 12),
      (1992, 5, 18, 1371, 2, 28),
      (2021, 3, 20, 1399, 12, 30),
      (2021, 3, 21, 1400, 1, 1),
      (2024, 3, 20, 1403, 1, 1),
      (1979, 2, 11, 1357, 11, 22),
    ];
    for (final (gy, gm, gd, jy, jm, jd) in pairs) {
      test('$jy/$jm/$jd -> $gy-$gm-$gd', () {
        expect(PersianDate(jy, jm, jd).toDateTime(), DateTime(gy, gm, gd));
      });
    }

    test('returns the original DateTime unchanged', () {
      final utc = DateTime.utc(2018, 7, 7, 21, 43, 44, 909);
      final local = DateTime(2018, 7, 7, 5, 6, 7);
      expect(PersianDate.fromDateTime(utc).toDateTime(), utc);
      expect(PersianDate.fromDateTime(utc).toDateTime().isUtc, isTrue);
      expect(PersianDate.fromDateTime(local).toDateTime(), local);
      expect(PersianDate.fromDateTime(local).toDateTime().isUtc, isFalse);
    });
  });

  test('fromGregorian rolls over like DateTime', () {
    expect(
      PersianDate.fromGregorian(2021, 2, 30),
      PersianDate.fromGregorian(2021, 3, 2),
    );
  });

  test('isLeapYear and monthLength', () {
    expect(PersianDate(1399, 1, 1).isLeapYear, isTrue);
    expect(PersianDate(1400, 1, 1).isLeapYear, isFalse);
    expect(PersianDate(1399, 12, 1).monthLength, 30);
    expect(PersianDate(1400, 12, 1).monthLength, 29);
    expect(PersianDate(1400, 6, 1).monthLength, 31);
    expect(PersianDate(1400, 7, 1).monthLength, 30);
  });

  group('equality and ordering', () {
    test('equal dates ignore the time of day and the source', () {
      final jalali = PersianDate(1400, 1, 1);
      final gregorian =
          PersianDate.fromDateTime(DateTime.utc(2021, 3, 21, 23, 59));
      expect(gregorian, jalali);
      expect(gregorian.hashCode, jalali.hashCode);
      expect(gregorian.compareTo(jalali), 0);
    });

    test('orders across a year boundary', () {
      final last = PersianDate(1399, 12, 30);
      final first = PersianDate(1400, 1, 1);
      expect(last.compareTo(first), lessThan(0));
      expect(first.compareTo(last), greaterThan(0));
      expect(last, isNot(first));
      final sorted = [first, last, PersianDate.fromGregorian(2021, 3, 19)]
        ..sort();
      expect(sorted, [PersianDate(1399, 12, 29), last, first]);
    });
  });

  group('Persian names', () {
    test('monthName', () {
      expect(PersianDate(1400, 1, 1).monthName, 'فروردین');
      expect(PersianDate(1400, 6, 1).monthName, 'شهریور');
      expect(PersianDate(1400, 7, 1).monthName, 'مهر');
      expect(PersianDate(1400, 12, 1).monthName, 'اسفند');
      expect(PersianDate.monthNames, hasLength(12));
    });

    test('weekday follows DateTime and weekdayName is Persian', () {
      final revolution = PersianDate.fromGregorian(1979, 2, 11);
      expect(revolution.weekday, DateTime.sunday);
      expect(revolution.weekdayName, 'یکشنبه');
      final nowruz = PersianDate(1400, 1, 1);
      expect(nowruz.weekday, DateTime.sunday);
      expect(nowruz.weekdayName, 'یکشنبه');
      expect(PersianDate(1403, 1, 4).weekdayName, 'شنبه');
      expect(PersianDate(1403, 1, 7).weekdayName, 'سه\u200cشنبه');
    });
  });

  test('toString pads the date part', () {
    expect(PersianDate(1400, 1, 1).toString(), '1400/01/01');
    expect(PersianDate(1357, 11, 22).toString(), '1357/11/22');
  });

  group('format', () {
    test('yyyy/MM/dd matches toString', () {
      final date = PersianDate.fromGregorian(2009, 6, 2);
      expect(date.format('yyyy/MM/dd'), date.toString());
    });

    test('Persian month name', () {
      expect(
        PersianDate.fromGregorian(2021, 3, 21).format('d MMMM yyyy'),
        '1 فروردین 1400',
      );
    });

    test('Persian weekday name', () {
      expect(
        PersianDate.fromGregorian(1979, 2, 11).format('EEEE d MMMM'),
        'یکشنبه 22 بهمن',
      );
    });

    test('short year, month, and day', () {
      expect(PersianDate(1403, 1, 4).format('yy-M-d'), '03-1-4');
    });

    test('time tokens', () {
      final date = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
      expect(date.format('HH:mm'), '21:43');
      final early = PersianDate.fromDateTime(DateTime(2018, 7, 7, 1, 2, 3));
      expect(early.format('H:m:s HH:mm:ss'), '1:2:3 01:02:03');
    });

    test('time tokens need a DateTime', () {
      expect(() => PersianDate(1400, 1, 1).format('HH'), throwsStateError);
    });

    test('negative years keep the sign outside the padding', () {
      expect(PersianDate(-5, 1, 1).format('yyyy'), '-0005');
    });

    test('unknown characters pass through', () {
      expect(PersianDate(1400, 1, 1).format('Q yyyy! T'), 'Q 1400! T');
    });
  });

  group('bounds and copyWith', () {
    test('min and max are the ends of the supported range', () {
      expect(PersianDate.min, PersianDate(-61, 1, 1));
      expect(PersianDate.max, PersianDate(3177, 10, 11));
      expect(PersianDate.min.toDateTime(), DateTime(560, 3, 20));
      expect(PersianDate.max.toDateTime(), DateTime(3798, 12, 31));
    });

    test('copyWith replaces fields and validates', () {
      final date = PersianDate(1403, 6, 31);
      expect(date.copyWith(year: 1402), PersianDate(1402, 6, 31));
      expect(date.copyWith(day: 1), PersianDate(1403, 6, 1));
      expect(date.copyWith(), date);
      expect(() => date.copyWith(month: 7), throwsArgumentError);
      expect(
        () => PersianDate(1403, 12, 30).copyWith(year: 1404),
        throwsArgumentError,
      );
    });

    test('copyWith drops the time of day', () {
      final date = PersianDate.fromDateTime(DateTime(2024, 3, 20, 10, 30));
      expect(() => date.copyWith().toString(showTime: true), throwsStateError);
    });
  });

  group('arithmetic', () {
    test('addDays crosses month and year boundaries', () {
      expect(PersianDate(1403, 1, 31).addDays(1), PersianDate(1403, 2, 1));
      expect(PersianDate(1403, 12, 30).addDays(1), PersianDate(1404, 1, 1));
      expect(PersianDate(1404, 12, 29).addDays(1), PersianDate(1405, 1, 1));
      expect(PersianDate(1404, 1, 1).addDays(-1), PersianDate(1403, 12, 30));
      expect(PersianDate(1400, 1, 1).addDays(365), PersianDate(1401, 1, 1));
      expect(PersianDate(1400, 1, 1).addDays(0), PersianDate(1400, 1, 1));
    });

    test('addDays drops the time and keeps the day', () {
      final date = PersianDate.fromDateTime(DateTime.utc(2024, 3, 20, 23));
      final next = date.addDays(1);
      expect(next, PersianDate(1403, 1, 2));
      expect(next.toDateTime(), DateTime(2024, 3, 21));
    });

    test('addMonths clamps the day', () {
      expect(PersianDate(1403, 6, 31).addMonths(1), PersianDate(1403, 7, 30));
      expect(PersianDate(1403, 11, 30).addMonths(1), PersianDate(1403, 12, 30));
      expect(PersianDate(1404, 11, 30).addMonths(1), PersianDate(1404, 12, 29));
      expect(PersianDate(1403, 1, 15).addMonths(12), PersianDate(1404, 1, 15));
      expect(PersianDate(1403, 1, 15).addMonths(-1), PersianDate(1402, 12, 15));
      expect(
          PersianDate(1403, 1, 15).addMonths(-13), PersianDate(1401, 12, 15));
      expect(PersianDate(1403, 5, 1).addMonths(0), PersianDate(1403, 5, 1));
    });

    test('addMonths works across negative years', () {
      expect(PersianDate(-1, 12, 1).addMonths(1), PersianDate(0, 1, 1));
      expect(PersianDate(0, 1, 1).addMonths(-1), PersianDate(-1, 12, 1));
      expect(PersianDate(-59, 3, 4).addMonths(-25), PersianDate(-61, 2, 4));
      expect(() => PersianDate(-60, 3, 4).addMonths(-25), throwsArgumentError);
    });

    test('addYears clamps Esfand 30', () {
      expect(PersianDate(1403, 12, 30).addYears(1), PersianDate(1404, 12, 29));
      expect(PersianDate(1403, 12, 30).addYears(5), PersianDate(1408, 12, 30));
      expect(PersianDate(1403, 7, 1).addYears(-3), PersianDate(1400, 7, 1));
    });

    test('results outside the range throw', () {
      expect(() => PersianDate.max.addDays(1), throwsArgumentError);
      expect(() => PersianDate.min.addDays(-1), throwsArgumentError);
      expect(() => PersianDate.min.addMonths(-1), throwsArgumentError);
      expect(() => PersianDate(3177, 11, 1).addDays(0), throwsArgumentError);
      expect(() => PersianDate(3177, 10, 1).addMonths(1), throwsArgumentError);
      expect(() => PersianDate(3177, 1, 1).addYears(1), throwsArgumentError);
    });

    test('differenceInDays', () {
      final date = PersianDate(1399, 12, 30);
      for (final n in [-400, -1, 0, 1, 30, 366, 1000]) {
        expect(date.addDays(n).differenceInDays(date), n, reason: '$n');
      }
      expect(PersianDate(1404, 1, 1).differenceInDays(PersianDate(1403, 1, 1)),
          366);
      final evening = PersianDate.fromDateTime(DateTime(2021, 3, 21, 23, 59));
      final morning = PersianDate.fromDateTime(DateTime(2021, 3, 22, 0, 1));
      expect(morning.differenceInDays(evening), 1);
    });
  });

  group('comparison helpers', () {
    final a = PersianDate(1399, 12, 30);
    final b = PersianDate(1400, 1, 1);
    final bLate = PersianDate.fromDateTime(DateTime(2021, 3, 21, 23, 59));

    test('isBefore and isAfter', () {
      expect(a.isBefore(b), isTrue);
      expect(b.isBefore(a), isFalse);
      expect(b.isAfter(a), isTrue);
      expect(b.isAfter(bLate), isFalse);
      expect(b.isBefore(bLate), isFalse);
    });

    test('isSameDay, isSameMonth, isSameYear', () {
      expect(b.isSameDay(bLate), isTrue);
      expect(a.isSameDay(b), isFalse);
      expect(b.isSameMonth(PersianDate(1400, 1, 31)), isTrue);
      expect(b.isSameMonth(PersianDate(1401, 1, 1)), isFalse);
      expect(b.isSameYear(PersianDate(1400, 12, 29)), isTrue);
      expect(a.isSameYear(b), isFalse);
    });

    test('operators', () {
      expect(a < b, isTrue);
      expect(a <= b, isTrue);
      expect(b <= bLate, isTrue);
      expect(b >= bLate, isTrue);
      expect(b > a, isTrue);
      expect(a > b, isFalse);
      expect(b < bLate, isFalse);
    });

    test('isToday', () {
      expect(PersianDate.now().isToday, isTrue);
      expect(PersianDate.now().addDays(1).isToday, isFalse);
    });
  });

  group('calendar anchors', () {
    test('dayOfYear and daysInYear', () {
      expect(PersianDate(1403, 1, 1).dayOfYear, 1);
      expect(PersianDate(1403, 6, 31).dayOfYear, 186);
      expect(PersianDate(1403, 7, 1).dayOfYear, 187);
      expect(PersianDate(1403, 12, 30).dayOfYear, 366);
      expect(PersianDate(1404, 12, 29).dayOfYear, 365);
      expect(PersianDate(1403, 1, 1).daysInYear, 366);
      expect(PersianDate(1404, 1, 1).daysInYear, 365);
    });

    test('dayOfYear matches day arithmetic for a whole year', () {
      final first = PersianDate(1403, 1, 1);
      for (var i = 0; i < 366; i++) {
        expect(first.addDays(i).dayOfYear, i + 1);
      }
    });

    test('quarter, season, and seasonName', () {
      expect(PersianDate(1403, 1, 1).quarter, 1);
      expect(PersianDate(1403, 3, 31).quarter, 1);
      expect(PersianDate(1403, 4, 1).quarter, 2);
      expect(PersianDate(1403, 12, 1).quarter, 4);
      expect(PersianDate(1403, 7, 1).season, 3);
      expect(PersianDate(1403, 1, 1).seasonName, 'بهار');
      expect(PersianDate(1403, 4, 1).seasonName, 'تابستان');
      expect(PersianDate(1403, 7, 1).seasonName, 'پاییز');
      expect(PersianDate(1403, 10, 1).seasonName, 'زمستان');
    });

    test('first and last days of month and year', () {
      final date = PersianDate.fromDateTime(DateTime(2024, 8, 10, 12));
      expect(date, PersianDate(1403, 5, 20));
      expect(date.firstDayOfMonth, PersianDate(1403, 5, 1));
      expect(date.lastDayOfMonth, PersianDate(1403, 5, 31));
      expect(PersianDate(1403, 7, 9).lastDayOfMonth, PersianDate(1403, 7, 30));
      expect(
          PersianDate(1404, 12, 9).lastDayOfMonth, PersianDate(1404, 12, 29));
      expect(date.firstDayOfYear, PersianDate(1403, 1, 1));
      expect(date.lastDayOfYear, PersianDate(1403, 12, 30));
      expect(PersianDate(1404, 5, 5).lastDayOfYear, PersianDate(1404, 12, 29));
      expect(
        () => date.firstDayOfMonth.toString(showTime: true),
        throwsStateError,
      );
    });

    test('last days past max throw', () {
      expect(() => PersianDate.max.lastDayOfMonth, throwsArgumentError);
      expect(() => PersianDate.max.lastDayOfYear, throwsArgumentError);
      expect(PersianDate.max.firstDayOfMonth, PersianDate(3177, 10, 1));
    });
  });

  group('Persian week', () {
    test('weekday from the day number matches DateTime for a long span', () {
      var date = PersianDate(1390, 1, 1);
      for (var i = 0; i < 3000; i++) {
        expect(date.weekday, date.toDateTime().weekday, reason: '$date');
        date = date.addDays(1);
      }
      final utcLate = PersianDate.fromDateTime(DateTime.utc(2024, 3, 23, 23));
      expect(utcLate.weekday, DateTime.saturday);
    });

    test('weekdayPersian starts on Saturday', () {
      // 1403/01/04 is Saturday 2024-03-23.
      final saturday = PersianDate(1403, 1, 4);
      for (var i = 0; i < 7; i++) {
        expect(saturday.addDays(i).weekdayPersian, i + 1);
      }
      expect(saturday.addDays(7).weekdayPersian, 1);
    });

    test('short weekday names', () {
      final saturday = PersianDate(1403, 1, 4);
      expect(
        [for (var i = 0; i < 7; i++) saturday.addDays(i).weekdayNameShort],
        ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
      );
      expect(PersianDate.weekdayNamesShort, hasLength(7));
    });

    test('isWeekend is Friday only', () {
      final saturday = PersianDate(1403, 1, 4);
      expect(saturday.addDays(6).isWeekend, isTrue);
      expect(saturday.addDays(5).isWeekend, isFalse);
      expect(saturday.isWeekend, isFalse);
    });

    test('startOfWeek and endOfWeek', () {
      final wednesday = PersianDate(1403, 1, 1);
      expect(wednesday.weekday, DateTime.wednesday);
      expect(wednesday.startOfWeek(), PersianDate(1402, 12, 26));
      expect(wednesday.endOfWeek(), PersianDate(1403, 1, 3));
      final saturday = PersianDate(1403, 1, 4);
      expect(saturday.startOfWeek(), saturday);
      expect(saturday.addDays(6).endOfWeek(), saturday.addDays(6));
    });

    test('weekOfYear', () {
      // 1403/01/01 is Wednesday, so its week runs to Friday 1403/01/03.
      expect(PersianDate(1403, 1, 1).weekOfYear, 1);
      expect(PersianDate(1403, 1, 3).weekOfYear, 1);
      expect(PersianDate(1403, 1, 4).weekOfYear, 2);
      expect(PersianDate(1403, 1, 10).weekOfYear, 2);
      expect(PersianDate(1403, 1, 11).weekOfYear, 3);
      expect(PersianDate(1403, 12, 30).weekOfYear, 53);
      final first = PersianDate(1404, 1, 1);
      for (var i = 0; i < first.daysInYear; i++) {
        final date = first.addDays(i);
        if (date.weekdayPersian == 1 && i > 0) {
          expect(date.weekOfYear, date.addDays(-1).weekOfYear + 1);
        } else if (i > 0) {
          expect(date.weekOfYear, date.addDays(-1).weekOfYear);
        }
      }
    });

    test('month grid recipe from the README', () {
      // 1403/07 starts on Sunday 2024-09-22, the second Persian column.
      final first = PersianDate(1403, 7, 1);
      expect(first.weekdayPersian - 1, 1);
      expect(first.monthLength, 30);
    });
  });

  group('Persian digits', () {
    test('toPersianDigits converts every digit and keeps other text', () {
      expect(toPersianDigits('0123456789'), '۰۱۲۳۴۵۶۷۸۹');
      expect(toPersianDigits('1403/01/01 ساعت 9'), '۱۴۰۳/۰۱/۰۱ ساعت ۹');
      expect(toPersianDigits('۱۲'), '۱۲');
      expect(toPersianDigits(''), '');
    });

    test('toLatinDigits handles Persian and Arabic-Indic digits', () {
      expect(toLatinDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
      expect(toLatinDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(toLatinDigits('۱۴۰۳-۰۱-۰۱ abc 7'), '1403-01-01 abc 7');
    });

    test('round trip', () {
      const text = 'Date 1357/11/22, 21:43';
      expect(toLatinDigits(toPersianDigits(text)), text);
    });

    test('toString and format with persianDigits', () {
      final date = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
      expect(date.toString(persianDigits: true), '۱۳۹۷/۰۴/۱۶');
      expect(
        date.toString(showTime: true, persianDigits: true),
        '۱۳۹۷/۰۴/۱۶ ۲۱:۴۳:۴۴',
      );
      expect(
        date.format('d MMMM yyyy, HH:mm', persianDigits: true),
        '۱۶ تیر ۱۳۹۷, ۲۱:۴۳',
      );
      expect(date.format('yyyy 2', persianDigits: true), '۱۳۹۷ 2');
    });
  });

  group('time of day', () {
    test('hasTime', () {
      expect(PersianDate(1403, 1, 1).hasTime, isFalse);
      expect(PersianDate.now().hasTime, isTrue);
      expect(PersianDate.fromGregorian(2024, 3, 20).hasTime, isTrue);
      expect(PersianDate.withTime(1403, 1, 1).hasTime, isTrue);
      expect(PersianDate.now().addDays(0).hasTime, isFalse);
    });

    test('hour, minute, second', () {
      final date = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
      expect((date.hour, date.minute, date.second), (21, 43, 44));
      expect(() => PersianDate(1403, 1, 1).hour, throwsStateError);
      expect(() => PersianDate(1403, 1, 1).minute, throwsStateError);
      expect(() => PersianDate(1403, 1, 1).second, throwsStateError);
    });

    test('withTime builds a local DateTime', () {
      final date = PersianDate.withTime(1357, 11, 22, 9, 5, 7);
      expect(date, PersianDate(1357, 11, 22));
      expect(date.toDateTime(), DateTime(1979, 2, 11, 9, 5, 7));
      expect(date.toDateTime().isUtc, isFalse);
      expect(date.toString(showTime: true), '1357/11/22 09:05:07');
      expect(
          PersianDate.withTime(1400, 1, 1).toDateTime(), DateTime(2021, 3, 21));
    });

    test('withTime validates', () {
      expect(() => PersianDate.withTime(1400, 12, 30), throwsArgumentError);
      expect(() => PersianDate.withTime(1400, 1, 1, 24), throwsArgumentError);
      expect(() => PersianDate.withTime(1400, 1, 1, -1), throwsArgumentError);
      expect(
          () => PersianDate.withTime(1400, 1, 1, 0, 60), throwsArgumentError);
      expect(() => PersianDate.withTime(1400, 1, 1, 0, 0, 60),
          throwsArgumentError);
      expect(
          () => PersianDate.withTime(1400, 1, 1, 23, 59, 59), returnsNormally);
    });
  });

  group('parse', () {
    test('date-only formats', () {
      for (final input in [
        '1403/01/01',
        '1403-01-01',
        '1403/1/1',
        ' 1403-1-01 ',
        '۱۴۰۳/۰۱/۰۱',
        '١٤٠٣/٠١/٠١',
      ]) {
        final date = PersianDate.parse(input);
        expect(date, PersianDate(1403, 1, 1), reason: input);
        expect(date.hasTime, isFalse, reason: input);
      }
      expect(PersianDate.parse('-5/1/1'), PersianDate(-5, 1, 1));
    });

    test('with a time of day', () {
      final date = PersianDate.parse('1403/01/01 14:30');
      expect(date.toDateTime(), DateTime(2024, 3, 20, 14, 30));
      expect(
        PersianDate.parse('1403-01-01T14:30:15').toDateTime(),
        DateTime(2024, 3, 20, 14, 30, 15),
      );
      expect(
        PersianDate.parse('۱۴۰۳/۰۱/۰۱ ۰۹:۰۵').toString(showTime: true),
        '1403/01/01 09:05:00',
      );
    });

    test('round trips toString and format', () {
      final date = PersianDate.withTime(1357, 11, 22, 21, 43, 44);
      expect(PersianDate.parse(date.toString()), date);
      expect(
        PersianDate.parse(date.toString(showTime: true)).toDateTime(),
        date.toDateTime(),
      );
      expect(
        PersianDate.parse(date.toString(persianDigits: true)),
        date,
      );
    });

    test('invalid input throws FormatException', () {
      for (final input in [
        '',
        '1403',
        '1403/01',
        '1403.01.01',
        '01/01/1403',
        '1403/13/01',
        '1400/12/30',
        '1403/01/01 24:00',
        '1403/01/01 12:60',
        '1403/01/01 12',
        '1403/01/01x',
      ]) {
        expect(() => PersianDate.parse(input), throwsFormatException,
            reason: input);
        expect(PersianDate.tryParse(input), isNull, reason: input);
      }
    });
  });

  group('JSON', () {
    test('toJson and fromJson round trip', () {
      final date = PersianDate(1403, 1, 4);
      expect(date.toJson(), '1403-01-04');
      expect(PersianDate.fromJson(date.toJson()), date);
      expect(PersianDate(-5, 1, 1).toJson(), '-0005-01-01');
      expect(PersianDate.fromJson('-0005-01-01'), PersianDate(-5, 1, 1));
    });

    test('toJson drops the time and works with jsonEncode', () {
      final date = PersianDate.withTime(1403, 1, 4, 10, 30);
      expect(date.toJson(), '1403-01-04');
      expect(jsonEncode({'date': date}), '{"date":"1403-01-04"}');
    });

    test('fromJson rejects invalid input', () {
      expect(() => PersianDate.fromJson('1403-13-01'), throwsFormatException);
    });
  });
}
