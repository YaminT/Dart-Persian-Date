const _latinZero = 0x30;
const _persianZero = 0x06F0;
const _arabicIndicZero = 0x0660;

/// Replaces the ASCII digits 0 to 9 in [input] with Persian digits ۰ to ۹.
///
/// Every other character is kept, so `toPersianDigits('1403/01/01')` is
/// `۱۴۰۳/۰۱/۰۱`.
String toPersianDigits(String input) => String.fromCharCodes(
      input.codeUnits.map(
        (c) => c >= _latinZero && c <= _latinZero + 9
            ? c - _latinZero + _persianZero
            : c,
      ),
    );

/// Replaces Persian (۰ to ۹) and Arabic-Indic (٠ to ٩) digits in [input]
/// with the ASCII digits 0 to 9.
///
/// Every other character is kept. Use it on user input before parsing.
String toLatinDigits(String input) => String.fromCharCodes(
      input.codeUnits.map((c) {
        if (c >= _persianZero && c <= _persianZero + 9) {
          return c - _persianZero + _latinZero;
        }
        if (c >= _arabicIndicZero && c <= _arabicIndicZero + 9) {
          return c - _arabicIndicZero + _latinZero;
        }
        return c;
      }),
    );
