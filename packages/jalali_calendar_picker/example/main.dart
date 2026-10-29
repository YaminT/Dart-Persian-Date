import 'package:flutter/material.dart';
import 'package:jalali_calendar_picker/jalali_calendar_picker.dart';

void main() => runApp(const MaterialApp(home: ExamplePage()));

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  PersianDate? _date;
  PersianDateRange? _range;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('jalali_calendar_picker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () async {
              final date = await showPersianDatePicker(context: context);
              if (date != null) setState(() => _date = date);
            },
            child: const Text('انتخاب تاریخ'),
          ),
          Text(_date?.format('EEEE d MMMM yyyy', persianDigits: true) ?? '-'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final range = await showPersianDateRangePicker(
                context: context,
                firstDate: PersianDate.now(),
                lastDate: PersianDate.now().addMonths(3),
              );
              if (range != null) setState(() => _range = range);
            },
            child: const Text('انتخاب بازه'),
          ),
          Text(_range == null ? '-' : toPersianDigits('$_range')),
          const Divider(height: 32),
          PersianCalendarDatePicker(
            selectedDate: _date,
            onDateChanged: (date) => setState(() => _date = date),
          ),
        ],
      ),
    );
  }
}
