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

## Usage in fromJson or fromMap:
````
class Item{
    String text;
    String date;
    
    Item(this.text, this.date);
    
    Item.fromJson(Map<String, dynamic> json){
        text = json['text'];
        if(json['date'] != null)
          date = PersianDate.fromDateTime(DateTime.parse(json['date']).toLocal()).toString(
              showTime: true, second: false);
    }
}
````
