/// How Jalali years are numbered in text.
///
/// `PersianDate.year` is always Solar Hijri. The era only changes the year
/// that `format` and `toString` write and that `parse` and `tryParse` read.
enum JalaliEra {
  /// Solar Hijri (هجری شمسی), the official numbering in Iran: 1405.
  solarHijri(0),

  /// Shahanshahi (شاهنشاهی, Imperial): Solar Hijri plus 1180, so 1405 is
  /// 2585.
  shahanshahi(1180);

  const JalaliEra(this.offset);

  /// Years added to a Solar Hijri year to number it in this era: 0 or 1180.
  final int offset;
}
