const _ones = [
  '', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه', //
  'ده', 'یازده', 'دوازده', 'سیزده', 'چهارده', 'پانزده', 'شانزده', 'هفده',
  'هجده', 'نوزده',
];
const _tens = [
  '', '', 'بیست', 'سی', 'چهل', 'پنجاه', 'شصت', 'هفتاد', 'هشتاد', 'نود', //
];
const _hundreds = [
  '', 'صد', 'دویست', 'سیصد', 'چهارصد', 'پانصد', 'ششصد', 'هفتصد', 'هشتصد', //
  'نهصد',
];
const _scales = [
  '', 'هزار', 'میلیون', 'میلیارد', 'تریلیون', 'کوادریلیون', 'کوینتیلیون', //
];

/// [number] written in Persian words, for example `هزار و چهارصد و سه` for
/// 1403, or as an ordinal with [ordinal]: `بیست و چهارم` for 24.
///
/// Parts are joined with ` و `. A leading thousand is `هزار`, not
/// `یک هزار`, as years are written; larger scales keep `یک`
/// (`یک میلیون`). Ordinals are the forms dates use: `یکم`, `سوم`, and
/// `سی‌ام` with a zero-width non-joiner. Negative numbers start with `منفی`.
String toPersianWords(int number, {bool ordinal = false}) {
  final words = _cardinal(number);
  return ordinal ? _ordinal(words) : words;
}

String _cardinal(int number) {
  if (number == 0) return 'صفر';
  // Groups of three digits from the lowest; remainder and ~/ keep the sign,
  // so the smallest int never overflows.
  final groups = <int>[];
  for (var rest = number; rest != 0; rest ~/= 1000) {
    groups.add(rest.remainder(1000).abs());
  }
  final parts = <String>[];
  for (var scale = groups.length - 1; scale >= 0; scale--) {
    final group = groups[scale];
    if (group == 0) continue;
    if (scale == 0) {
      parts.add(_belowThousand(group));
    } else if (group == 1 && scale == 1 && parts.isEmpty) {
      parts.add(_scales[1]);
    } else {
      parts.add('${_belowThousand(group)} ${_scales[scale]}');
    }
  }
  final words = parts.join(' و ');
  return number < 0 ? 'منفی $words' : words;
}

String _belowThousand(int number) {
  final parts = [
    if (number >= 100) _hundreds[number ~/ 100],
    if (number % 100 >= 20) ...[
      _tens[number % 100 ~/ 10],
      if (number % 10 != 0) _ones[number % 10],
    ] else if (number % 100 != 0)
      _ones[number % 100],
  ];
  return parts.join(' و ');
}

String _ordinal(String words) {
  if (words.endsWith('سه')) {
    return '${words.substring(0, words.length - 2)}سوم';
  }
  if (words.endsWith('ی')) return '$words\u200cام';
  return '$wordsم';
}
