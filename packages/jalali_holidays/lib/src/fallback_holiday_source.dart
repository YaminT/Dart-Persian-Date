import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';
import 'holiday_source.dart';

/// Asks [primary] and answers from [fallback] when [primary] fails.
///
/// Typical use: an online source first, so announced changes are picked
/// up, and an `OfflineHolidaySource` when there is no network.
///
/// ```dart
/// final source = FallbackHolidaySource(
///   CachedHolidaySource(HolidayApiIrSource()),
///   OfflineHolidaySource(),
/// );
/// ```
class FallbackHolidaySource implements HolidaySource {
  /// The source asked first.
  final HolidaySource primary;

  /// The source asked when [primary] throws a [HolidaySourceException].
  final HolidaySource fallback;

  /// Creates the source.
  FallbackHolidaySource(this.primary, this.fallback);

  @override
  String get name => '${primary.name}, else ${fallback.name}';

  @override
  Uri get website => primary.website;

  @override
  String get notice => '${primary.notice}\n${fallback.notice}';

  @override
  Future<HolidayDay> day(PersianDate date) async {
    try {
      return await primary.day(date);
    } on HolidaySourceException {
      return fallback.day(date);
    }
  }

  @override
  Future<List<HolidayDay>> month(int year, int month) async {
    try {
      return await primary.month(year, month);
    } on HolidaySourceException {
      return fallback.month(year, month);
    }
  }
}
