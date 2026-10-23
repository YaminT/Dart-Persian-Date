import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';

/// The Friday event added by sources that do not report Fridays themselves.
const fridayEvent = HolidayEvent(description: 'جمعه', isHoliday: true);

/// Builds the [HolidayDay] for [date] from [events], holidays first.
///
/// With [fridays], a Friday gets [fridayEvent] and counts as a holiday.
HolidayDay buildDay(
  PersianDate date,
  Iterable<HolidayEvent> events, {
  required bool fridays,
}) {
  final all = [
    if (fridays && date.isWeekend) fridayEvent,
    ...events,
  ]..sort((a, b) => (b.isHoliday ? 1 : 0) - (a.isHoliday ? 1 : 0));
  return HolidayDay(
    date: PersianDate(date.year, date.month, date.day),
    isHoliday: all.any((e) => e.isHoliday),
    events: all,
  );
}

/// `yyyy-MM-dd` of the Gregorian day of [date].
String gregorianIso(PersianDate date) {
  final g = date.toDateTime();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${g.year.toString().padLeft(4, '0')}-${two(g.month)}-${two(g.day)}';
}

/// Every day of Jalali [month] in [year].
List<PersianDate> daysOfMonth(int year, int month) {
  final first = PersianDate(year, month, 1);
  return first.daysUntil(first.lastDayOfMonth).toList();
}

/// Caches futures by key and forgets failed ones so they are retried.
class FutureCache<K, V> {
  final _entries = <K, Future<V>>{};

  /// Returns the cached future for [key], or stores the one from [load].
  Future<V> get(K key, Future<V> Function() load) =>
      _entries.putIfAbsent(key, () {
        final future = load();
        future.then<void>((_) {}, onError: (Object _) {
          if (identical(_entries[key], future)) _entries.remove(key);
        });
        return future;
      });

  /// Forgets every entry.
  void clear() => _entries.clear();
}
