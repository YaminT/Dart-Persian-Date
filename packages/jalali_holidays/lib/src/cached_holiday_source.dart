import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';
import 'holiday_source.dart';
import 'pool.dart';

/// Remembers the answers of another [HolidaySource] in memory, so each day
/// is requested once.
///
/// Failed requests are not cached. The cache lives as long as this object;
/// persist [HolidayDay] values yourself to keep them across app restarts.
class CachedHolidaySource implements HolidaySource {
  /// The source that answers cache misses.
  final HolidaySource source;

  final _days = <PersianDate, Future<HolidayDay>>{};
  final int _concurrency;

  /// Wraps [source].
  ///
  /// [concurrency] limits how many uncached days [month] requests at once,
  /// so the wrapped service is not flooded.
  CachedHolidaySource(this.source, {int concurrency = 4})
      : _concurrency = concurrency < 1 ? 1 : concurrency;

  @override
  String get name => source.name;

  @override
  Uri get website => source.website;

  @override
  String get notice => source.notice;

  @override
  Future<HolidayDay> day(PersianDate date) {
    final key = PersianDate(date.year, date.month, date.day);
    return _days.putIfAbsent(key, () {
      final future = source.day(key);
      // Drop failures so the next call retries; the caller still gets the
      // error through the returned future.
      future.then<void>((_) {}, onError: (Object _) {
        // Only drop this attempt; clear() may have stored a newer one.
        if (identical(_days[key], future)) _days.remove(key);
      });
      return future;
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

  /// Forgets every cached day.
  void clear() => _days.clear();
}
