import 'package:http/http.dart' as http;
import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';
import 'holiday_source.dart';
import 'http_json.dart';
import 'pool.dart';

/// Holidays from [holidayapi.ir](https://holidayapi.ir), a free service
/// with no API key.
///
/// Before using it, know that:
///
/// - It is a free community service with no service level agreement or
///   published terms of use; it can be slow, change, or disappear.
/// - Its data is extracted from time.ir, the Iranian official calendar
///   site, and covers Iranian holidays only.
/// - It answers one day per request, so [month] sends one request per day.
///   Wrap it in a `CachedHolidaySource`.
/// - It sends no CORS headers, so browsers block it and it does not work
///   in Flutter web or other web apps; use it from mobile, desktop, or a
///   server.
/// - Fridays are reported as holidays, with a `جمعه` event.
class HolidayApiIrSource implements HolidaySource {
  final http.Client _client;
  final Duration _timeout;
  final int _concurrency;

  /// Creates the source.
  ///
  /// Pass [client] to reuse or mock an HTTP client. [timeout] limits each
  /// request, and [concurrency] limits parallel requests in [month].
  HolidayApiIrSource({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    int concurrency = 4,
  })  : _client = client ?? http.Client(),
        _timeout = timeout,
        _concurrency = concurrency < 1 ? 1 : concurrency;

  /// Base address of the service.
  static final Uri baseUri = Uri.parse('https://holidayapi.ir/');

  @override
  String get name => 'holidayapi.ir';

  @override
  Uri get website => baseUri;

  @override
  String get notice => 'Free community service with no API key, no service '
      'level agreement, and no published terms. Data is extracted from '
      'time.ir. One request per day; not usable from web browsers (no CORS).';

  /// The request URL for [date].
  static Uri uriFor(PersianDate date) =>
      baseUri.resolve('jalali/${date.format('yyyy/MM/dd')}');

  @override
  Future<HolidayDay> day(PersianDate date) async {
    final uri = uriFor(date);
    final json = await getJson(_client, uri, _timeout);
    return readResponse(uri, () {
      final body = json as Map;
      final events = [
        for (final event in body['events'] as List)
          HolidayEvent(
            description: (event as Map)['description'] as String,
            additionalDescription:
                event['additional_description'] as String? ?? '',
            isHoliday: event['is_holiday'] as bool,
            isReligious: event['is_religious'] as bool? ?? false,
          ),
      ]..sort((a, b) => (b.isHoliday ? 1 : 0) - (a.isHoliday ? 1 : 0));
      return HolidayDay(
        date: PersianDate(date.year, date.month, date.day),
        isHoliday: body['is_holiday'] as bool,
        events: events,
      );
    });
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) {
    final first = PersianDate(year, month, 1);
    return mapWithConcurrency(
      first.daysUntil(first.lastDayOfMonth).toList(),
      _concurrency,
      day,
    );
  }

  /// Closes the HTTP client, including one passed to the constructor.
  void close() => _client.close();
}
