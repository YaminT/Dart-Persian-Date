const _latinZero = 0x30;
const _persianZero = 0x06F0;
const _arabicIndicZero = 0x0660;

/// Replaces the ASCII digits 0 to 9 in [input] with Persian digits ۰ to ۹.
///
/// Every other character is kept, so `toPersianDigits('1403/01/01')` is
/// `۱۴۰۳/۰۱/۰۱`.
String toPersianDigits(String input) {
  List<int>? units;
  for (var i = 0; i < input.length; i++) {
    final c = input.codeUnitAt(i);
    if (c >= _latinZero && c <= _latinZero + 9) {
      (units ??= input.codeUnits.toList())[i] = c - _latinZero + _persianZero;
    }
  }
  return units == null ? input : String.fromCharCodes(units);
}

/// Replaces Persian (۰ to ۹) and Arabic-Indic (٠ to ٩) digits in [input]
/// with the ASCII digits 0 to 9.
///
/// Every other character is kept. Use it on user input before parsing.
String toLatinDigits(String input) {
  List<int>? units;
  for (var i = 0; i < input.length; i++) {
    final c = input.codeUnitAt(i);
    final zero = c >= _persianZero && c <= _persianZero + 9
        ? _persianZero
        : c >= _arabicIndicZero && c <= _arabicIndicZero + 9
            ? _arabicIndicZero
            : null;
    if (zero != null) {
      (units ??= input.codeUnits.toList())[i] = c - zero + _latinZero;
    }
  }
  return units == null ? input : String.fromCharCodes(units);
}
