// Rough timings for the hot paths, to spot regressions between versions.
//
// Usage: dart run benchmark/jalali_date_benchmark.dart
// Compare runs on the same machine only; the numbers are not portable.
import 'package:jalali_date/jalali_date.dart';

void main() {
  final start = PersianDate(1300, 1, 1);
  final gregorian = DateTime(2024, 3, 20, 14, 30);

  _run('fromDateTime', () => PersianDate.fromDateTime(gregorian));
  _run('PersianDate()', () => PersianDate(1403, 6, 31));
  _run('toDateTime', () => PersianDate(1403, 6, 31).toDateTime());
  _run('addDays(1000)', () => start.addDays(1000));
  _run('addMonths(13)', () => start.addMonths(13));
  _run('weekdayPersian', () => start.weekdayPersian);
  _run('format', () => start.format('EEEE d MMMM yyyy'));
  _run('toString', () => start.toString());
  _run('parse', () => PersianDate.parse('۱۴۰۳/۰۶/۳۱ ۱۴:۳۰'));
  _run('month grid', () {
    final first = start.firstDayOfMonth;
    return first.daysUntil(first.lastDayOfMonth).length;
  });
}

Object? _sink;

void _run(String name, Object? Function() body) {
  // Warm up so the JIT has compiled the path before timing it.
  for (var i = 0; i < 20000; i++) {
    _sink = body();
  }
  const iterations = 200000;
  final watch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    _sink = body();
  }
  watch.stop();
  final nanos = watch.elapsedMicroseconds * 1000 / iterations;
  print('${name.padRight(16)} ${nanos.toStringAsFixed(0).padLeft(6)} ns/op');
  if (_sink == null) print('');
}
