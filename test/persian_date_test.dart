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
}
