import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalali_date_picker/jalali_date_picker.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Finder _day(PersianDate day) =>
    find.byKey(ValueKey('persian-calendar-day-${day.toJson()}'));

void main() {
  testWidgets('weekday header starts on Saturday, right-to-left',
      (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 7, 1),
      onDateChanged: (_) {},
    )));
    final saturday = tester.getCenter(find.text('ش'));
    final sunday = tester.getCenter(find.text('ی'));
    final friday = tester.getCenter(find.text('ج'));
    expect(saturday.dx, greaterThan(sunday.dx));
    expect(sunday.dx, greaterThan(friday.dx));
  });

  testWidgets('days sit in their Persian weekday column', (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 7, 1),
      onDateChanged: (_) {},
    )));
    // 1403/07/01 is a Sunday and 1403/07/06 a Friday.
    expect(
      tester.getCenter(_day(PersianDate(1403, 7, 1))).dx,
      moreOrLessEquals(tester.getCenter(find.text('ی')).dx, epsilon: 1),
    );
    expect(
      tester.getCenter(_day(PersianDate(1403, 7, 6))).dx,
      moreOrLessEquals(tester.getCenter(find.text('ج')).dx, epsilon: 1),
    );
    expect(_day(PersianDate(1403, 7, 30)), findsOneWidget);
    expect(_day(PersianDate(1403, 8, 1)), findsNothing);
    expect(find.text('مهر ۱۴۰۳'), findsOneWidget);
    expect(find.text('۱۵'), findsOneWidget);
  });

  testWidgets('tapping a day reports it; limits disable days', (tester) async {
    final tapped = <PersianDate>[];
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 7, 1),
      firstDate: PersianDate(1403, 7, 10),
      lastDate: PersianDate(1403, 7, 20),
      selectableDayPredicate: (day) => day.day != 15,
      onDateChanged: tapped.add,
    )));
    await tester.tap(_day(PersianDate(1403, 7, 12)));
    await tester.tap(_day(PersianDate(1403, 7, 5)));
    await tester.tap(_day(PersianDate(1403, 7, 15)));
    await tester.tap(_day(PersianDate(1403, 7, 25)));
    expect(tapped, [PersianDate(1403, 7, 12)]);
    final previous = tester.widget<IconButton>(
        find.byKey(const ValueKey('persian-calendar-previous')));
    final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('persian-calendar-next')));
    expect(previous.onPressed, isNull);
    expect(next.onPressed, isNull);
  });

  testWidgets('month navigation', (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 12, 1),
      onDateChanged: (_) {},
    )));
    expect(_day(PersianDate(1403, 12, 30)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('persian-calendar-next')));
    await tester.pump();
    expect(find.text('فروردین ۱۴۰۴'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('persian-calendar-previous')));
    await tester.tap(find.byKey(const ValueKey('persian-calendar-previous')));
    await tester.pump();
    expect(find.text('بهمن ۱۴۰۳'), findsOneWidget);
  });

  testWidgets('month and year views jump', (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 7, 1),
      onDateChanged: (_) {},
    )));
    await tester.tap(find.byKey(const ValueKey('persian-calendar-title')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('persian-calendar-month-12')));
    await tester.pump();
    expect(find.text('اسفند ۱۴۰۳'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('persian-calendar-title')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('persian-calendar-years')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('persian-calendar-year-1399')),
      -100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('persian-calendar-year-1399')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('persian-calendar-month-12')));
    await tester.pump();
    expect(find.text('اسفند ۱۳۹۹'), findsOneWidget);
    expect(_day(PersianDate(1399, 12, 30)), findsOneWidget);
  });

  testWidgets('months outside the limits are disabled', (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 7, 1),
      firstDate: PersianDate(1403, 3, 15),
      lastDate: PersianDate(1403, 9, 1),
      onDateChanged: (_) {},
    )));
    await tester.tap(find.byKey(const ValueKey('persian-calendar-title')));
    await tester.pump();
    TextButton month(int m) => tester
        .widget<TextButton>(find.byKey(ValueKey('persian-calendar-month-$m')));
    expect(month(2).onPressed, isNull);
    expect(month(3).onPressed, isNotNull);
    expect(month(9).onPressed, isNotNull);
    expect(month(10).onPressed, isNull);
  });

  testWidgets('Latin digits on request', (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate(1403, 7, 1),
      persianDigits: false,
      onDateChanged: (_) {},
    )));
    expect(find.text('مهر 1403'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('the last supported month renders up to PersianDate.max',
      (tester) async {
    await tester.pumpWidget(_app(PersianCalendarDatePicker(
      initialMonth: PersianDate.max,
      onDateChanged: (_) {},
    )));
    expect(_day(PersianDate.max), findsOneWidget);
    expect(find.text('۱۲'), findsNothing);
    final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('persian-calendar-next')));
    expect(next.onPressed, isNull);
  });

  test('lastDate before firstDate throws', () {
    expect(
      () => PersianCalendar(
        firstDate: PersianDate(1403, 2, 1),
        lastDate: PersianDate(1403, 1, 1),
        isSelected: (_) => false,
        isInRange: (_) => false,
        onDayTapped: (_) {},
      ),
      throwsArgumentError,
    );
  });

  testWidgets('range picker taps', (tester) async {
    final ranges = <PersianDateRange>[];
    await tester.pumpWidget(_app(PersianCalendarRangePicker(
      firstDate: PersianDate(1403, 1, 1),
      lastDate: PersianDate(1403, 12, 30),
      onRangeChanged: ranges.add,
    )));
    await tester.tap(find.byKey(const ValueKey('persian-calendar-title')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('persian-calendar-month-7')));
    await tester.pump();
    PersianDateRange r(int a, int b) =>
        PersianDateRange(PersianDate(1403, 7, a), PersianDate(1403, 7, b));
    await tester.tap(_day(PersianDate(1403, 7, 10)));
    await tester.pump();
    await tester.tap(_day(PersianDate(1403, 7, 3)));
    await tester.pump();
    await tester.tap(_day(PersianDate(1403, 7, 8)));
    await tester.pump();
    await tester.tap(_day(PersianDate(1403, 7, 20)));
    await tester.pump();
    expect(ranges, [r(10, 10), r(3, 3), r(3, 8), r(20, 20)]);
  });

  group('dialogs', () {
    Future<void> open(
        WidgetTester tester,
        Future<Object?> Function(BuildContext) show,
        List<Object?> results) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(await show(context)),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('date picker confirms and cancels', (tester) async {
      final results = <Object?>[];
      Future<Object?> show(BuildContext context) => showPersianDatePicker(
            context: context,
            initialDate: PersianDate(1403, 7, 1),
          );
      await open(tester, show, results);
      expect(find.text('یکشنبه ۱ مهر'), findsOneWidget);
      await tester.tap(_day(PersianDate(1403, 7, 4)));
      await tester.pump();
      expect(find.text('چهارشنبه ۴ مهر'), findsOneWidget);
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      expect(results, [PersianDate(1403, 7, 4)]);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('لغو'));
      await tester.pumpAndSettle();
      expect(results, [PersianDate(1403, 7, 4), null]);
    });

    testWidgets('range picker needs a tap before confirming', (tester) async {
      final results = <Object?>[];
      Future<Object?> show(BuildContext context) => showPersianDateRangePicker(
            context: context,
            firstDate: PersianDate(1403, 7, 1),
            lastDate: PersianDate(1403, 7, 30),
          );
      await open(tester, show, results);
      final confirm = find.widgetWithText(TextButton, 'تأیید');
      expect(tester.widget<TextButton>(confirm).onPressed, isNull);
      await tester.tap(_day(PersianDate(1403, 7, 2)));
      await tester.pump();
      await tester.tap(_day(PersianDate(1403, 7, 5)));
      await tester.pump();
      expect(find.text('۲ مهر - ۵ مهر'), findsOneWidget);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(results, [
        PersianDateRange(PersianDate(1403, 7, 2), PersianDate(1403, 7, 5)),
      ]);
    });

    testWidgets('invalid limits throw before showing', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      ));
      expect(
        () => showPersianDatePicker(
          context: captured,
          initialDate: PersianDate(1403, 1, 1),
          firstDate: PersianDate(1403, 2, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => showPersianDateRangePicker(
          context: captured,
          firstDate: PersianDate(1403, 2, 1),
          lastDate: PersianDate(1403, 1, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  testWidgets('dialogs fit a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showPersianDateRangePicker(
            context: context,
            initialRange: PersianDateRange(
                PersianDate(1403, 7, 1), PersianDate(1403, 7, 9)),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('persian-calendar-title')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('persian-calendar-years')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
