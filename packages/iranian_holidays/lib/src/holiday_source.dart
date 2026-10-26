import 'package:jalali_date/jalali_date.dart';

import 'holiday.dart';

/// A place that knows Iranian holidays, usually a web service.
///
/// There is deliberately no default source. Each source is run by a third
/// party with its own terms, availability, and accuracy, and every request
/// tells that party which dates your app asks about. Read
/// [name], [website], and [notice] before choosing one, and tell your users
/// where holiday data comes from.
abstract interface class HolidaySource {
  /// Human-readable name of the source, for settings screens and logs.
  String get name;

  /// Where the source documents its data and terms.
  Uri get website;

  /// What a developer should know before using the source: who runs it,
  /// where its data comes from, and its limits.
  String get notice;

  /// Holidays and events of [date].
  ///
  /// Throws [HolidaySourceException] when the source cannot answer.
  Future<HolidayDay> day(PersianDate date);

  /// Holidays and events of every day in [month] of [year], in order.
  ///
  /// Throws [HolidaySourceException] when the source cannot answer.
  Future<List<HolidayDay>> month(int year, int month);
}

/// A [HolidaySource] failed: a network error, an unexpected status, or a
/// response it could not read.
class HolidaySourceException implements Exception {
  /// What went wrong.
  final String message;

  /// The request that failed, when there was one.
  final Uri? uri;

  /// The HTTP status code, when the source answered.
  final int? statusCode;

  /// Creates the exception.
  const HolidaySourceException(this.message, {this.uri, this.statusCode});

  @override
  String toString() => [
        'HolidaySourceException: $message',
        if (statusCode != null) 'status $statusCode',
        if (uri != null) '$uri',
      ].join(', ');
}
