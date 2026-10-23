# jalali_holidays

Iranian holidays and events for [jalali_date](https://pub.dev/packages/jalali_date) dates.
تعطیلات و مناسبت‌های تقویم رسمی ایران برای تاریخ‌های `jalali_date`.

Holidays in Iran cannot be computed from the calendar alone.
Religious holidays follow the lunar Hijri calendar, and their dates are announced each year.
So this package asks a holiday source, and you choose that source explicitly.
No source is built in by default, because each one is run by a third party with its own terms, limits, and accuracy, and every request tells that party which dates your app looks up.

## Choosing a source

| Source | Cost and key | Class | Know before using |
| ------ | ------------ | ----- | ----------------- |
| [holidayapi.ir](https://holidayapi.ir) | Free, no key | `HolidayApiIrSource` | Community service, no service level agreement or published terms. Data is extracted from time.ir. One request per day. No CORS headers, so it does not work in browsers or Flutter web. Fridays count as holidays. |
| [Calendarific](https://calendarific.com) | Free tier with an API key and a monthly request limit; paid plans above it | `CalendarificSource` | Commercial service with Iran coverage; one request per Gregorian year. Shipping the key inside an app exposes it; use a proxy of your own through `baseUri`. Names are English unless your plan supports `language`. Fridays are added by this package. |
| [Google Calendar API](https://developers.google.com/calendar/api) public holiday calendar | Free quota with a Google Cloud API key | `GoogleCalendarSource` | Reads Google's public Iranian holiday calendar, one request per Jalali month. Needs a Google Cloud project with the Calendar API enabled; restrict the key or use a proxy through `baseUri`. Days off are detected from the event description (`Public holiday` on the English calendar); pass `isHolidayEvent` for the Persian calendar. Fridays are added by this package. |
| Your own table | Free | No, implement `HolidaySource` | Works offline and needs no third party. You update it yourself each year from the official announcement. |

Not usable today: [Nager.Date](https://date.nager.at) is free but has no Iranian data, and [time.ir](https://www.time.ir) is a website without a public API.

Tell your users where holiday data comes from, for example on an about or settings screen; `HolidaySource.name`, `website`, and `notice` hold that text.

## Usage

```dart
import 'package:jalali_date/jalali_date.dart';
import 'package:jalali_holidays/jalali_holidays.dart';

Future<void> main() async {
  final api = HolidayApiIrSource();
  print(api.notice); // read this before shipping

  final source = CachedHolidaySource(api);
  final day = await source.day(PersianDate(1403, 1, 1));
  print(day.isHoliday); // true
  print(day.holidays.first.description); // جشن نوروز/جشن سال نو

  final mehr = await source.month(1403, 7);
  print(mehr.where((d) => d.isHoliday).map((d) => d.date));
  api.close();
}
```

`CachedHolidaySource` keeps answers in memory, so each day is requested once; failed requests are retried on the next call.
`CalendarificSource` and `GoogleCalendarSource` already cache whole years or months, so they do not need it.
Errors from any source are `HolidaySourceException`, and API keys are replaced by `REDACTED` in its URL.

### Sources with your own API key

```dart
// Calendarific: https://calendarific.com, key from your account.
final calendarific = CalendarificSource(apiKey: calendarificKey);

// Google Calendar API: key from a Google Cloud project with the Calendar API.
final google = GoogleCalendarSource(apiKey: googleKey);

// Persian names from Google; tell it how days off are marked there.
final googleFa = GoogleCalendarSource(
  apiKey: googleKey,
  calendarId: GoogleCalendarSource.persianCalendarId,
  isHolidayEvent: (summary, description) => description.contains('تعطیل'),
);

// Keep the key on your server: a proxy that adds it and forwards the request.
final proxied = CalendarificSource(
  apiKey: 'unused',
  baseUri: Uri.parse('https://api.example.com/calendarific/'),
);
```

Read keys from your configuration (for example `--dart-define`), never from source code.
These two classes are tested against the providers' documented response formats with mock clients; check the results against the official calendar before you rely on them.

## Writing your own source

```dart
class MyTableSource implements HolidaySource {
  @override
  String get name => 'Built-in table 1403';

  @override
  Uri get website => Uri.parse('https://example.com/holidays');

  @override
  String get notice => 'Official 1403 holidays, updated by hand.';

  static final _holidays = {
    PersianDate(1403, 1, 1): 'جشن نوروز',
    // ...
  };

  @override
  Future<HolidayDay> day(PersianDate date) async {
    final key = PersianDate(date.year, date.month, date.day);
    final name = _holidays[key];
    return HolidayDay(
      date: key,
      isHoliday: name != null || key.isWeekend,
      events: [if (name != null) HolidayEvent(description: name, isHoliday: true)],
    );
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) {
    final first = PersianDate(year, month, 1);
    return Future.wait(first.daysUntil(first.lastDayOfMonth).map(day));
  }
}
```

## License

Apache-2.0.
See [LICENSE](LICENSE).
