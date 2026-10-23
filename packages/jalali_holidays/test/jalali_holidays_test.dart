import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jalali_date/jalali_date.dart';
import 'package:jalali_holidays/jalali_holidays.dart';
import 'package:test/test.dart';

// A trimmed real response of https://holidayapi.ir/jalali/1403/01/03.
const _friday = {
  'is_holiday': true,
  'events': [
    {
      'description': 'روز جهانی آب',
      'additional_description': 'March 22 1900',
      'is_holiday': false,
      'is_religious': false,
    },
    {
      'description': 'جمعه',
      'additional_description': '',
      'is_holiday': true,
      'is_religious': false,
    },
  ],
};

const _workday = {'is_holiday': false, 'events': <Object>[]};

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test('uriFor pads the date', () {
    expect(
      HolidayApiIrSource.uriFor(PersianDate(1403, 1, 3)).toString(),
      'https://holidayapi.ir/jalali/1403/01/03',
    );
  });

  test('day parses events, holidays first', () async {
    final requested = <Uri>[];
    final source = HolidayApiIrSource(
      client: MockClient((request) async {
        requested.add(request.url);
        return _json(_friday);
      }),
    );
    final day = await source.day(PersianDate.withTime(1403, 1, 3, 10));
    expect(requested.single.path, '/jalali/1403/01/03');
    expect(day.date, PersianDate(1403, 1, 3));
    expect(day.date.hasTime, isFalse);
    expect(day.isHoliday, isTrue);
    expect(day.events.map((e) => e.description), ['جمعه', 'روز جهانی آب']);
    expect(day.holidays.single.description, 'جمعه');
    expect(day.events.last.additionalDescription, 'March 22 1900');
    expect(() => day.events.add(day.events.first), throwsUnsupportedError);
  });

  test('errors become HolidaySourceException', () async {
    final status = HolidayApiIrSource(
      client: MockClient((_) async => http.Response('oops', 500)),
    );
    await expectLater(
      status.day(PersianDate(1403, 1, 1)),
      throwsA(isA<HolidaySourceException>()
          .having((e) => e.statusCode, 'statusCode', 500)),
    );

    final garbage = HolidayApiIrSource(
      client: MockClient((_) async => http.Response('<html>', 200)),
    );
    await expectLater(
      garbage.day(PersianDate(1403, 1, 1)),
      throwsA(isA<HolidaySourceException>()),
    );

    final network = HolidayApiIrSource(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      network.day(PersianDate(1403, 1, 1)),
      throwsA(isA<HolidaySourceException>()
          .having((e) => e.message, 'message', 'offline')),
    );

    final slow = HolidayApiIrSource(
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _json(_workday);
      }),
    );
    await expectLater(
      slow.day(PersianDate(1403, 1, 1)),
      throwsA(isA<HolidaySourceException>()),
    );
  });

  test('month returns every day in order with limited concurrency', () async {
    var active = 0;
    var peak = 0;
    final source = HolidayApiIrSource(
      concurrency: 3,
      client: MockClient((request) async {
        active++;
        if (active > peak) peak = active;
        await Future<void>.delayed(const Duration(milliseconds: 2));
        active--;
        return _json(request.url.path.endsWith('/03') ? _friday : _workday);
      }),
    );
    final days = await source.month(1403, 7);
    expect(days, hasLength(30));
    expect(days.first.date, PersianDate(1403, 7, 1));
    expect(days.last.date, PersianDate(1403, 7, 30));
    expect(days[2].isHoliday, isTrue);
    expect(days[3].isHoliday, isFalse);
    expect(peak, lessThanOrEqualTo(3));
  });

  test('CachedHolidaySource requests each day once and retries failures',
      () async {
    var calls = 0;
    var fail = true;
    final cached = CachedHolidaySource(
      HolidayApiIrSource(
        client: MockClient((_) async {
          calls++;
          if (fail) return http.Response('down', 503);
          return _json(_workday);
        }),
      ),
    );
    final date = PersianDate(1403, 2, 5);
    await expectLater(cached.day(date), throwsA(isA<HolidaySourceException>()));
    fail = false;
    await cached.day(date);
    await cached.day(PersianDate.withTime(1403, 2, 5, 12));
    expect(calls, 2);
    await cached.month(1403, 2);
    expect(calls, 32);
    cached.clear();
    await cached.day(date);
    expect(calls, 33);
    expect(cached.name, 'holidayapi.ir');
  });

  test('source metadata', () {
    final source = HolidayApiIrSource();
    expect(source.name, 'holidayapi.ir');
    expect(source.website.host, 'holidayapi.ir');
    expect(source.notice, contains('time.ir'));
    source.close();
  });
}
