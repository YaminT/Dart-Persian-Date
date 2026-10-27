# 07: Moment of Nowruz

## Why

Every Iranian calendar announces the moment of the March equinox, سال تحویل, and apps show a countdown to it.
DNTPersianUtils.Core has `EquinoxCalculator`, and persian-calendar has an `equinox` library claimed accurate to under a second for 1800 to 2200.
The package already has solar position code for the Hijri calculation, but it is too coarse for this (minutes of error).

## API

```dart
PersianDate.nowruzMoment(1405); // DateTime.utc(2026, 3, 20, 14, 46, ...)
PersianDate(1405, 1, 1).nowruzMoment; // same, for the year of a date
```

- Returns a UTC `DateTime`; Iran time is `toUtc().add(Duration(hours: 3, minutes: 30))` for the years Iran kept no daylight time, which the doc comment explains.
- Uses Meeus chapter 27 (mean equinox plus the 24 periodic terms) with the existing Delta T, or a better published method if it is needed to meet the bar below.

## Done when

- Within one minute of every moment the University of Tehran announced for 1360 to 1405, using [persian-calendar/equinox-research `iran-ground-truth.json`](https://github.com/persian-calendar/equinox-research/blob/main/iran-ground-truth.json) as a checked-in fixture (check its license first; if it cannot be copied, transcribe the moments from the University of Tehran PDFs).
- The doc comment states the accuracy and the years it was checked for.
- README section.
