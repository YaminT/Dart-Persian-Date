# jalali_date

Persian (Jalali) date for Dart (Web/Flutter/DartVm).
This calendar is using in Iran, Afghanistan and other countries. with this plugin, you can convert Gregorian date to Persian date.

## Usage
````dart
void main(){
    //Create a date object from current time.
    PersianDate date = new PersianDate.now();
    print(date.dateToString());
}
````