import 'package:jalali_date/jalali_date.dart';

import 'day_builder.dart';
import 'holiday.dart';
import 'holiday_source.dart';

/// One official holiday of Iran, on a fixed Jalali or Hijri date.
class OfficialHoliday {
  /// Name of the holiday in Persian, in religiously neutral wording rather
  /// than the official text: no honorifics or religious titles.
  final String description;

  /// Whether the date is on the lunar Hijri calendar.
  final bool isHijri;

  /// Month, Jalali or Hijri depending on [isHijri].
  final int month;

  /// Day of the month.
  final int day;

  /// A holiday on [day]/[month] of every Jalali year.
  const OfficialHoliday.jalali(this.month, this.day, this.description)
      : isHijri = false;

  /// A holiday on [day]/[month] of every Hijri year.
  const OfficialHoliday.hijri(this.month, this.day, this.description)
      : isHijri = true;

  /// The 26 official holidays of Iran, besides Fridays.
  static const List<OfficialHoliday> iran = [
    OfficialHoliday.jalali(1, 1, 'جشن نوروز'),
    OfficialHoliday.jalali(1, 2, 'تعطیلات نوروز'),
    OfficialHoliday.jalali(1, 3, 'تعطیلات نوروز'),
    OfficialHoliday.jalali(1, 4, 'تعطیلات نوروز'),
    OfficialHoliday.jalali(1, 12, 'سالروز همه‌پرسی ۱۳۵۸'),
    OfficialHoliday.jalali(1, 13, 'سیزده‌به‌در'),
    OfficialHoliday.jalali(3, 14, 'سالروز درگذشت روح‌الله خمینی'),
    OfficialHoliday.jalali(3, 15, 'سالروز رویدادهای ۱۵ خرداد ۱۳۴۲'),
    OfficialHoliday.jalali(11, 22, 'سالروز انقلاب ۱۳۵۷'),
    OfficialHoliday.jalali(12, 29, 'روز ملی شدن صنعت نفت'),
    OfficialHoliday.hijri(1, 9, 'تاسوعا'),
    OfficialHoliday.hijri(1, 10, 'عاشورا'),
    OfficialHoliday.hijri(2, 20, 'اربعین'),
    OfficialHoliday.hijri(
        2, 28, 'سالروز درگذشت پیامبر اسلام و شهادت امام دوم شیعیان'),
    OfficialHoliday.hijri(2, 29, 'سالروز شهادت امام هشتم شیعیان'),
    OfficialHoliday.hijri(3, 8, 'سالروز شهادت امام یازدهم شیعیان'),
    OfficialHoliday.hijri(3, 17, 'زادروز پیامبر اسلام و امام ششم شیعیان'),
    OfficialHoliday.hijri(6, 3, 'سالروز شهادت فاطمه، دختر پیامبر اسلام'),
    OfficialHoliday.hijri(7, 13, 'زادروز امام اول شیعیان و روز پدر'),
    OfficialHoliday.hijri(7, 27, 'عید مبعث'),
    OfficialHoliday.hijri(8, 15, 'نیمه شعبان'),
    OfficialHoliday.hijri(9, 21, 'سالروز شهادت امام اول شیعیان'),
    OfficialHoliday.hijri(10, 1, 'عید فطر'),
    OfficialHoliday.hijri(10, 2, 'تعطیلی عید فطر'),
    OfficialHoliday.hijri(10, 25, 'سالروز شهادت امام ششم شیعیان'),
    OfficialHoliday.hijri(12, 10, 'عید قربان'),
    OfficialHoliday.hijri(12, 18, 'عید غدیر'),
  ];

  @override
  String toString() => '$day/$month ${isHijri ? 'Hijri' : 'Jalali'}: '
      '$description';
}

/// Iran's official holidays computed on the device, with no network.
///
/// Jalali holidays such as Nowruz are fixed. Hijri holidays such as Ashura
/// follow the lunar calendar: their dates are calculated from the predicted
/// first sighting of the new crescent in Iran, and taken from the official
/// record up to Jalali 1405 (see `IranianHijri`). Fridays are
/// holidays when `fridaysAreHolidays` is true.
///
/// Know that:
///
/// - A Hijri month officially starts when the crescent is actually seen,
///   which is announced only days before. A calculated date can be one day
///   off, and changes announced later never reach this source. Pass
///   `hijriMonthStarts` when an announcement differs, or use an online
///   source when that matters.
/// - Only official days off are listed, not the many other events of the
///   calendar.
/// - Changes to the holiday law are not picked up; pass your own
///   `holidays` list if it changes.
class OfflineHolidaySource implements HolidaySource {
  /// The holidays this source knows.
  final List<OfficialHoliday> holidays;

  final bool _fridays;
  final IranianHijri _hijri;
  final _years = <int, Map<PersianDate, List<HolidayEvent>>>{};

  /// Creates the source.
  ///
  /// [holidays] defaults to [OfficialHoliday.iran]. [hijriMonthStarts] maps
  /// a Hijri `(year, month)` to the Jalali day it starts on, for months
  /// where an announcement differs from the calculation.
  OfflineHolidaySource({
    List<OfficialHoliday> holidays = OfficialHoliday.iran,
    bool fridaysAreHolidays = true,
    Map<(int, int), PersianDate> hijriMonthStarts = const {},
  })  : holidays = List.unmodifiable(holidays),
        _fridays = fridaysAreHolidays,
        _hijri = IranianHijri(monthStarts: hijriMonthStarts);

  @override
  String get name => 'Offline calculation';

  @override
  Uri get website => Uri.parse('https://pub.dev/packages/iranian_holidays');

  @override
  String get notice => 'Calculated on the device, no network. Hijri holidays '
      'come from a predicted crescent sighting and can be one day off from '
      'the official announcement; announcements are not picked up.';

  /// The Hijri date of [date] on Iran's official calendar, calculated.
  HijriDate hijriDate(PersianDate date) => _hijri.fromPersianDate(date);

  /// Synchronous [day].
  HolidayDay dayOf(PersianDate date) {
    final key = PersianDate(date.year, date.month, date.day);
    return buildDay(key, _year(key.year)[key] ?? const [], fridays: _fridays);
  }

  /// Every official holiday of Jalali [year] in order, without Fridays.
  List<HolidayDay> holidaysOf(int year) {
    final days = _year(year);
    return [
      for (final date in days.keys.toList()..sort())
        buildDay(date, days[date]!, fridays: false),
    ];
  }

  @override
  Future<HolidayDay> day(PersianDate date) async => dayOf(date);

  @override
  Future<List<HolidayDay>> month(int year, int month) async {
    final first = PersianDate(year, month, 1);
    final last = year == PersianDate.max.year && month == PersianDate.max.month
        ? PersianDate.max
        : first.lastDayOfMonth;
    return [for (final date in first.daysUntil(last)) dayOf(date)];
  }

  Map<PersianDate, List<HolidayEvent>> _year(int year) =>
      _years.putIfAbsent(year, () {
        final first = year == PersianDate.min.year
            ? PersianDate.min
            : PersianDate(year, 1, 1);
        final last = year == PersianDate.max.year
            ? PersianDate.max
            : first.lastDayOfYear;
        final events = <PersianDate, List<HolidayEvent>>{};
        void add(PersianDate date, OfficialHoliday holiday, String when) {
          (events[date] ??= []).add(HolidayEvent(
            description: holiday.description,
            additionalDescription: when,
            isHoliday: true,
            isReligious: holiday.isHijri,
          ));
        }

        final firstHijri = _hijri.fromPersianDate(first);
        final lastHijri = _hijri.fromPersianDate(last);
        // Orders Hijri days without creating them, so days outside the
        // supported range are never built.
        int key(int year, int month, int day) => (year * 12 + month) * 31 + day;
        final firstKey = key(firstHijri.year, firstHijri.month, firstHijri.day);
        final lastKey = key(lastHijri.year, lastHijri.month, lastHijri.day);
        for (final holiday in holidays) {
          if (!holiday.isHijri) {
            if (holiday.month > last.month ||
                (holiday.month == last.month && holiday.day > last.day) ||
                holiday.month < first.month ||
                (holiday.month == first.month && holiday.day < first.day)) {
              continue;
            }
            if (holiday.day <=
                PersianDate(year, holiday.month, 1).monthLength) {
              final date = PersianDate(year, holiday.month, holiday.day);
              add(date, holiday, date.format('d MMMM'));
            }
            continue;
          }
          for (var hy = firstHijri.year; hy <= lastHijri.year; hy++) {
            if (holiday.day > _hijri.monthLength(hy, holiday.month)) continue;
            final k = key(hy, holiday.month, holiday.day);
            if (k < firstKey || k > lastKey) continue;
            final hijri = _hijri.date(hy, holiday.month, holiday.day);
            add(hijri.toPersianDate(), holiday, '$hijri');
          }
        }
        return events;
      });
}
