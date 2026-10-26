import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

// 1 Shawwal (Eid al-Fitr) on the calendars published on time.ir, Hijri 1429
// (Jalali 1387) to 1446 (Jalali 1404).
const _eidAlFitr = [
  '1387/07/10', '1388/06/29', '1389/06/19', '1390/06/09', '1391/05/29',
  '1392/05/18', '1393/05/07', '1394/04/27', '1395/04/16', '1396/04/05',
  '1397/03/25', '1398/03/15', '1399/03/04', '1400/02/23', '1401/02/13',
  '1402/02/02', '1403/01/22', '1404/01/11', //
];

void main() {
  group('conversion', () {
    test('known days', () {
      expect(PersianDate(1405, 1, 1).toHijri(), HijriDate(1447, 10, 1));
      expect(PersianDate(1405, 4, 4).toHijri(), HijriDate(1448, 1, 10));
      expect(HijriDate(1448, 1, 10).toPersianDate(), PersianDate(1405, 4, 4));
      expect(HijriDate(1448, 1, 10).toDateTime(), DateTime(2026, 6, 25));
      expect(HijriDate.fromDateTime(DateTime(2026, 6, 25, 23, 59)),
          HijriDate(1448, 1, 10));
      expect(DateTime(2026, 6, 25).toHijriDate(), HijriDate(1448, 1, 10));
      expect(HijriDate.fromPersianDate(PersianDate.withTime(1405, 4, 4, 23)),
          HijriDate(1448, 1, 10));
    });

    test('Eid al-Fitr matches the published calendar', () {
      for (final (i, text) in _eidAlFitr.indexed) {
        final eid = HijriDate(1429 + i, 10, 1);
        expect(eid.toPersianDate(), PersianDate.parse(text), reason: text);
        expect(PersianDate.parse(text).toHijri(), eid, reason: text);
      }
    });

    test('round trip and day sequence, 1300 to 1500', () {
      var date = PersianDate(1300, 1, 1);
      var previous = date.toHijri();
      final end = PersianDate(1500, 1, 1);
      while (date.isBefore(end)) {
        date = date.addDays(1);
        final hijri = date.toHijri();
        expect(hijri.toPersianDate(), date);
        if (hijri.day == 1) {
          expect(previous.day, previous.monthLength, reason: '$date');
          expect(previous.day, inInclusiveRange(29, 30), reason: '$date');
          expect(hijri.month, previous.month % 12 + 1, reason: '$date');
        } else {
          expect(hijri.day, previous.day + 1, reason: '$date');
        }
        previous = hijri;
      }
    });

    test('range endpoints and years before the Hijra', () {
      expect(HijriDate.min, PersianDate.min.toHijri());
      expect(HijriDate.max, PersianDate.max.toHijri());
      expect(HijriDate.min.year, isNegative);
      expect(HijriDate.min.toPersianDate(), PersianDate.min);
      expect(HijriDate.max.toPersianDate(), PersianDate.max);
      for (final start in [PersianDate.min, PersianDate.max.addDays(-800)]) {
        for (final date in start.daysUntil(start.addDays(800))) {
          final hijri = date.toHijri();
          expect(hijri.toPersianDate(), date);
          expect(HijriDate(hijri.year, hijri.month, hijri.day), hijri);
        }
      }
    });
  });

  group('validation', () {
    test('month and day', () {
      expect(() => HijriDate(1447, 0, 1), throwsArgumentError);
      expect(() => HijriDate(1447, 13, 1), throwsArgumentError);
      expect(() => HijriDate(1447, 1, 0), throwsArgumentError);
      expect(() => HijriDate(1447, 1, 31), throwsArgumentError);
      // Safar 1447 has 30 days, Dhu al-Hijjah 1447 has 29.
      expect(HijriDate(1447, 2, 30).toPersianDate(), PersianDate(1404, 6, 2));
      expect(HijriDate(1447, 12, 1).monthLength, 29);
      expect(() => HijriDate(1447, 12, 30), throwsArgumentError);
    });

    test('range', () {
      final min = HijriDate.min, max = HijriDate.max;
      expect(() => HijriDate(min.year - 1, 1, 1), throwsArgumentError);
      expect(() => HijriDate(max.year + 1, 1, 1), throwsArgumentError);
      if (min.day > 1) {
        expect(() => HijriDate(min.year, min.month, min.day - 1),
            throwsArgumentError);
      }
      expect(() => HijriDate(max.year, max.month, max.day + 1),
          throwsArgumentError);
      expect(() => HijriDate.fromDateTime(DateTime(3799, 1, 1)),
          throwsArgumentError);
    });
  });

  test('equality and ordering', () {
    final last = HijriDate(1447, 12, 29);
    final first = HijriDate(1448, 1, 1);
    expect(last == HijriDate(1447, 12, 29), isTrue);
    expect(last.hashCode, HijriDate(1447, 12, 29).hashCode);
    expect(last < first, isTrue);
    expect(last <= first, isTrue);
    expect(first > last, isTrue);
    expect(first >= first, isTrue);
    expect(last.isBefore(first), isTrue);
    expect(first.isAfter(last), isTrue);
    expect(last.compareTo(last), 0);
    expect([first, last]..sort(), [last, first]);
  });

  group('names and format', () {
    final ashura = HijriDate(1448, 1, 10);

    test('names', () {
      expect(ashura.monthName, 'محرم');
      expect(HijriDate(1447, 9, 1).monthName, 'رمضان');
      expect(HijriDate.monthNames, hasLength(12));
      expect(ashura.weekday, DateTime.thursday);
      expect(ashura.weekdayName, 'پنجشنبه');
      expect(ashura.weekdayNameShort, 'پ');
    });

    test('toString', () {
      expect('$ashura', '10 محرم 1448');
    });

    test('format', () {
      expect(ashura.format('yyyy/MM/dd'), '1448/01/10');
      expect(ashura.format('yy M d'), '48 1 10');
      expect(ashura.format('EEEE d MMMM yyyy'), 'پنجشنبه 10 محرم 1448');
      expect(ashura.format('E'), 'پ');
      expect(ashura.format("d MMMM yyyy 'ق'"), '10 محرم 1448 ق');
      expect(ashura.format("d 'o''clock'"), "10 o'clock");
      expect(ashura.format('d MMMM yyyy', persianDigits: true), '۱۰ محرم ۱۴۴۸');
      expect(HijriDate.min.format('yyyy'), startsWith('-00'));
    });
  });

  group('IranianHijri', () {
    test('official is the calendar HijriDate uses', () {
      final date = PersianDate(1405, 1, 1);
      expect(IranianHijri.official.fromPersianDate(date), date.toHijri());
      expect(IranianHijri.official.monthStart(1447, 10), date);
      expect(IranianHijri.official.monthLength(1447, 9), 30);
      expect(IranianHijri().fromDateTime(DateTime(2026, 3, 21)),
          HijriDate(1447, 10, 1));
    });

    test('monthStarts moves a month', () {
      final calendar = IranianHijri(
        monthStarts: {(1448, 1): PersianDate(1405, 3, 27)},
      );
      expect(calendar.monthStart(1448, 1), PersianDate(1405, 3, 27));
      expect(calendar.monthLength(1447, 12), 30);
      expect(calendar.monthLength(1448, 1), 29);
      expect(calendar.fromPersianDate(PersianDate(1405, 4, 5)),
          HijriDate(1448, 1, 10));
      // 30 Dhu al-Hijjah 1447 exists only on this calendar, and keeps its
      // day.
      final day30 = calendar.date(1447, 12, 30);
      expect(day30.toPersianDate(), PersianDate(1405, 3, 26));
      expect(day30.weekday, PersianDate(1405, 3, 26).weekday);
      expect(() => HijriDate(1447, 12, 30), throwsArgumentError);
      expect(calendar.monthStarts, hasLength(1));
      expect(() => calendar.monthStarts.clear(), throwsUnsupportedError);
    });

    test('validation', () {
      final calendar = IranianHijri.official;
      expect(() => calendar.monthStart(1447, 13), throwsArgumentError);
      expect(() => calendar.monthLength(1447, 0), throwsArgumentError);
      expect(() => calendar.monthStart(HijriDate.max.year + 1, 1),
          throwsArgumentError);
    });
  });
}
