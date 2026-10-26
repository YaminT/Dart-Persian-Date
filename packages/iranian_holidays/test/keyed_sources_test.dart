// Response shapes follow the providers' documentation; these tests use mock
// clients because the services need an API key.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jalali_date/jalali_date.dart';
import 'package:iranian_holidays/iranian_holidays.dart';
import 'package:iranian_holidays/src/http_json.dart' show redactUri;
import 'package:test/test.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

Map<String, Object> _calendarificHoliday(
  String name,
  String iso,
  List<String> types,
) =>
    {
      'name': name,
      'description': '$name description',
      'date': {'iso': iso},
      'type': types,
    };

Map<String, Object> _googleEvent(
  String summary,
  String description,
  String start,
  String end,
) =>
    {
      'summary': summary,
      'description': description,
      'start': {'date': start},
      'end': {'date': end},
    };

void main() {
  group('CalendarificSource', () {
    final years = <String>[];
    CalendarificSource source({String? language, Uri? baseUri}) =>
        CalendarificSource(
          apiKey: 'secret',
          language: language,
          baseUri: baseUri,
          client: MockClient((request) async {
            final year = request.url.queryParameters['year']!;
            years.add(year);
            return _json({
              'meta': {'code': 200},
              'response': {
                'holidays': [
                  if (year == '2024') ...[
                    _calendarificHoliday(
                        'Nowruz', '2024-03-20', ['National holiday']),
                    _calendarificHoliday(
                        'Ashura', '2024-07-16', ['National holiday', 'Muslim']),
                    _calendarificHoliday('March Equinox',
                        '2024-03-20T06:06:24+03:30', ['Season']),
                  ],
                  if (year == '2025')
                    _calendarificHoliday(
                        'Nowruz', '2025-03-21', ['National holiday']),
                ],
              },
            });
          }),
        );

    setUp(years.clear);

    test('request URL', () {
      final uri = source(language: 'fa').uriFor(2024);
      expect(uri.toString(),
          'https://calendarific.com/api/v2/holidays?api_key=secret&country=IR&year=2024&language=fa');
      final proxy = source(baseUri: Uri.parse('https://example.com/cal/'));
      expect(proxy.uriFor(2024).path, '/cal/holidays');
    });

    test('day maps events and types', () async {
      final s = source();
      final nowruz = await s.day(PersianDate(1403, 1, 1));
      expect(nowruz.isHoliday, isTrue);
      expect(
          nowruz.events.map((e) => e.description), ['Nowruz', 'March Equinox']);
      expect(nowruz.events.last.isHoliday, isFalse);
      final ashura = await s.day(PersianDate(1403, 4, 26));
      expect(ashura.holidays.single.isReligious, isTrue);
      final workday = await s.day(PersianDate(1403, 2, 5));
      expect(workday.isHoliday, isFalse);
      expect(years, ['2024'], reason: 'one request per Gregorian year');
    });

    test('Fridays are added unless disabled', () async {
      final friday = await source().day(PersianDate(1403, 1, 3));
      expect(friday.isHoliday, isTrue);
      expect(friday.events.first.description, 'جمعه');
      final plain = CalendarificSource(
        apiKey: 'k',
        fridaysAreHolidays: false,
        client: MockClient((_) async => _json({
              'meta': {'code': 200},
              'response': {'holidays': <Object>[]},
            })),
      );
      expect((await plain.day(PersianDate(1403, 1, 3))).isHoliday, isFalse);
    });

    test('a month across two Gregorian years', () async {
      final days = await source().month(1403, 12);
      expect(days, hasLength(30));
      expect(days.last.date, PersianDate(1403, 12, 30));
      expect(years.toSet(), {'2025'});
      final dey = await source().month(1403, 10);
      expect(dey, hasLength(30));
      expect(years.toSet(), {'2024', '2025'});
    });

    test('errors hide the key', () async {
      final s = CalendarificSource(
        apiKey: 'secret',
        client: MockClient((_) async => _json({
              'meta': {
                'code': 401,
                'error_type': 'auth failed',
                'error_detail': 'Missing or invalid api credentials.',
              },
              'response': <Object>[],
            }, 401)),
      );
      await expectLater(
        s.day(PersianDate(1403, 1, 1)),
        throwsA(isA<HolidaySourceException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => '$e', 'text', isNot(contains('secret')))
            .having((e) => '$e', 'text', contains('api_key=REDACTED'))),
      );
    });

    test('a 200 response with an error code in meta', () async {
      final s = CalendarificSource(
        apiKey: 'k',
        client: MockClient((_) async => _json({
              'meta': {'code': 429, 'error_detail': 'Too many requests'},
              'response': <Object>[],
            })),
      );
      await expectLater(
        s.day(PersianDate(1403, 1, 1)),
        throwsA(isA<HolidaySourceException>()
            .having((e) => e.statusCode, 'statusCode', 429)),
      );
    });
  });

  group('GoogleCalendarSource', () {
    final requests = <Uri>[];
    GoogleCalendarSource source({
      String calendarId = GoogleCalendarSource.englishCalendarId,
      bool Function(String, String)? isHolidayEvent,
    }) =>
        GoogleCalendarSource(
          apiKey: 'secret',
          calendarId: calendarId,
          isHolidayEvent: isHolidayEvent,
          client: MockClient((request) async {
            requests.add(request.url);
            final page = request.url.queryParameters['pageToken'];
            return _json({
              'items': [
                if (page == null) ...[
                  _googleEvent(
                      'Nowruz', 'Public holiday', '2024-03-20', '2024-03-24'),
                  _googleEvent(
                      'Mother\'s Day',
                      'Observance\nTo hide observances, go to Google Calendar Settings > Holidays in Iran',
                      '2024-01-03',
                      '2024-01-04'),
                ],
                if (page == 'p2')
                  _googleEvent('Islamic Republic Day', 'Public holiday',
                      '2024-03-31', '2024-04-01'),
              ],
              if (page == null) 'nextPageToken': 'p2',
            });
          }),
        );

    setUp(requests.clear);

    test('request URL', () {
      final uri = source().uriFor(1403, 1);
      expect(uri.path,
          '/calendar/v3/calendars/en.ir%23holiday%40group.v.calendar.google.com/events');
      expect(uri.queryParameters['timeMin'], '2024-03-20T00:00:00Z');
      expect(uri.queryParameters['timeMax'], '2024-04-20T00:00:00Z');
      expect(uri.queryParameters['key'], 'secret');
      expect(uri.queryParameters['singleEvents'], 'true');
    });

    test('month follows pages and expands multi-day events', () async {
      final days = await source().month(1403, 1);
      expect(requests, hasLength(2));
      expect(days, hasLength(31));
      for (final d in [1, 2, 3, 4]) {
        expect(
            days[d - 1].holidays.map((e) => e.description), contains('Nowruz'),
            reason: '$d');
      }
      expect(
          days[4].events.map((e) => e.description), isNot(contains('Nowruz')));
      expect(days[11].holidays.map((e) => e.description),
          ['Islamic Republic Day']);
      expect(days[1].isHoliday, isTrue);
      expect(days[1].events.first.description, 'Nowruz');
    });

    test('day uses the cached month', () async {
      final s = source();
      await s.day(PersianDate(1403, 1, 1));
      await s.day(PersianDate(1403, 1, 12));
      expect(requests, hasLength(2));
      s.clearCache();
      await s.day(PersianDate(1403, 1, 1));
      expect(requests, hasLength(4));
    });

    test('observances are not days off; custom rule for other calendars',
        () async {
      final s = GoogleCalendarSource(
        apiKey: 'k',
        fridaysAreHolidays: false,
        client: MockClient((_) async => _json({
              'items': [
                _googleEvent('روز مادر', 'مناسبت', '2024-01-03', '2024-01-04'),
                _googleEvent(
                    'عید فطر', 'تعطیل رسمی', '2024-04-10', '2024-04-11'),
              ],
            })),
        calendarId: GoogleCalendarSource.persianCalendarId,
        isHolidayEvent: (summary, description) => description == 'تعطیل رسمی',
      );
      final farvardin = await s.month(1403, 1);
      expect(farvardin[21].isHoliday, isTrue);
      final dey = await s.month(1402, 10);
      expect(dey[12].isHoliday, isFalse);
      expect(dey[12].events.single.description, 'روز مادر');
    });

    test('errors hide the key', () async {
      final s = GoogleCalendarSource(
        apiKey: 'secret',
        client: MockClient((_) async => _json({
              'error': {'code': 400, 'message': 'API key not valid.'},
            }, 400)),
      );
      await expectLater(
        s.day(PersianDate(1403, 1, 1)),
        throwsA(isA<HolidaySourceException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => '$e', 'text', isNot(contains('secret')))),
      );
    });
  });

  test('redactUri hides secret parameters only', () {
    final uri = Uri.parse('https://x.test/a?key=1&api_key=2&year=2024');
    expect(redactUri(uri).queryParameters,
        {'key': 'REDACTED', 'api_key': 'REDACTED', 'year': '2024'});
  });
}
