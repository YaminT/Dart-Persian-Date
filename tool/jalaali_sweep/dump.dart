// Prints every day from Gregorian 1850-01-01 to 2300-12-31 as
// "gy gm gd jy jm jd", converted with this package, for sweep.mjs to
// compare against jalaali-js.
//
// Usage: dart run tool/jalaali_sweep/dump.dart | node tool/jalaali_sweep/sweep.mjs
import 'dart:io';

import 'package:jalali_date/src/jalali_calc.dart';

void main() {
  final out = StringBuffer();
  final last = g2d(2300, 12, 31);
  for (var jdn = g2d(1850, 1, 1); jdn <= last; jdn++) {
    final g = d2g(jdn);
    final j = d2j(jdn);
    out.writeln('${g.gy} ${g.gm} ${g.gd} ${j.jy} ${j.jm} ${j.jd}');
  }
  stdout.write(out);
}
