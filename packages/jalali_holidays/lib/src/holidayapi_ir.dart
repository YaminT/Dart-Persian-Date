import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';
import 'holiday_source.dart';

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
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw HolidaySourceException('Request timed out', uri: uri);
    } on http.ClientException catch (error) {
      throw HolidaySourceException(error.message, uri: uri);
    }
    if (response.statusCode != 200) {
      throw HolidaySourceException(
        'Unexpected response',
        uri: uri,
        statusCode: response.statusCode,
      );
    }
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      final events = [
        for (final event in json['events'] as List)
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
        isHoliday: json['is_holiday'] as bool,
        events: events,
      );
    } on Object catch (error) {
      if (error is HolidaySourceException) rethrow;
      throw HolidaySourceException('Unreadable response: $error', uri: uri);
    }
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) async {
    final first = PersianDate(year, month, 1);
    final days = first.daysUntil(first.lastDayOfMonth).toList();
    final results = List<HolidayDay?>.filled(days.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < days.length) {
        final index = next++;
        results[index] = await day(days[index]);
      }
    }

    await Future.wait([for (var i = 0; i < _concurrency; i++) worker()]);
    return results.cast<HolidayDay>();
  }

  /// Closes the HTTP client, including one passed to the constructor.
  void close() => _client.close();
}
