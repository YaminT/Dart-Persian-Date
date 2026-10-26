import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jalali_date/jalali_date.dart';
import 'package:jalali_holidays/jalali_holidays.dart';
import 'package:test/test.dart';

// Official holidays of 1405 from the calendar published on time.ir, without
// Fridays.
const _official1405 = [
  '1405/01/01', '1405/01/02', '1405/01/03', '1405/01/04', '1405/01/12',
  '1405/01/13', '1405/01/25', '1405/03/06', '1405/03/14', '1405/03/15',
  '1405/04/03', '1405/04/04', '1405/05/13', '1405/05/21', '1405/05/22',
  '1405/05/30', '1405/06/08', '1405/08/22', '1405/10/02', '1405/10/16',
  '1405/11/04', '1405/11/22', '1405/12/09', '1405/12/19', '1405/12/20',
  '1405/12/29', //
];

// The same for 1406.
const _official1406 = [
  '1406/01/01', '1406/01/02', '1406/01/03', '1406/01/04', '1406/01/12',
  '1406/01/13', '1406/01/14', '1406/02/27', '1406/03/04', '1406/03/14',
  '1406/03/15', '1406/03/25', '1406/03/26', '1406/05/03', '1406/05/11',
  '1406/05/12', '1406/05/20', '1406/05/29', '1406/08/12', '1406/09/21',
  '1406/10/05', '1406/10/23', '1406/11/22', '1406/11/29', '1406/12/08',
  '1406/12/09', '1406/12/29', //
];

// 1 Shawwal (Eid al-Fitr) on the published calendars, 1387 to 1404.
const _eidAlFitr = [
  '1387/07/10', '1388/06/29', '1389/06/19', '1390/06/09', '1391/05/29',
  '1392/05/18', '1393/05/07', '1394/04/27', '1395/04/16', '1396/04/05',
  '1397/03/25', '1398/03/15', '1399/03/04', '1400/02/23', '1401/02/13',
  '1402/02/02', '1403/01/22', '1404/01/11', //
];

void main() {
  final source = OfflineHolidaySource();

  test('1405 and 1406 match the published calendar', () {
    for (final (year, expected) in [
      (1405, _official1405),
      (1406, _official1406),
    ]) {
      expect(
        source.holidaysOf(year).map((d) => d.date.format('yyyy/MM/dd')),
        expected,
        reason: '$year',
      );
    }
  });

  test('Eid al-Fitr matches the published calendar', () {
    for (final text in _eidAlFitr) {
      final day = source.dayOf(PersianDate.parse(text));
      expect(
        day.holidays.map((e) => e.description),
        contains('عید سعید فطر'),
        reason: text,
      );
    }
  });

  test('Hijri events carry the Hijri date', () {
    final ashura = source.dayOf(PersianDate(1405, 4, 4));
    expect(ashura.isHoliday, isTrue);
    expect(ashura.events.single.description, 'عاشورای حسینی');
    expect(ashura.events.single.additionalDescription, '10 محرم 1448');
    expect(ashura.events.single.isReligious, isTrue);

    final nowruz = source.dayOf(PersianDate(1405, 1, 1));
    expect(nowruz.events.map((e) => e.description),
        ['جشن نوروز/جشن سال نو', 'عید سعید فطر']);
    expect(nowruz.events.first.additionalDescription, '1 فروردین');
    expect(nowruz.events.first.isReligious, isFalse);
  });

  test('Imam Reza is on 29 Safar even when Safar has 30 days', () {
    expect(source.hijriDate(PersianDate(1404, 6, 3)), HijriDate(1447, 3, 1));
    expect(source.dayOf(PersianDate(1404, 6, 1)).holidays.single.description,
        'شهادت امام رضا (ع)');
    expect(source.dayOf(PersianDate(1404, 6, 2)).isHoliday, isFalse);
  });

  test('hijriDate', () {
    expect(source.hijriDate(PersianDate(1405, 1, 1)), HijriDate(1447, 10, 1));
    expect(source.hijriDate(PersianDate.withTime(1405, 4, 4, 23)).toString(),
        '10 محرم 1448');
  });

  test('supported range endpoints and negative Hijri years', () async {
    for (final date in [PersianDate.min, PersianDate.max]) {
      expect(source.dayOf(date).date, date);
      expect(await source.month(date.year, date.month), isNotEmpty);
      final hijri = source.hijriDate(date);
      expect(hijri.day, inInclusiveRange(1, 30));
      expect(hijri.month, inInclusiveRange(1, 12));
    }
    var date = PersianDate.min;
    var previous = source.hijriDate(date);
    for (var i = 0; i < 800; i++) {
      date = date.addDays(1);
      final next = source.hijriDate(date);
      if (next.day == 1) {
        expect(previous.day, inInclusiveRange(29, 30));
        expect(next.month, previous.month % 12 + 1);
      } else {
        expect(next.day, previous.day + 1);
      }
      previous = next;
    }
  });

  test('holiday configuration is copied and immutable', () {
    final list = [const OfficialHoliday.jalali(1, 1, 'custom')];
    final custom = OfflineHolidaySource(holidays: list);
    custom.holidaysOf(1405);
    list.clear();
    expect(custom.holidaysOf(1406).single.events.single.description, 'custom');
    expect(() => custom.holidays.clear(), throwsUnsupportedError);
  });

  test('Fridays', () {
    final friday = PersianDate(1405, 1, 7);
    expect(friday.isWeekend, isTrue);
    expect(source.dayOf(friday).isHoliday, isTrue);
    expect(source.dayOf(friday).events.single.description, 'جمعه');
    final noFridays = OfflineHolidaySource(fridaysAreHolidays: false);
    expect(noFridays.dayOf(friday).isHoliday, isFalse);
    expect(source.dayOf(PersianDate(1405, 1, 8)).isHoliday, isFalse);
  });

  test('hijriMonthStarts moves Hijri holidays', () {
    final corrected = OfflineHolidaySource(
      hijriMonthStarts: {(1448, 1): PersianDate(1405, 3, 27)},
    );
    expect(corrected.dayOf(PersianDate(1405, 4, 3)).isHoliday, isFalse);
    expect(
      corrected.dayOf(PersianDate(1405, 4, 4)).holidays.single.description,
      'تاسوعای حسینی',
    );
    expect(
      corrected
          .dayOf(PersianDate(1405, 4, 5))
          .holidays
          .map((e) => e.description),
      contains('عاشورای حسینی'),
    );
    expect(
        corrected.hijriDate(PersianDate(1405, 3, 27)), HijriDate(1448, 1, 1));
  });

  test('custom holidays', () {
    final custom = OfflineHolidaySource(holidays: const [
      OfficialHoliday.jalali(7, 1, 'test'),
      OfficialHoliday.hijri(9, 1, 'ramadan'),
    ]);
    expect(custom.holidaysOf(1405).map((d) => d.events.single.description),
        ['test', 'ramadan']);
  });

  test('day and month', () async {
    final day = await source.day(PersianDate(1405, 1, 13));
    expect(day.isHoliday, isTrue);
    final month = await source.month(1405, 12);
    expect(month, hasLength(29));
    expect(month.where((d) => d.isHoliday && !d.date.isWeekend).length, 4);
    expect(source.notice, contains('one day off'));
  });

  test('FallbackHolidaySource uses the fallback when the primary fails',
      () async {
    var fail = true;
    final online = HolidayApiIrSource(
      client: MockClient((_) async => fail
          ? throw http.ClientException('offline')
          : http.Response('{"is_holiday":false,"events":[]}', 200)),
    );
    final both = FallbackHolidaySource(online, source);
    final ashura = PersianDate(1405, 4, 4);
    expect((await both.day(ashura)).isHoliday, isTrue);
    expect(await both.month(1405, 4), hasLength(31));
    fail = false;
    expect((await both.day(ashura)).isHoliday, isFalse);
    expect(both.name, 'holidayapi.ir, else Offline calculation');
  });
}
