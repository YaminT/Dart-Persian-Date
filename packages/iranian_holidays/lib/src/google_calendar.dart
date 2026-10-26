import 'package:http/http.dart' as http;
import 'package:jalali_date/jalali_date.dart';

import 'day_builder.dart';
import 'holiday.dart';
import 'holiday_source.dart';
import 'http_json.dart';

/// Holidays from Google's public Iranian holiday calendar through the
/// [Google Calendar API](https://developers.google.com/calendar/api), using
/// your own API key.
///
/// Before using it, know that:
///
/// - You need a Google Cloud project with the Calendar API enabled and an
///   API key; Google's quotas and terms apply.
/// - Restrict the key in the Google Cloud console, or call the API through
///   a proxy of your own by setting `baseUri`, because a key shipped inside
///   an app can be extracted.
/// - One request (plus paging) covers a Jalali month, and answers are kept
///   for the life of this object.
/// - Google marks days off in the event description. The default
///   `isHolidayEvent` treats `Public holiday` as a day off, which matches
///   the English calendar [englishCalendarId]. For [persianCalendarId] or
///   another calendar, pass your own `isHolidayEvent`.
/// - Google does not report Fridays; with `fridaysAreHolidays` this source
///   adds them.
class GoogleCalendarSource implements HolidaySource {
  /// Google's public Iranian holiday calendar with English names.
  static const englishCalendarId = 'en.ir#holiday@group.v.calendar.google.com';

  /// Google's public Iranian holiday calendar with Persian names.
  static const persianCalendarId = 'fa.ir#holiday@group.v.calendar.google.com';

  /// The Calendar API address.
  static final Uri defaultBaseUri = Uri.parse(
    'https://www.googleapis.com/calendar/v3/',
  );

  final String _apiKey;
  final String _calendarId;
  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;
  final bool _fridays;
  final bool Function(String summary, String description) _isHolidayEvent;
  final _months = FutureCache<int, List<HolidayDay>>();

  /// Creates the source with your Google Cloud [apiKey].
  ///
  /// [calendarId] defaults to [englishCalendarId]. [baseUri] replaces the
  /// API address, for a proxy of your own; it must end with `/`.
  /// [isHolidayEvent] decides from an event's summary and description
  /// whether it is a day off.
  GoogleCalendarSource({
    required String apiKey,
    String calendarId = englishCalendarId,
    Uri? baseUri,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    bool fridaysAreHolidays = true,
    bool Function(String summary, String description)? isHolidayEvent,
  })  : _apiKey = apiKey,
        _calendarId = calendarId,
        _baseUri = baseUri ?? defaultBaseUri,
        _client = client ?? http.Client(),
        _timeout = timeout,
        _fridays = fridaysAreHolidays,
        _isHolidayEvent = isHolidayEvent ?? _defaultIsHolidayEvent;

  static bool _defaultIsHolidayEvent(String summary, String description) =>
      description.toLowerCase().contains('public holiday');

  @override
  String get name => 'Google Calendar';

  @override
  Uri get website => Uri.parse('https://developers.google.com/calendar/api');

  @override
  String get notice => 'Google Calendar API with your own API key; Google '
      'quotas and terms apply. Restrict the key or use a proxy. Days off '
      'are detected from event descriptions. Fridays are added by this '
      'package.';

  /// The request URL for Jalali [month] of [year], with [pageToken] for
  /// later pages.
  Uri uriFor(int year, int month, {String? pageToken}) {
    final days = daysOfMonth(year, month);
    final after = days.last.toDateTime().add(const Duration(days: 1));
    final end = PersianDate.fromDateTime(after);
    return _baseUri
        .resolve('calendars/${Uri.encodeComponent(_calendarId)}/events')
        .replace(queryParameters: {
      'key': _apiKey,
      'timeMin': '${gregorianIso(days.first)}T00:00:00Z',
      'timeMax': '${gregorianIso(end)}T00:00:00Z',
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '2500',
      if (pageToken != null) 'pageToken': pageToken,
    });
  }

  @override
  Future<HolidayDay> day(PersianDate date) async {
    final days = await month(date.year, date.month);
    return days[date.day - 1];
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) =>
      _months.get(year * 100 + month, () async {
        final days = daysOfMonth(year, month);
        final events = <PersianDate, List<HolidayEvent>>{};
        String? pageToken;
        do {
          final uri = uriFor(year, month, pageToken: pageToken);
          final json = await getJson(_client, uri, _timeout);
          pageToken = readResponse(uri, () {
            final body = json as Map;
            for (final item in body['items'] as List? ?? const []) {
              _addEvent(item as Map, events);
            }
            return body['nextPageToken'] as String?;
          });
        } while (pageToken != null);
        return [
          for (final d in days)
            buildDay(d, events[d] ?? const [], fridays: _fridays),
        ];
      });

  void _addEvent(Map item, Map<PersianDate, List<HolidayEvent>> events) {
    DateTime day(Map? time) {
      final text = (time?['date'] ?? time?['dateTime']) as String;
      return DateTime(
        int.parse(text.substring(0, 4)),
        int.parse(text.substring(5, 7)),
        int.parse(text.substring(8, 10)),
      );
    }

    final summary = item['summary'] as String? ?? '';
    final description = item['description'] as String? ?? '';
    final start = day(item['start'] as Map?);
    final endMap = item['end'] as Map?;
    // All-day events end on the next day, exclusive.
    var end = endMap == null ? start.add(const Duration(days: 1)) : day(endMap);
    if (!end.isAfter(start)) end = start.add(const Duration(days: 1));
    final event = HolidayEvent(
      description: summary,
      additionalDescription: description,
      isHoliday: _isHolidayEvent(summary, description),
    );
    for (var d = start;
        d.isBefore(end);
        d = DateTime(d.year, d.month, d.day + 1)) {
      events.putIfAbsent(PersianDate.fromDateTime(d), () => []).add(event);
    }
  }

  /// Forgets the cached months.
  void clearCache() => _months.clear();

  /// Closes the HTTP client, including one passed to the constructor.
  void close() => _client.close();
}
