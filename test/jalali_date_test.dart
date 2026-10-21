import 'package:jalali_date/jalali_date.dart';
import 'package:jalali_date/src/jalali_calc.dart';
import 'package:test/test.dart';

void main() {
  test('Gregorian to Jalali conversion', () {
    final farv961 = PersianDate.fromGregorian(2017, 03, 21);
    expect(farv961.toString(), "1396/1/1");
    final khord8812 = PersianDate.fromGregorian(2009, 06, 02);
    expect(khord8812.toString(), "1388/3/12");
    final ordi7128 = PersianDate.fromGregorian(1992, 05, 18);
    expect(ordi7128.toString(), "1371/2/28");
    final farv001 = PersianDate.fromGregorian(2021, 03, 21);
    expect(farv001.toString(showTime: true), "1400/1/1 00:00:00");

    final stringFormat =
        PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
    expect(stringFormat.toString(showTime: true), '1397/4/16 21:43:44');
  });

  group('toString time parts', () {
    final date = PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
    final earlyMorning =
        PersianDate.fromGregorianString('2018-07-07T01:02:03.000Z');

    test('pads hour, minute, and second to two digits', () {
      expect(earlyMorning.toString(showTime: true), '1397/4/16 01:02:03');
    });

    test('hides seconds', () {
      expect(
        date.toString(showTime: true, showSecond: false),
        '1397/4/16 21:43',
      );
    });

    test('hides the date', () {
      expect(date.toString(showDate: false, showTime: true), '21:43:44');
    });

    test('shows only the selected parts without stray separators', () {
      expect(
        date.toString(showTime: true, showHour: false),
        '1397/4/16 43:44',
      );
      expect(
        date.toString(showTime: true, showMinute: false),
        '1397/4/16 21:44',
      );
      expect(
        date.toString(
          showDate: false,
          showTime: true,
          showMinute: false,
          showSecond: false,
        ),
        '21',
      );
      expect(
        date.toString(
          showDate: false,
          showTime: true,
          showHour: false,
          showSecond: false,
        ),
        '43',
      );
    });

    test('uses the wall-clock time of a local DateTime', () {
      final local = PersianDate.fromDateTime(DateTime(2018, 7, 7, 5, 6, 7));
      expect(local.toString(showTime: true), '1397/4/16 05:06:07');
    });

    test('rejects a time with every part hidden', () {
      expect(
        () => date.toString(
          showTime: true,
          showHour: false,
          showMinute: false,
          showSecond: false,
        ),
        throwsArgumentError,
      );
    });

    test('rejects hiding both date and time', () {
      expect(
        () => date.toString(showDate: false, showTime: false),
        throwsArgumentError,
      );
    });

    test('part flags are ignored when time is hidden', () {
      expect(date.toString(showSecond: false), '1397/4/16');
    });

    test('still fails without a Gregorian time source', () {
      expect(
        () => PersianDate(1400, 1, 1).toString(showTime: true),
        throwsStateError,
      );
    });
  });

  group('known Gregorian to Jalali pairs', () {
    const pairs = [
      (2017, 3, 21, 1396, 1, 1),
      (2009, 6, 2, 1388, 3, 12),
      (1992, 5, 18, 1371, 2, 28),
      (2018, 7, 7, 1397, 4, 16),
      (2021, 3, 20, 1399, 12, 30),
      (2021, 3, 21, 1400, 1, 1),
      (2024, 3, 20, 1403, 1, 1),
      (2025, 3, 21, 1404, 1, 1),
      (1979, 2, 11, 1357, 11, 22),
    ];
    for (final (gy, gm, gd, jy, jm, jd) in pairs) {
      test('$gy-$gm-$gd -> $jy/$jm/$jd', () {
        final date = PersianDate.fromGregorian(gy, gm, gd);
        expect((date.year, date.month, date.day), (jy, jm, jd));
        expect(date.toString(), '$jy/$jm/$jd');
      });
    }
  });

  test('Jalali leap years and Esfand lengths', () {
    for (final year in [1399, 1403]) {
      expect(isLeapJalaliYear(year), isTrue, reason: '$year');
      expect(jalaliMonthLength(year, 12), 30);
    }
    for (final year in [1400, 1401, 1402, 1404]) {
      expect(isLeapJalaliYear(year), isFalse, reason: '$year');
      expect(jalaliMonthLength(year, 12), 29);
    }
  });

  test('jalCal enforces the break table year bounds', () {
    expect(() => jalCal(-62), throwsArgumentError);
    expect(() => jalCal(-61), returnsNormally);
    expect(() => jalCal(3177), returnsNormally);
    expect(() => jalCal(3178), throwsArgumentError);
    expect(() => isLeapJalaliYear(-62), throwsArgumentError);
    expect(() => isLeapJalaliYear(3178), throwsArgumentError);
  });

  test('jalCal and the leap fast path agree across the supported range', () {
    for (var jy = -61; jy < 3178; jy++) {
      expect(isLeapJalaliYear(jy), jalCal(jy).leap == 0, reason: '$jy');
    }
  });

  test('daily round trips and valid Jalali dates from 1850 through 2300', () {
    final first = g2d(1850, 1, 1);
    final last = g2d(2300, 12, 31);
    for (var jdn = first; jdn <= last; jdn++) {
      final date = d2j(jdn);
      final roundTrip = j2d(date.jy, date.jm, date.jd);
      if (roundTrip != jdn) {
        fail('JDN $jdn -> $date -> $roundTrip');
      }
      final g = d2g(jdn);
      if (g2d(g.gy, g.gm, g.gd) != jdn) {
        fail('Gregorian JDN $jdn -> $g -> ${g2d(g.gy, g.gm, g.gd)}');
      }
      if (date.jm < 1 || date.jm > 12) {
        fail('Invalid month for JDN $jdn: $date');
      }
      if (date.jd < 1 || date.jd > jalaliMonthLength(date.jy, date.jm)) {
        fail('Invalid day for JDN $jdn: $date');
      }
    }
  });

  test('daily Jalali continuity from 1850 through 2300', () {
    final first = g2d(1850, 1, 1);
    final last = g2d(2300, 12, 31);
    var previous = d2j(first);
    for (var jdn = first + 1; jdn <= last; jdn++) {
      final current = d2j(jdn);
      var jy = previous.jy;
      var jm = previous.jm;
      var jd = previous.jd + 1;
      if (jd > jalaliMonthLength(jy, jm)) {
        jd = 1;
        jm++;
        if (jm > 12) {
          jm = 1;
          jy++;
        }
      }
      final expected = (jy: jy, jm: jm, jd: jd);
      if (current != expected) {
        fail('JDN $jdn: $previous -> $current; expected $expected');
      }
      previous = current;
    }
  });

  group('Gregorian edges of the supported range, matching jalaali-js', () {
    test('last supported Gregorian day converts', () {
      expect(toJalali(3798, 12, 31), (jy: 3177, jm: 10, jd: 11));
    });

    test('Gregorian 3799 throws like jalaali-js', () {
      expect(() => toJalali(3799, 1, 1), throwsArgumentError);
      expect(() => PersianDate.fromGregorian(3799, 1, 1), throwsArgumentError);
    });

    test('first day of Jalali -61 converts', () {
      expect(toJalali(560, 3, 20), (jy: -61, jm: 1, jd: 1));
    });

    test('days before Jalali -61 fall out of range unchecked, like jalaali-js',
        () {
      expect(toJalali(560, 1, 1), (jy: -62, jm: 10, jd: 11));
    });
  });

  group('March 1 in non-leap Gregorian century years', () {
    // Expected values verified against jalaali-js v1.2.8 directly.
    const cases = [
      (1900, 1278, 12, 10),
      (2100, 1478, 12, 11),
    ];
    for (final (gy, jy, jm, jd) in cases) {
      test('$gy-03-01 -> $jy/$jm/$jd', () {
        final jdn = g2d(gy, 3, 1);
        expect(toJalali(gy, 3, 1), (jy: jy, jm: jm, jd: jd));
        expect(j2d(jy, jm, jd), jdn);
        expect(d2g(jdn), (gy: gy, gm: 3, gd: 1));
        expect(g2d(gy, 3, 1) - g2d(gy, 2, 28), 1,
            reason: '$gy must not be a Gregorian leap year');
        final publicDate = PersianDate.fromGregorian(gy, 3, 1);
        expect(
          (publicDate.year, publicDate.month, publicDate.day),
          (jy, jm, jd),
        );
      });
    }
  });
}
