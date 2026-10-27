import '../jalali_date.dart';
import 'jalali_calc.dart';
import 'pattern.dart';

/// Tokens `PersianDate.parseFormat` reads, longest first.
const _tokens = [
  'yyyy', 'yy', 'yw', 'MMMM', 'MM', 'M', 'dd', 'dw', 'd', 'EEEE', 'E', //
  'D', 'Q', 'HH', 'H', 'hh', 'h', 'mm', 'm', 'ss', 's', 'a', 'BBBB', 'B',
];

const _amPm = ['ق.ظ', 'ب.ظ'];

const _dayPeriods = [
  'نیمه‌شب', 'بامداد', 'صبح', 'ظهر', 'بعدازظهر', 'عصر', 'شب', //
];

/// Parses [input] with [pattern] as `PersianDate.parseFormat` describes, or
/// returns null when [input] does not match.
///
/// Throws [ArgumentError] when [pattern] cannot identify a date.
PersianDate? parseWithPattern(String input, String pattern, JalaliEra era) {
  final parts = splitPattern(pattern, _tokens);
  final tokens = {
    for (final part in parts)
      if (part.token) part.text,
  };
  for (final token in const ['yy', 'yw', 'dw']) {
    if (tokens.contains(token)) {
      throw ArgumentError.value(
          pattern, 'pattern', "The token '$token' cannot be parsed");
    }
  }
  if (!tokens.contains('yyyy') ||
      !tokens.any((t) => t.startsWith('M')) ||
      !tokens.any((t) => t.startsWith('d'))) {
    throw ArgumentError.value(
        pattern, 'pattern', 'Must have a year (yyyy), a month, and a day');
  }
  final twelveHour = tokens.contains('h') || tokens.contains('hh');
  if (twelveHour &&
      !tokens.contains('a') &&
      !tokens.contains('B') &&
      !tokens.contains('BBBB')) {
    throw ArgumentError.value(
        pattern, 'pattern', 'h and hh need a or B to tell the half of the day');
  }

  final regex = StringBuffer('^');
  for (final part in parts) {
    regex.write(part.token ? '(${_tokenRegex(part.text)})' : _literal(part));
  }
  regex.write(r'$');
  final match = RegExp(regex.toString(), caseSensitive: false)
      .firstMatch(_normalize(input));
  if (match == null) return null;

  // Every value read, by field; a field read twice must agree.
  final fields = <String, int>{};
  var group = 0;
  for (final part in parts) {
    if (!part.token) continue;
    final text = match[++group]!;
    final (field, value) = _read(part.text, text);
    if (value == null) return null;
    if (fields[field] case final previous? when previous != value) return null;
    fields[field] = value;
  }

  final year = fields['year']! - era.offset;
  final month = fields['month']!, day = fields['day']!;
  if (year < -61 || year > 3177 || month < 1 || month > 12 || day < 1) {
    return null;
  }
  if (day > jalaliMonthLength(year, month)) return null;

  final hour = _hour(fields);
  if (hour == -1) return null;
  final minute = fields['minute'] ?? 0, second = fields['second'] ?? 0;
  if (minute > 59 || second > 59) return null;

  final PersianDate date;
  try {
    date = hour == null
        ? PersianDate(year, month, day)
        : PersianDate.withTime(year, month, day, hour, minute, second);
  } on ArgumentError {
    return null;
  }
  if (fields['weekday'] case final weekday? when weekday != date.weekday) {
    return null;
  }
  if (fields['dayOfYear'] case final d? when d != date.dayOfYear) return null;
  if (fields['quarter'] case final q? when q != date.quarter) return null;
  return date;
}

/// The hour of the day from [fields], null when no hour was read, or -1
/// when the values do not fit together.
int? _hour(Map<String, int> fields) {
  final hour24 = fields['hour24'];
  final hour12 = fields['hour12'];
  final half = fields['half'];
  final period = fields['period'];
  if (hour24 == null && hour12 == null) return null;
  final candidates = hour24 != null
      ? [hour24]
      : [
          if (hour12! >= 1 && hour12 <= 12) ...[hour12 % 12, hour12 % 12 + 12]
        ];
  final fitting = [
    for (final h in candidates)
      if (h <= 23 &&
          (hour12 == null || h % 12 == hour12 % 12) &&
          (half == null || (h < 12 ? 0 : 1) == half) &&
          (period == null || _periodsOf(h).contains(period)))
        h,
  ];
  return fitting.length == 1 ? fitting.single : -1;
}

/// Indexes in [_dayPeriods] that `B` and `BBBB` write for [hour].
Set<int> _periodsOf(int hour) => switch (hour) {
      0 => {0},
      < 4 => {1},
      < 12 => {2},
      12 => {3, 4},
      < 19 => {5},
      _ => {6},
    };

/// The field [token] sets and its value from the matched [text], or a null
/// value when [text] names nothing.
(String, int?) _read(String token, String text) => switch (token) {
      'yyyy' => ('year', int.parse(text)),
      'MMMM' => ('month', _nameIndex(text, _monthNames)),
      'MM' || 'M' => ('month', int.parse(text)),
      'dd' || 'd' => ('day', int.parse(text)),
      'EEEE' => ('weekday', _nameIndex(text, _weekdayNames)),
      'E' => ('weekday', _nameIndex(text, [PersianDate.weekdayNamesShort])),
      'D' => ('dayOfYear', int.parse(text)),
      'Q' => ('quarter', int.parse(text)),
      'HH' || 'H' => ('hour24', int.parse(text)),
      'hh' || 'h' => ('hour12', int.parse(text)),
      'mm' || 'm' => ('minute', int.parse(text)),
      'ss' || 's' => ('second', int.parse(text)),
      'a' => ('half', _nameIndex(_withoutDot(text), [_amPm], first: 0)),
      _ => ('period', _nameIndex(text, [_dayPeriods], first: 0)),
    };

const _monthNames = [
  PersianDate.monthNames,
  PersianDate.monthNamesLatin,
  PersianDate.monthNamesDari,
];

const _weekdayNames = [
  PersianDate.weekdayNames,
  PersianDate.weekdayNamesLatin,
];

/// [text] without a final dot, as CLDR writes `ق.ظ.`.
String _withoutDot(String text) =>
    text.endsWith('.') ? text.substring(0, text.length - 1) : text;

/// Position of [text] in one of [lists], counting from [first], or null.
int? _nameIndex(String text, List<List<String>> lists, {int first = 1}) {
  final key = _nameKey(text);
  for (final names in lists) {
    for (var i = 0; i < names.length; i++) {
      if (_nameKey(names[i]) == key) return i + first;
    }
  }
  return null;
}

/// [name] without spaces and in lower case, for comparing names.
String _nameKey(String name) =>
    _normalize(name).replaceAll(' ', '').toLowerCase();

String _tokenRegex(String token) => switch (token) {
      'yyyy' => r'-?\d{1,4}',
      'MM' || 'dd' || 'HH' || 'hh' || 'mm' || 'ss' => r'\d{2}',
      'M' || 'd' || 'H' || 'h' || 'm' || 's' => r'\d{1,2}',
      'D' => r'\d{1,3}',
      'Q' => '[1-4]',
      'MMMM' => _namesRegex(_monthNames.expand((names) => names)),
      'EEEE' => _namesRegex(_weekdayNames.expand((names) => names)),
      'E' => _namesRegex(PersianDate.weekdayNamesShort),
      'a' => '${_namesRegex(_amPm)}\\.?',
      _ => _namesRegex(_dayPeriods),
    };

/// Alternatives for [names], longest first, each allowing a space or none
/// between its letters, so `سه‌شنبه`, `سه شنبه`, and `سهشنبه` all match.
String _namesRegex(Iterable<String> names) {
  final keys = {for (final name in names) _nameKey(name)}.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final alternatives =
      keys.map((key) => key.split('').map(RegExp.escape).join(' ?'));
  return '(?:${alternatives.join('|')})';
}

/// Literal text of the pattern; spaces in it and around it match any run of
/// spaces, or none.
String _literal(({bool token, String text}) part) {
  final words = _normalize(part.text).split(' ').where((w) => w.isNotEmpty);
  return [r'\s*', ...words.map((w) => '${RegExp.escape(w)}\\s*')].join();
}

/// [text] with Latin digits, Persian letters for their Arabic forms,
/// zero-width non-joiners as spaces, no tatweel, and single spaces.
String _normalize(String text) => toLatinDigits(text)
    .replaceAll('\u064a', '\u06cc') // Arabic yeh
    .replaceAll('\u0649', '\u06cc') // alef maksura
    .replaceAll('\u0643', '\u06a9') // Arabic kaf
    .replaceAll('\u0629', '\u0647') // teh marbuta
    .replaceAll('\u0640', '') // tatweel
    .replaceAll('\u200c', ' ') // zero-width non-joiner
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
