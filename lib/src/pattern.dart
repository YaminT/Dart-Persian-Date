import 'digits.dart';

/// Writes [pattern] with every token in [tokens] replaced by [value].
///
/// [tokens] must list longer tokens before their prefixes; the first match
/// wins. Text in single quotes is copied without looking for tokens, and two
/// single quotes write one. With [persianDigits], token values are written
/// with Persian digits; literal text is copied unchanged.
String formatPattern(
  String pattern,
  List<String> tokens,
  String Function(String token) value, {
  required bool persianDigits,
}) {
  final out = StringBuffer();
  var i = 0;
  while (i < pattern.length) {
    if (pattern[i] == "'") {
      i = _copyQuoted(pattern, i, out);
      continue;
    }
    final token = tokens.firstWhere(
      (t) => pattern.startsWith(t, i),
      orElse: () => '',
    );
    if (token.isEmpty) {
      out.write(pattern[i]);
      i++;
      continue;
    }
    final text = value(token);
    out.write(persianDigits ? toPersianDigits(text) : text);
    i += token.length;
  }
  return out.toString();
}

/// Copies the quoted section starting at [start] and returns the index after
/// it.
int _copyQuoted(String pattern, int start, StringBuffer out) {
  if (pattern.startsWith("''", start)) {
    out.write("'");
    return start + 2;
  }
  var i = start + 1;
  while (i < pattern.length) {
    if (pattern[i] == "'") {
      if (!pattern.startsWith("''", i)) return i + 1;
      out.write("'");
      i += 2;
      continue;
    }
    out.write(pattern[i]);
    i++;
  }
  return i;
}

/// [year] with at least four digits, keeping a minus sign.
String fourDigitYear(int year) {
  final digits = year.abs().toString().padLeft(4, '0');
  return year < 0 ? '-$digits' : digits;
}

/// [value] padded to two digits.
String twoDigits(int value) => value.toString().padLeft(2, '0');
