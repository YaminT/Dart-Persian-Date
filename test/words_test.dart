import 'package:jalali_date/jalali_date.dart';
import 'package:test/test.dart';

void main() {
  test('cardinals', () {
    const cases = {
      0: 'صفر',
      1: 'یک',
      9: 'نه',
      10: 'ده',
      11: 'یازده',
      12: 'دوازده',
      13: 'سیزده',
      15: 'پانزده',
      16: 'شانزده',
      17: 'هفده',
      18: 'هجده',
      19: 'نوزده',
      20: 'بیست',
      21: 'بیست و یک',
      30: 'سی',
      99: 'نود و نه',
      100: 'صد',
      101: 'صد و یک',
      110: 'صد و ده',
      200: 'دویست',
      300: 'سیصد',
      500: 'پانصد',
      999: 'نهصد و نود و نه',
      1000: 'هزار',
      1001: 'هزار و یک',
      1403: 'هزار و چهارصد و سه',
      2000: 'دو هزار',
      2585: 'دو هزار و پانصد و هشتاد و پنج',
      10000: 'ده هزار',
      100000: 'صد هزار',
      1000000: 'یک میلیون',
      1001000: 'یک میلیون و یک هزار',
      1000001: 'یک میلیون و یک',
      2500000000: 'دو میلیارد و پانصد میلیون',
      -61: 'منفی شصت و یک',
    };
    cases.forEach((n, words) => expect(toPersianWords(n), words, reason: '$n'));
  });

  test('ordinals', () {
    const cases = {
      1: 'یکم',
      2: 'دوم',
      3: 'سوم',
      4: 'چهارم',
      9: 'نهم',
      10: 'دهم',
      13: 'سیزدهم',
      20: 'بیستم',
      23: 'بیست و سوم',
      24: 'بیست و چهارم',
      30: 'سی‌ام',
      31: 'سی و یکم',
      100: 'صدم',
      1000: 'هزارم',
    };
    cases.forEach((n, words) =>
        expect(toPersianWords(n, ordinal: true), words, reason: '$n'));
  });

  test('every number to 1000 is well formed', () {
    for (var n = 0; n <= 1000; n++) {
      final words = toPersianWords(n);
      expect(words, isNot(contains('  ')), reason: '$n');
      expect(words, isNot(startsWith(' ')), reason: '$n');
      expect(words, isNot(endsWith(' و')), reason: '$n');
      expect(words.split(' و ').length, lessThanOrEqualTo(3), reason: '$n');
    }
  });

  test('the smallest and largest int', () {
    // Stays within 2^53 so the test also holds on the web.
    expect(toPersianWords(9007199254740991), startsWith('نه کوادریلیون'));
    expect(toPersianWords(-9007199254740991), startsWith('منفی نه کوادریلیون'));
  });

  test('format tokens', () {
    final date = PersianDate(1403, 5, 24);
    expect(date.format('EEEE dw MMMM yw'),
        'چهارشنبه بیست و چهارم مرداد هزار و چهارصد و سه');
    expect(PersianDate(1405, 1, 1).format('dw MMMM'), 'یکم فروردین');
    expect(PersianDate(1405, 1, 30).format('dw MMMM'), 'سی‌ام فروردین');
    expect(PersianDate(1405, 1, 4).format('yw', era: JalaliEra.shahanshahi),
        'دو هزار و پانصد و هشتاد و پنج');
    expect(PersianDate(1405, 1, 4).format("'dw' d"), 'dw 4');
    expect(HijriDate(1448, 1, 10).format('dw MMMM yw'),
        'دهم محرم هزار و چهارصد و چهل و هشت');
  });
}
