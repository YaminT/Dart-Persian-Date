import '../jalali_date.dart';

/// An inclusive range of days from [start] to [end].
///
/// Days are compared without the time of day, like [PersianDate.compareTo].
class PersianDateRange {
  /// First day of the range.
  final PersianDate start;

  /// Last day of the range, included.
  final PersianDate end;

  /// Creates the range from [start] to [end], both included.
  ///
  /// Throws [ArgumentError] when [end] is before [start]. A one-day range
  /// has the same [start] and [end].
  PersianDateRange(this.start, this.end) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(
          '$end', 'end', 'Must not be before start $start');
    }
  }

  /// Number of days in the range, at least 1.
  int get length => end.differenceInDays(start) + 1;

  /// Every day of the range in order, date-only.
  Iterable<PersianDate> get days => start.daysUntil(end);

  /// Whether [date] is on or after [start] and on or before [end].
  bool contains(PersianDate date) =>
      !date.isBefore(start) && !date.isAfter(end);

  /// Whether this range and [other] share at least one day.
  bool overlaps(PersianDateRange other) =>
      !other.end.isBefore(start) && !other.start.isAfter(end);

  /// Equal when [start] and [end] are the same days.
  @override
  bool operator ==(Object other) =>
      other is PersianDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  /// Returns `start - end`, for example `1403/01/01 - 1403/01/10`.
  @override
  String toString() => '$start - $end';
}
