import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  test('era offsets', () {
    expect(JalaliEra.solarHijri.offset, 0);
    expect(JalaliEra.shahanshahi.offset, 1180);
  });

  test('shahanshahiYear adds 1180', () {
    expect(PersianDate(1405, 1, 1).shahanshahiYear, 2585);
    expect(PersianDate.min.shahanshahiYear, 1119);
    expect(PersianDate.max.shahanshahiYear, 4357);
  });

  test('format prints the year in the chosen era', () {
    final date = PersianDate(1405, 1, 4);
    expect(date.format('yyyy/MM/dd'), '1405/01/04');
    expect(
      date.format('yyyy/MM/dd', era: JalaliEra.shahanshahi),
      '2585/01/04',
    );
    expect(date.format('yy', era: JalaliEra.shahanshahi), '85');
    expect(
      date.format('d MMMM yyyy',
          era: JalaliEra.shahanshahi, persianDigits: true),
      '۴ فروردین ۲۵۸۵',
    );
    expect(PersianDate(-61, 1, 1).format('yyyy', era: JalaliEra.shahanshahi),
        '1119');
  });

  test('toString prints the year in the chosen era', () {
    final date = PersianDate.withTime(1405, 1, 4, 9, 30);
    expect(date.toString(), '1405/01/04');
    expect(date.toString(era: JalaliEra.shahanshahi), '2585/01/04');
    expect(
      date.toString(era: JalaliEra.shahanshahi, showTime: true),
      '2585/01/04 09:30:00',
    );
  });

  test('parse reads the year in the chosen era', () {
    expect(
      PersianDate.parse('2585/01/04', era: JalaliEra.shahanshahi),
      PersianDate(1405, 1, 4),
    );
    expect(
      PersianDate.parse('۲۵۸۵-۱-۴ ۱۴:۳۰', era: JalaliEra.shahanshahi).hour,
      14,
    );
    expect(PersianDate.parse('1405/01/04'), PersianDate(1405, 1, 4));
    expect(
      PersianDate.tryParse('2585/01/04', era: JalaliEra.shahanshahi),
      PersianDate(1405, 1, 4),
    );
  });

  test('parse checks the range in the chosen era', () {
    expect(
      PersianDate.parse('1119/01/01', era: JalaliEra.shahanshahi),
      PersianDate.min,
    );
    expect(
      PersianDate.parse('4357/10/11', era: JalaliEra.shahanshahi),
      PersianDate.max,
    );
    expect(
      () => PersianDate.parse('1118/12/29', era: JalaliEra.shahanshahi),
      throwsA(isA<FormatException>()
          .having((e) => e.message, 'message', contains('1119 to 4357'))),
    );
    expect(
      () => PersianDate.parse('4357/10/12', era: JalaliEra.shahanshahi),
      throwsFormatException,
    );
    // 2579 is Solar Hijri 1399, a leap year; 2580 (1400) is not.
    expect(PersianDate.tryParse('2579/12/30', era: JalaliEra.shahanshahi),
        PersianDate(1399, 12, 30));
    expect(
        PersianDate.tryParse('2580/12/30', era: JalaliEra.shahanshahi), isNull);
  });

  test('round trip in both eras', () {
    for (final era in JalaliEra.values) {
      for (var d = PersianDate(1399, 12, 25);
          d <= PersianDate(1400, 1, 5);
          d = d.addDays(1)) {
        expect(
            PersianDate.parse(d.format('yyyy/MM/dd', era: era), era: era), d);
        expect(PersianDate.parse(d.toString(era: era), era: era), d);
      }
    }
  });
}
