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
}
