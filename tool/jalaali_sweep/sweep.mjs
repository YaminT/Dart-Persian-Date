// Reads "gy gm gd jy jm jd" lines from dump.dart on stdin and checks each
// against jalaali-js in both directions. Exits 1 on the first mismatches.
import { createInterface } from 'node:readline';
import jalaali from 'jalaali-js';

const lines = createInterface({ input: process.stdin });
let count = 0;
let failures = 0;

for await (const line of lines) {
  if (!line) continue;
  const [gy, gm, gd, jy, jm, jd] = line.split(' ').map(Number);
  const j = jalaali.toJalaali(gy, gm, gd);
  const g = jalaali.toGregorian(jy, jm, jd);
  if (j.jy !== jy || j.jm !== jm || j.jd !== jd ||
      g.gy !== gy || g.gm !== gm || g.gd !== gd) {
    failures++;
    if (failures <= 20) {
      console.error(`mismatch: ${line} jalaali-js ${JSON.stringify(j)} ${JSON.stringify(g)}`);
    }
  }
  count++;
}

if (count === 0) {
  console.error('no input; pipe dump.dart into this script');
  process.exit(1);
}
console.log(`${count} days compared, ${failures} mismatches`);
process.exit(failures === 0 ? 0 : 1);
