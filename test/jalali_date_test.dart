import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  test('Gregorian to Jalali conversion', () {
    final Farv96_1 = new PersianDate.fromGregorian(2017, 03, 21);
    expect(Farv96_1.toString(), "1396/1/1");
    final Khord88_12 = new PersianDate.fromGregorian(2009, 06, 02);
    expect(Khord88_12.toString(), "1388/3/12");
    final Ordi71_28 = new PersianDate.fromGregorian(1992, 05, 18);
    expect(Ordi71_28.toString(), "1371/2/28");
    final Farv00_1 = new PersianDate.fromGregorian(2021, 03, 21);
    expect(Farv00_1.toString(showTime: true), "1400/1/1 0:0:0");

    final string_format = new PersianDate.fromGregorianString('2018-07-07T21:43:44.909Z');
    expect(string_format.toString(showTime: true), '1397/4/16 21:43:44');
  });
}
