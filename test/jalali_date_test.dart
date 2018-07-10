import 'package:test/test.dart';

import 'package:jalali_date/jalali_date.dart';

void main() {
  test('Gregorian to Jalali conversion', () {
    final Farv96_1 = new PersianDate.fromGregorian(2017, 03, 21);
    expect(Farv96_1.dateToString(),"1396/1/1");
    final Khord88_12 = new PersianDate.fromGregorian(2009, 06, 02);
    expect(Khord88_12.dateToString(),"1388/3/12");
    final Ordi71_28 = new PersianDate.fromGregorian(1992, 05, 18);
    expect(Ordi71_28.dateToString(),"1371/2/28");
    final Farv00_1 = new PersianDate.fromGregorian(2021, 03, 21);
    expect(Farv00_1.dateToString(),"1400/1/1");
  });
}
