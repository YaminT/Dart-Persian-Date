import 'package:http/http.dart' as http;
import 'package:jalali_date/jalali_date.dart';

import 'day_builder.dart';
import 'holiday.dart';
import 'holiday_source.dart';
import 'http_json.dart';

/// Holidays from [Calendarific](https://calendarific.com), a commercial
/// service with a free tier, using your own API key.
///
/// Before using it, know that:
///
/// - You need your own API key from calendarific.com; the free tier has a
///   monthly request limit, and their terms of use apply.
/// - A key shipped inside a mobile or web app can be extracted. Prefer a
///   small server of your own that adds the key, and point [baseUri] at it.
/// - One request covers a whole Gregorian year; a Jalali month needs one or
///   two years, and answers are kept for the life of this object.
/// - Calendarific does not report Fridays; with `fridaysAreHolidays` this
///   source adds them, like holidayapi.ir does.
/// - Event names are in English unless you pass a `language` your plan
///   supports. Check their accuracy for Iranian religious holidays.
class CalendarificSource implements HolidaySource {
  /// Calendarific's API address.
  static final Uri defaultBaseUri = Uri.parse(
    'https://calendarific.com/api/v2/',
  );

  final String _apiKey;
  final String _country;
  final String? _language;
  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;
  final bool _fridays;
  final bool Function(List<String> types) _isHolidayType;
  final _years = FutureCache<int, Map<PersianDate, List<HolidayEvent>>>();

  /// Creates the source with your Calendarific [apiKey].
  ///
  /// [country] is an ISO 3166 code, `IR` by default. [language] is passed
  /// through when set. [baseUri] replaces Calendarific's address, for a
  /// proxy of your own; it must end with `/`. [isHolidayType] decides from
  /// an event's `type` list whether it is a day off; by default
  /// `National holiday` and `Public holiday` are.
  CalendarificSource({
    required String apiKey,
    String country = 'IR',
    String? language,
    Uri? baseUri,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    bool fridaysAreHolidays = true,
    bool Function(List<String> types)? isHolidayType,
  })  : _apiKey = apiKey,
        _country = country,
        _language = language,
        _baseUri = baseUri ?? defaultBaseUri,
        _client = client ?? http.Client(),
        _timeout = timeout,
        _fridays = fridaysAreHolidays,
        _isHolidayType = isHolidayType ?? _defaultIsHolidayType;

  static bool _defaultIsHolidayType(List<String> types) => types.any((type) {
        final lower = type.toLowerCase();
        return lower.contains('national holiday') ||
            lower.contains('public holiday');
      });

  @override
  String get name => 'Calendarific';

  @override
  Uri get website => Uri.parse('https://calendarific.com');

  @override
  String get notice => 'Commercial service; needs your own API key and has '
      'a monthly request limit on the free tier. Keep the key out of shipped '
      'apps by using a proxy. Fridays are added by this package.';

  /// The request URL for Gregorian [year].
  Uri uriFor(int year) => _baseUri.resolve('holidays').replace(
        queryParameters: {
          'api_key': _apiKey,
          'country': _country,
          'year': '$year',
          if (_language != null) 'language': _language,
        },
      );

  Future<Map<PersianDate, List<HolidayEvent>>> _year(int year) =>
      _years.get(year, () async {
        final uri = uriFor(year);
        final json = await getJson(_client, uri, _timeout);
        return readResponse(uri, () {
          final body = json as Map;
          final code = (body['meta'] as Map?)?['code'];
          if (code != null && code != 200) {
            throw HolidaySourceException(
              'Calendarific error ${(body['meta'] as Map)['error_detail'] ?? ''}'
                  .trim(),
              uri: redactUri(uri),
              statusCode: code is int ? code : null,
            );
          }
          final events = <PersianDate, List<HolidayEvent>>{};
          for (final item in (body['response'] as Map)['holidays'] as List) {
            final holiday = item as Map;
            final iso = ((holiday['date'] as Map)['iso'] as String);
            final types = [
              for (final type in holiday['type'] as List? ?? const []) '$type',
            ];
            final date = PersianDate.fromGregorian(
              int.parse(iso.substring(0, 4)),
              int.parse(iso.substring(5, 7)),
              int.parse(iso.substring(8, 10)),
            );
            events.putIfAbsent(date, () => []).add(HolidayEvent(
                  description: holiday['name'] as String,
                  additionalDescription:
                      holiday['description'] as String? ?? '',
                  isHoliday: _isHolidayType(types),
                  isReligious: types.any((type) {
                    final lower = type.toLowerCase();
                    return lower.contains('religious') ||
                        lower.contains('muslim');
                  }),
                ));
          }
          return events;
        });
      });

  @override
  Future<HolidayDay> day(PersianDate date) async {
    final events = await _year(date.toDateTime().year);
    return buildDay(date, events[date] ?? const [], fridays: _fridays);
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) async {
    final days = daysOfMonth(year, month);
    final years = {
      for (final d in [days.first, days.last]) d.toDateTime().year
    };
    final events = <PersianDate, List<HolidayEvent>>{
      for (final y in years) ...await _year(y),
    };
    return [
      for (final d in days)
        buildDay(d, events[d] ?? const [], fridays: _fridays),
    ];
  }

  /// Forgets the cached years.
  void clearCache() => _years.clear();

  /// Closes the HTTP client, including one passed to the constructor.
  void close() => _client.close();
}
