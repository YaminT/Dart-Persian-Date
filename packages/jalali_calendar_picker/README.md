# jalali_calendar_picker

[![pub package](https://img.shields.io/pub/v/jalali_calendar_picker.svg)](https://pub.dev/packages/jalali_calendar_picker)

Persian (Jalali, Shamsi) date picker and range picker for Flutter, built on [jalali_date](https://pub.dev/packages/jalali_date).
انتخابگر تاریخ و بازه‌ی تاریخ شمسی برای Flutter.

- Material 3, follows your app's `ColorScheme`.
- Saturday-first weeks, Fridays marked as the weekend.
- Persian digits by default, Latin digits on request.
- Right-to-left layout by default, even inside a left-to-right app.
- Day, month, and year views for quick jumps.
- Limits with `firstDate`, `lastDate`, and `selectableDayPredicate`.
- Persian labels; the dialog texts can be changed with `helpText`, `confirmText`, and `cancelText`.

## Installation

`jalali_calendar_picker` is published on [pub.dev](https://pub.dev/packages/jalali_calendar_picker):

```sh
flutter pub add jalali_calendar_picker
```

`jalali_calendar_picker` re-exports `jalali_date`, so one import is enough:

```dart
import 'package:jalali_calendar_picker/jalali_calendar_picker.dart';
```

## Dialogs

```dart
final date = await showPersianDatePicker(
  context: context,
  initialDate: PersianDate.now(),
  firstDate: PersianDate(1400, 1, 1),
  lastDate: PersianDate(1410, 12, 29),
);
if (date != null) print(date.format('EEEE d MMMM yyyy')); // یکشنبه 1 مهر 1403

final range = await showPersianDateRangePicker(context: context);
if (range != null) print('${range.length} days');
```

Both return null when the dialog is cancelled or dismissed.
The range dialog returns a one-day range when only a start was picked.

| Parameter | Default |
| --------- | ------- |
| `initialDate` / `initialRange` | today, clamped to the limits / none |
| `firstDate`, `lastDate` | `PersianDate.min`, `PersianDate.max` |
| `selectableDayPredicate` | every day |
| `persianDigits` | `true` |
| `helpText` | `انتخاب تاریخ` / `انتخاب بازه` |
| `confirmText`, `cancelText` | `تأیید`, `لغو` |
| `textDirection` | `TextDirection.rtl` |

## Inline calendars

```dart
PersianCalendarDatePicker(
  selectedDate: selected,
  onDateChanged: (date) => setState(() => selected = date),
  selectableDayPredicate: (day) => !day.isWeekend,
)

PersianCalendarRangePicker(
  onRangeChanged: (range) => setState(() => this.range = range),
)
```

For other selection rules, such as several separate days, use `PersianCalendar` directly with your own `isSelected`, `isInRange`, and `onDayTapped`.

## Holidays

[iranian_holidays](https://pub.dev/packages/iranian_holidays) gives Iran's official holidays, calculated offline on the device or fetched from an online source.
The offline source answers synchronously, so it fits `selectableDayPredicate` directly:

```dart
final holidays = OfflineHolidaySource();

PersianCalendarDatePicker(
  selectedDate: selected,
  onDateChanged: (date) => setState(() => selected = date),
  selectableDayPredicate: holidays.isWorkingDay, // no Fridays or holidays
)
```

With an online source, load a month with `HolidaySource.month` first, then pass a predicate over the result, or mark the days in your own `PersianCalendar` cells.

## License

Apache-2.0.
See [LICENSE](LICENSE).
