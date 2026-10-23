import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';
import 'holiday_source.dart';

/// Remembers the answers of another [HolidaySource] in memory, so each day
/// is requested once.
///
/// Failed requests are not cached. The cache lives as long as this object;
/// persist [HolidayDay] values yourself to keep them across app restarts.
class CachedHolidaySource implements HolidaySource {
  /// The source that answers cache misses.
  final HolidaySource source;

  final _days = <PersianDate, Future<HolidayDay>>{};

  /// Wraps [source].
  CachedHolidaySource(this.source);

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
        _days.remove(key);
      });
      return future;
    });
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) {
    final first = PersianDate(year, month, 1);
    return Future.wait([
      for (final date in first.daysUntil(first.lastDayOfMonth)) day(date),
    ]);
  }

  /// Forgets every cached day.
  void clear() => _days.clear();
}
