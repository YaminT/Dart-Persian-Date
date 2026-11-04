import 'digits.dart';

/// Writes [pattern] with every token in [tokens] replaced by [value].
///
/// Tokens and quoted text are found as [splitPattern] describes. With
/// [persianDigits], token values are written with Persian digits; literal
/// text is copied unchanged.
String formatPattern(
  String pattern,
  List<String> tokens,
  String Function(String token) value, {
  required bool persianDigits,
}) {
  // Streams instead of calling splitPattern, which allocates every part.
  final out = StringBuffer();
  var i = 0;
  while (i < pattern.length) {
    final c = pattern.codeUnitAt(i);
    if (c == _quote) {
      i = _copyQuoted(pattern, i, out);
      continue;
    }
    final token = _tokenAt(pattern, i, c, tokens);
    if (token == null) {
      out.writeCharCode(c);
      i++;
      continue;
    }
    final text = value(token);
    out.write(persianDigits ? toPersianDigits(text) : text);
    i += token.length;
  }
  return out.toString();
}

const _quote = 0x27;

/// The first of [tokens] at [i] in [pattern], whose code unit there is [c].
String? _tokenAt(String pattern, int i, int c, List<String> tokens) {
  for (final t in tokens) {
    if (t.codeUnitAt(0) == c && pattern.startsWith(t, i)) return t;
  }
  return null;
}

/// Splits [pattern] into tokens from [tokens] and the literal text between
/// them.
///
/// [tokens] must list longer tokens before their prefixes; the first match
/// wins. Text in single quotes is literal, and two single quotes are one
/// quote. An unclosed quote runs to the end of the pattern.
List<({bool token, String text})> splitPattern(
  String pattern,
  List<String> tokens,
) {
  final parts = <({bool token, String text})>[];
  final literal = StringBuffer();
  void flush() {
    if (literal.isEmpty) return;
    parts.add((token: false, text: literal.toString()));
    literal.clear();
  }

  var i = 0;
  while (i < pattern.length) {
    final c = pattern.codeUnitAt(i);
    if (c == _quote) {
      i = _copyQuoted(pattern, i, literal);
      continue;
    }
    final token = _tokenAt(pattern, i, c, tokens);
    if (token == null) {
      literal.writeCharCode(c);
      i++;
      continue;
    }
    flush();
    parts.add((token: true, text: token));
    i += token.length;
  }
  flush();
  return parts;
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
