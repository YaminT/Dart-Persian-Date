import 'package:jalali_date/jalali_date.dart';

import 'day_builder.dart';
import 'hijri_calendar.dart';
import 'holiday.dart';
import 'holiday_source.dart';

/// One official holiday of Iran, on a fixed Jalali or Hijri date.
class OfficialHoliday {
  /// Text of the holiday, as the official calendar writes it.
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
    OfficialHoliday.jalali(1, 1, 'جشن نوروز/جشن سال نو'),
    OfficialHoliday.jalali(1, 2, 'عیدنوروز'),
    OfficialHoliday.jalali(1, 3, 'عیدنوروز'),
    OfficialHoliday.jalali(1, 4, 'عیدنوروز'),
    OfficialHoliday.jalali(1, 12, 'روز جمهوری اسلامی'),
    OfficialHoliday.jalali(1, 13, 'جشن سیزده به در'),
    OfficialHoliday.jalali(3, 14, 'رحلت حضرت امام خمینی'),
    OfficialHoliday.jalali(3, 15, 'قیام 15 خرداد'),
    OfficialHoliday.jalali(11, 22, 'پیروزی انقلاب اسلامی'),
    OfficialHoliday.jalali(12, 29, 'روز ملی شدن صنعت نفت ایران'),
    OfficialHoliday.hijri(1, 9, 'تاسوعای حسینی'),
    OfficialHoliday.hijri(1, 10, 'عاشورای حسینی'),
    OfficialHoliday.hijri(2, 20, 'اربعین حسینی'),
    OfficialHoliday.hijri(2, 28, 'رحلت رسول اکرم؛شهادت امام حسن مجتبی (ع)'),
    OfficialHoliday.hijri(2, 29, 'شهادت امام رضا (ع)'),
    OfficialHoliday.hijri(3, 8, 'شهادت امام حسن عسکری (ع)'),
    OfficialHoliday.hijri(3, 17, 'میلاد رسول اکرم و امام جعفر صادق (ع)'),
    OfficialHoliday.hijri(6, 3, 'شهادت حضرت فاطمه زهرا (س)'),
    OfficialHoliday.hijri(7, 13, 'ولادت امام علی (ع) و روز پدر'),
    OfficialHoliday.hijri(7, 27, 'مبعث رسول اکرم (ص)'),
    OfficialHoliday.hijri(
        8, 15, 'ولادت حضرت قائم عجل الله تعالی فرجه و جشن نیمه شعبان'),
    OfficialHoliday.hijri(9, 21, 'شهادت حضرت علی (ع)'),
    OfficialHoliday.hijri(10, 1, 'عید سعید فطر'),
    OfficialHoliday.hijri(10, 2, 'تعطیل به مناسبت عید سعید فطر'),
    OfficialHoliday.hijri(10, 25, 'شهادت امام جعفر صادق (ع)'),
    OfficialHoliday.hijri(12, 10, 'عید سعید قربان'),
    OfficialHoliday.hijri(12, 18, 'عید سعید غدیر خم'),
  ];

  @override
  String toString() => '$day/$month ${isHijri ? 'Hijri' : 'Jalali'}: '
      '$description';
}

/// Iran's official holidays computed on the device, with no network.
///
/// Jalali holidays such as Nowruz are fixed. Hijri holidays such as Ashura
/// follow the lunar calendar: their dates are calculated from the predicted
/// first sighting of the new crescent in Iran, and corrected where the
/// published calendar differs (checked from 1387 to 1406). Fridays are
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
        _hijri = IranianHijri({
          for (final MapEntry(key: (year, month), :value)
              in hijriMonthStarts.entries)
            year * 12 + month - 1: _julianDay(value),
        });

  @override
  String get name => 'Offline calculation';

  @override
  Uri get website => Uri.parse('https://pub.dev/packages/jalali_holidays');

  @override
  String get notice => 'Calculated on the device, no network. Hijri holidays '
      'come from a predicted crescent sighting and can be one day off from '
      'the official announcement; announcements are not picked up.';

  /// The Hijri date of [date] on Iran's official calendar, calculated.
  HijriDate hijriDate(PersianDate date) =>
      _hijri.fromJulianDay(_julianDay(date));

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
        final firstJdn = _julianDay(first), lastJdn = _julianDay(last);
        final events = <PersianDate, List<HolidayEvent>>{};
        void add(PersianDate date, OfficialHoliday holiday, String when) {
          (events[date] ??= []).add(HolidayEvent(
            description: holiday.description,
            additionalDescription: when,
            isHoliday: true,
            isReligious: holiday.isHijri,
          ));
        }

        final firstHijri = _hijri.fromJulianDay(_julianDay(first)).year;
        final lastHijri = _hijri.fromJulianDay(_julianDay(last)).year;
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
          for (var hy = firstHijri; hy <= lastHijri; hy++) {
            final start = _hijri.monthStart(hy, holiday.month);
            final next = holiday.month == 12
                ? _hijri.monthStart(hy + 1, 1)
                : _hijri.monthStart(hy, holiday.month + 1);
            if (holiday.day > next - start) continue;
            final jdn = start + holiday.day - 1;
            if (jdn >= firstJdn && jdn <= lastJdn) {
              final date = _fromJulianDay(jdn);
              add(date, holiday,
                  '${HijriDate(hy, holiday.month, holiday.day)}');
            }
          }
        }
        return events;
      });

  // Julian day number of 1400/1/1.
  static final _epoch = PersianDate(1400, 1, 1);
  static const _epochJulianDay = 2459295;

  static int _julianDay(PersianDate date) =>
      date.differenceInDays(_epoch) + _epochJulianDay;

  static PersianDate _fromJulianDay(int jdn) =>
      _epoch.addDays(jdn - _epochJulianDay);
}
