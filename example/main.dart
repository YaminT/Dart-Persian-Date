import 'package:jalali_date/jalali_date.dart';

main(List<String> arguments) async {
  print(PersianDate.fromDateTime(DateTime.parse('2012-02-27 13:27:00.123456z'))
      .toString(showTime: true));
  print(PersianDate.now().toString(showTime: false));
}
