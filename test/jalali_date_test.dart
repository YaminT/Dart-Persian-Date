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
    expect(farv001.toString(showTime: true), "1400/1/1 0:0:0");

    final stringFormat =
        PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
    expect(stringFormat.toString(showTime: true), '1397/4/16 21:43:44');
  });
}
