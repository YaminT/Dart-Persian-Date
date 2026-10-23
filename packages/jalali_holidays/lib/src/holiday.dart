import 'package:jalali_date/jalali_date.dart';

/// One event on a day, such as a holiday or an anniversary.
class HolidayEvent {
  /// Text of the event as the source gives it, usually in Persian.
  final String description;

  /// Extra text from the source, for example the matching Hijri or
  /// Gregorian date. Empty when the source has none.
  final String additionalDescription;

  /// Whether this event makes the day an official holiday.
  final bool isHoliday;

  /// Whether this is a religious event, usually on the lunar Hijri calendar.
  final bool isReligious;

  /// Creates an event.
  const HolidayEvent({
    required this.description,
    this.additionalDescription = '',
    required this.isHoliday,
    this.isReligious = false,
  });

  @override
  String toString() => isHoliday ? '$description (holiday)' : description;
}

/// What a [HolidaySource] knows about one day.
class HolidayDay {
  /// The day, date-only.
  final PersianDate date;

  /// Whether the day is an official holiday, including Fridays when the
  /// source counts them.
  final bool isHoliday;

  /// Every event the source lists for the day, holidays first.
  final List<HolidayEvent> events;

  /// Creates a day.
  HolidayDay({
    required this.date,
    required this.isHoliday,
    required List<HolidayEvent> events,
  }) : events = List.unmodifiable(events);

  /// Only the events that make the day a holiday.
  Iterable<HolidayEvent> get holidays => events.where((e) => e.isHoliday);

  @override
  String toString() => '$date${isHoliday ? ' holiday' : ''}: $events';
}
