# jalali_date_picker

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

```sh
flutter pub add jalali_date_picker
```

`jalali_date_picker` re-exports `jalali_date`, so one import is enough:

```dart
import 'package:jalali_date_picker/jalali_date_picker.dart';
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

Iranian holidays need a data source; see [jalali_holidays](https://github.com/YaminT/Dart-Persian-Date/tree/master/packages/jalali_holidays).
Load a month with `HolidaySource.month` and pass a `selectableDayPredicate`, or mark the days in your own `PersianCalendar` cells.

## License

Apache-2.0.
See [LICENSE](LICENSE).
