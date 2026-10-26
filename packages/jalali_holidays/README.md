# jalali_holidays

Iranian holidays and events for [jalali_date](https://pub.dev/packages/jalali_date) dates.
تعطیلات و مناسبت‌های تقویم رسمی ایران برای تاریخ‌های `jalali_date`.

Two ways to get holidays, and you choose one explicitly:

- **Offline**: `OfflineHolidaySource` calculates the official holidays on the device, with no network and no third party.
  Religious holidays follow the lunar Hijri calendar; their dates come from the predicted first sighting of the new crescent in Iran.
- **Online**: a holiday service such as holidayapi.ir, Calendarific, or Google Calendar, or one of your own.
  It follows announcements and lists every event of the calendar, not only days off.

`FallbackHolidaySource` combines both: online first, offline when the request fails.

## Choosing a source

| Source | Cost and key | Class | Know before using |
| ------ | ------------ | ----- | ----------------- |
| Offline calculation | Free, no network | `OfflineHolidaySource` | The 26 official holidays plus Fridays. Hijri dates are calculated and can be one day off from an announcement made later; such changes never reach it. No other events. |
| [holidayapi.ir](https://holidayapi.ir) | Free, no key | `HolidayApiIrSource` | Community service, no service level agreement or published terms. Data is extracted from time.ir. One request per day. No CORS headers, so it does not work in browsers or Flutter web. Fridays count as holidays. |
| [Calendarific](https://calendarific.com) | Free tier with an API key and a monthly request limit; paid plans above it | `CalendarificSource` | Commercial service with Iran coverage; one request per Gregorian year. Shipping the key inside an app exposes it; use a proxy of your own through `baseUri`. Names are English unless your plan supports `language`. Fridays are added by this package. |
| [Google Calendar API](https://developers.google.com/calendar/api) public holiday calendar | Free quota with a Google Cloud API key | `GoogleCalendarSource` | Reads Google's public Iranian holiday calendar, one request per Jalali month. Needs a Google Cloud project with the Calendar API enabled; restrict the key or use a proxy through `baseUri`. Days off are detected from the event description (`Public holiday` on the English calendar); pass `isHolidayEvent` for the Persian calendar. Fridays are added by this package. |
| Your own table | Free | No, implement `HolidaySource` | Works offline and needs no third party. You update it yourself each year from the official announcement. |

Not usable today: [Nager.Date](https://date.nager.at) is free but has no Iranian data, and [time.ir](https://www.time.ir) is a website without a public API.

Tell your users where holiday data comes from, for example on an about or settings screen; `HolidaySource.name`, `website`, and `notice` hold that text.

## Installation

```sh
dart pub add jalali_holidays
```

## Offline holidays

```dart
import 'package:jalali_date/jalali_date.dart';
import 'package:jalali_holidays/jalali_holidays.dart';

void main() {
  final offline = OfflineHolidaySource();

  final ashura = offline.dayOf(PersianDate(1405, 4, 4));
  print(ashura.isHoliday); // true
  print(ashura.holidays.first.description); // عاشورای حسینی
  print(ashura.holidays.first.additionalDescription); // 10 محرم 1448

  for (final day in offline.holidaysOf(1406)) {
    print('${day.date} ${day.holidays.map((e) => e.description).join(', ')}');
  }

  print(offline.hijriDate(PersianDate(1405, 1, 1))); // 1 شوال 1447
}
```

`dayOf`, `holidaysOf`, and `hijriDate` are synchronous; `day` and `month` implement `HolidaySource` like the online sources.
`holidaysOf` lists the official holidays of a Jalali year without Fridays; `dayOf` and `day` count Fridays unless you pass `fridaysAreHolidays: false`.

### How Hijri holidays are calculated

A Hijri month starts the day after the evening its new crescent is first seen in Iran.
The package computes the new moon and the positions of the Sun and the Moon at sunset (Meeus, Astronomical Algorithms), and checks Yallop's visibility criterion at eight cities across Iran, counting a crescent visible with optical aid (q >= -0.232).
Months where the calendar published by the Iranian calendar authority differs are corrected from a table.
Checked against the published calendar for every month with a holiday from 1387 to 1406, the result matches all of them.
Without the table, the calculation alone matches 174 of these 186 months, and 109 of the 112 from 1395 on.

What the offline mode cannot do:

- A month officially starts when the crescent is actually seen, which is announced only days before.
  A later announcement that moves a holiday is not picked up.
  Pass the announced start yourself, or use an online source:

  ```dart
  final offline = OfflineHolidaySource(
    // 1 Muharram 1448 announced for 1405/03/27.
    hijriMonthStarts: {(1448, 1): PersianDate(1405, 3, 27)},
  );
  ```

- Changes to the holiday law are not picked up either; pass your own `holidays` list (built from `OfficialHoliday.jalali` and `OfficialHoliday.hijri`) if the law changes.
- It lists official days off only, not the many other events of the calendar.

### The official holidays

| Calendar | Date | Holiday |
| -------- | ---- | ------- |
| Jalali | 1 to 4 Farvardin | Nowruz |
| Jalali | 12 Farvardin | Islamic Republic Day |
| Jalali | 13 Farvardin | Sizdah Bedar |
| Jalali | 14 Khordad | Death of Imam Khomeini |
| Jalali | 15 Khordad | 15 Khordad uprising |
| Jalali | 22 Bahman | Victory of the Islamic Revolution |
| Jalali | 29 Esfand | Oil nationalization day |
| Hijri | 9 and 10 Muharram | Tasua and Ashura |
| Hijri | 20 Safar | Arbaeen |
| Hijri | 28 Safar | Death of the Prophet and martyrdom of Imam Hasan |
| Hijri | 29 Safar | Martyrdom of Imam Reza |
| Hijri | 8 Rabi al-Awwal | Martyrdom of Imam Hasan Askari |
| Hijri | 17 Rabi al-Awwal | Birth of the Prophet and Imam Sadiq |
| Hijri | 3 Jumada al-Thani | Martyrdom of Fatima |
| Hijri | 13 Rajab | Birth of Imam Ali |
| Hijri | 27 Rajab | Mab'ath |
| Hijri | 15 Sha'ban | Birth of Imam Mahdi |
| Hijri | 21 Ramadan | Martyrdom of Imam Ali |
| Hijri | 1 and 2 Shawwal | Eid al-Fitr |
| Hijri | 25 Shawwal | Martyrdom of Imam Sadiq |
| Hijri | 10 Dhu al-Hijjah | Eid al-Adha |
| Hijri | 18 Dhu al-Hijjah | Eid al-Ghadir |

The Persian names are in `OfficialHoliday.iran`.
Imam Reza is on 29 Safar even in years where Safar has 30 days, as on the published calendars.
Fridays are holidays as well.

### Example: 1405 and 1406

Output of `OfflineHolidaySource().holidaysOf(year)`, Fridays not listed.
Both years match the calendar published on time.ir day for day.
A Hijri holiday falls twice in one Jalali year when the lunar year (354 or 355 days) fits inside it: Eid al-Fitr in 1405.

#### 1405

| Jalali | Weekday | Gregorian | Holiday | Calendar date |
| ------ | ------- | --------- | ------- | ------------- |
| 1405/01/01 | شنبه | 2026-03-21 | جشن نوروز/جشن سال نو<br>عید سعید فطر | 1 فروردین<br>1 شوال 1447 |
| 1405/01/02 | یکشنبه | 2026-03-22 | عیدنوروز<br>تعطیل به مناسبت عید سعید فطر | 2 فروردین<br>2 شوال 1447 |
| 1405/01/03 | دوشنبه | 2026-03-23 | عیدنوروز | 3 فروردین |
| 1405/01/04 | سه‌شنبه | 2026-03-24 | عیدنوروز | 4 فروردین |
| 1405/01/12 | چهارشنبه | 2026-04-01 | روز جمهوری اسلامی | 12 فروردین |
| 1405/01/13 | پنجشنبه | 2026-04-02 | جشن سیزده به در | 13 فروردین |
| 1405/01/25 | سه‌شنبه | 2026-04-14 | شهادت امام جعفر صادق (ع) | 25 شوال 1447 |
| 1405/03/06 | چهارشنبه | 2026-05-27 | عید سعید قربان | 10 ذوالحجه 1447 |
| 1405/03/14 | پنجشنبه | 2026-06-04 | رحلت حضرت امام خمینی<br>عید سعید غدیر خم | 14 خرداد<br>18 ذوالحجه 1447 |
| 1405/03/15 | جمعه | 2026-06-05 | قیام 15 خرداد | 15 خرداد |
| 1405/04/03 | چهارشنبه | 2026-06-24 | تاسوعای حسینی | 9 محرم 1448 |
| 1405/04/04 | پنجشنبه | 2026-06-25 | عاشورای حسینی | 10 محرم 1448 |
| 1405/05/13 | سه‌شنبه | 2026-08-04 | اربعین حسینی | 20 صفر 1448 |
| 1405/05/21 | چهارشنبه | 2026-08-12 | رحلت رسول اکرم؛شهادت امام حسن مجتبی (ع) | 28 صفر 1448 |
| 1405/05/22 | پنجشنبه | 2026-08-13 | شهادت امام رضا (ع) | 29 صفر 1448 |
| 1405/05/30 | جمعه | 2026-08-21 | شهادت امام حسن عسکری (ع) | 8 ربیع الاول 1448 |
| 1405/06/08 | یکشنبه | 2026-08-30 | میلاد رسول اکرم و امام جعفر صادق (ع) | 17 ربیع الاول 1448 |
| 1405/08/22 | جمعه | 2026-11-13 | شهادت حضرت فاطمه زهرا (س) | 3 جمادی الثانیه 1448 |
| 1405/10/02 | چهارشنبه | 2026-12-23 | ولادت امام علی (ع) و روز پدر | 13 رجب 1448 |
| 1405/10/16 | چهارشنبه | 2027-01-06 | مبعث رسول اکرم (ص) | 27 رجب 1448 |
| 1405/11/04 | یکشنبه | 2027-01-24 | ولادت حضرت قائم عجل الله تعالی فرجه و جشن نیمه شعبان | 15 شعبان 1448 |
| 1405/11/22 | پنجشنبه | 2027-02-11 | پیروزی انقلاب اسلامی | 22 بهمن |
| 1405/12/09 | یکشنبه | 2027-02-28 | شهادت حضرت علی (ع) | 21 رمضان 1448 |
| 1405/12/19 | چهارشنبه | 2027-03-10 | عید سعید فطر | 1 شوال 1448 |
| 1405/12/20 | پنجشنبه | 2027-03-11 | تعطیل به مناسبت عید سعید فطر | 2 شوال 1448 |
| 1405/12/29 | شنبه | 2027-03-20 | روز ملی شدن صنعت نفت ایران | 29 اسفند |

#### 1406

| Jalali | Weekday | Gregorian | Holiday | Calendar date |
| ------ | ------- | --------- | ------- | ------------- |
| 1406/01/01 | یکشنبه | 2027-03-21 | جشن نوروز/جشن سال نو | 1 فروردین |
| 1406/01/02 | دوشنبه | 2027-03-22 | عیدنوروز | 2 فروردین |
| 1406/01/03 | سه‌شنبه | 2027-03-23 | عیدنوروز | 3 فروردین |
| 1406/01/04 | چهارشنبه | 2027-03-24 | عیدنوروز | 4 فروردین |
| 1406/01/12 | پنجشنبه | 2027-04-01 | روز جمهوری اسلامی | 12 فروردین |
| 1406/01/13 | جمعه | 2027-04-02 | جشن سیزده به در | 13 فروردین |
| 1406/01/14 | شنبه | 2027-04-03 | شهادت امام جعفر صادق (ع) | 25 شوال 1448 |
| 1406/02/27 | دوشنبه | 2027-05-17 | عید سعید قربان | 10 ذوالحجه 1448 |
| 1406/03/04 | سه‌شنبه | 2027-05-25 | عید سعید غدیر خم | 18 ذوالحجه 1448 |
| 1406/03/14 | جمعه | 2027-06-04 | رحلت حضرت امام خمینی | 14 خرداد |
| 1406/03/15 | شنبه | 2027-06-05 | قیام 15 خرداد | 15 خرداد |
| 1406/03/25 | سه‌شنبه | 2027-06-15 | تاسوعای حسینی | 9 محرم 1449 |
| 1406/03/26 | چهارشنبه | 2027-06-16 | عاشورای حسینی | 10 محرم 1449 |
| 1406/05/03 | یکشنبه | 2027-07-25 | اربعین حسینی | 20 صفر 1449 |
| 1406/05/11 | دوشنبه | 2027-08-02 | رحلت رسول اکرم؛شهادت امام حسن مجتبی (ع) | 28 صفر 1449 |
| 1406/05/12 | سه‌شنبه | 2027-08-03 | شهادت امام رضا (ع) | 29 صفر 1449 |
| 1406/05/20 | چهارشنبه | 2027-08-11 | شهادت امام حسن عسکری (ع) | 8 ربیع الاول 1449 |
| 1406/05/29 | جمعه | 2027-08-20 | میلاد رسول اکرم و امام جعفر صادق (ع) | 17 ربیع الاول 1449 |
| 1406/08/12 | چهارشنبه | 2027-11-03 | شهادت حضرت فاطمه زهرا (س) | 3 جمادی الثانیه 1449 |
| 1406/09/21 | یکشنبه | 2027-12-12 | ولادت امام علی (ع) و روز پدر | 13 رجب 1449 |
| 1406/10/05 | یکشنبه | 2027-12-26 | مبعث رسول اکرم (ص) | 27 رجب 1449 |
| 1406/10/23 | پنجشنبه | 2028-01-13 | ولادت حضرت قائم عجل الله تعالی فرجه و جشن نیمه شعبان | 15 شعبان 1449 |
| 1406/11/22 | جمعه | 2028-02-11 | پیروزی انقلاب اسلامی | 22 بهمن |
| 1406/11/29 | جمعه | 2028-02-18 | شهادت حضرت علی (ع) | 21 رمضان 1449 |
| 1406/12/08 | یکشنبه | 2028-02-27 | عید سعید فطر | 1 شوال 1449 |
| 1406/12/09 | دوشنبه | 2028-02-28 | تعطیل به مناسبت عید سعید فطر | 2 شوال 1449 |
| 1406/12/29 | یکشنبه | 2028-03-19 | روز ملی شدن صنعت نفت ایران | 29 اسفند |

## Online holidays

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

### Online first, offline as fallback

```dart
final source = FallbackHolidaySource(
  CachedHolidaySource(HolidayApiIrSource()),
  OfflineHolidaySource(),
);
final day = await source.day(PersianDate(1405, 4, 4)); // works without network
```

`FallbackHolidaySource` uses the second source only when the first throws `HolidaySourceException`.

### Caching

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
