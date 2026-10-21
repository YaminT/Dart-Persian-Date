# jalali_date

Persian (Jalali) date for Dart (Web/Flutter/DartVm).
This calendar is using in Iran, Afghanistan and other countries. with this plugin, you can convert Gregorian date to Persian date.

## Usage
````dart
import 'package:jalali_date/jalali_date.dart';

void main() {
  // Create a date object from the current time.
  final date = PersianDate.now();
  print(date.toString()); // 1405/7/29
  print(date.toString(showTime: true)); // 1405/7/29 14:05:09
  print(date.toString(showTime: true, showSecond: false)); // 1405/7/29 14:05
  print(date.toString(showDate: false, showTime: true)); // 14:05:09
}
````

`toString` takes `showDate`, `showTime`, `showHour`, `showMinute`, and `showSecond` flags.
Hour, minute, and second are always zero-padded to two digits.

## Usage in fromJson
````dart
import 'package:jalali_date/jalali_date.dart';

class Item {
  final String text;
  final String? date;

  Item(this.text, this.date);

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String?;
    return Item(
      json['text'] as String,
      rawDate == null
          ? null
          : PersianDate.fromDateTime(DateTime.parse(rawDate).toLocal())
              .toString(showTime: true, showSecond: false),
    );
  }
}
````
