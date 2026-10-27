/// Units of relative time, with the Persian words from CLDR 49 (`fa`): the
/// names for small offsets such as `دیروز`, and the past and future
/// patterns.
enum RelativeUnit {
  second({0: 'اکنون'}, 'ثانیه پیش', 'ثانیه بعد'),
  minute({0: 'همین دقیقه'}, 'دقیقه پیش', 'دقیقه بعد'),
  hour({0: 'همین ساعت'}, 'ساعت پیش', 'ساعت بعد'),
  day(
    {-2: 'پریروز', -1: 'دیروز', 0: 'امروز', 1: 'فردا', 2: 'پس‌فردا'},
    'روز پیش',
    'روز دیگر',
  ),
  week({-1: 'هفتهٔ گذشته', 0: 'این هفته', 1: 'هفتهٔ آینده'}, 'هفته پیش',
      'هفته بعد'),
  month({-1: 'ماه گذشته', 0: 'این ماه', 1: 'ماه آینده'}, 'ماه پیش', 'ماه بعد'),
  year({-1: 'سال گذشته', 0: 'امسال', 1: 'سال آینده'}, 'سال پیش', 'سال بعد');

  const RelativeUnit(this.names, this.past, this.future);

  final Map<int, String> names;
  final String past;
  final String future;

  /// [value] units from now, like `Intl.RelativeTimeFormat('fa')`: a name
  /// when there is one and [numeric] is false, otherwise the number with
  /// [past] or [future]. Zero counts as future.
  String format(int value, {required bool numeric}) {
    final name = numeric ? null : names[value];
    if (name != null) return name;
    return value < 0 ? '${-value} $past' : '$value $future';
  }
}
