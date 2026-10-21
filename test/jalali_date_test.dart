import 'package:jalali_date/jalali_date.dart';
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
}
