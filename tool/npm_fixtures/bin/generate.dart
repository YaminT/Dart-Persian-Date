// Writes the data packages/iranian_calendar_js/test checks against, so the
// npm package gives the same days as the Dart packages.
//
// Run from the repository root:
//
//   dart run tool/npm_fixtures/bin/generate.dart
import 'dart:convert';
import 'dart:io';

import 'package:iranian_holidays/iranian_holidays.dart';
import 'package:jalali_date/jalali_date.dart';

const _dir = 'packages/iranian_calendar_js/test/data';

void main() {
  // Every Hijri month start from 1200 to 1600: the official record from 1265
  // and the crescent prediction on both sides of it.
  final starts = [
    for (var year = 1200; year <= 1600; year++)
      for (var month = 1; month <= 12; month++)
        _iso(IranianHijri.official.monthStart(year, month).toDateTime()),
  ];
  File('$_dir/month_starts.json').writeAsStringSync(
      '${jsonEncode({'firstYear': 1200, 'starts': starts})}\n');

  final offline = OfflineHolidaySource();
  final holidays = {
    for (var year = 1395; year <= 1410; year++)
      '$year': [
        for (final day in offline.holidaysOf(year))
          [
            _iso(day.date.toDateTime()),
            for (final event in day.holidays) event.description,
          ],
      ],
  };
  File('$_dir/holidays.json').writeAsStringSync('${jsonEncode(holidays)}\n');
  stdout.writeln('Wrote $_dir/month_starts.json and $_dir/holidays.json');
}

String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
