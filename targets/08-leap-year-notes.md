# 08: Leap years after 1500

Documentation only.

## Findings

- The package's leap years (jalaali-js) match the University of Tehran's table for every year from 1304 to 1498.
- `Intl` in Node 22 (ICU 78) gives the same Jalali date as the package for every day from 1300 to 1500.
- From 1502 (Gregorian 2123) the package disagrees with ICU4J, ICU4X, Python persiantools, and .NET, which use a 33-year rule with corrections taken from an astronomical calendar at 52.5° E.
  Over 1178 to 3177 they disagree on 49 years.
- The 2820-year rule, still found in old code, already gets 1403 and 1404 wrong.

## Change

- A short "Leap years" note in the README under "Supported range": the rule, the years it is checked for, and that other software may differ from 1502, where the official rule is not yet decided.
- A test pinning the leap years 1304 to 1498 to the University of Tehran list, so a future change in the algorithm cannot move them silently.
