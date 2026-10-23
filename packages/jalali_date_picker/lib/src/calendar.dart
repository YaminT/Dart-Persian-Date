import 'package:flutter/material.dart';
import 'package:jalali_date/jalali_date.dart';

/// Decides whether a day can be picked, on top of the first and last date.
typedef PersianSelectableDayPredicate = bool Function(PersianDate day);

/// An inline calendar for picking one day.
///
/// Shows one month at a time with Saturday in the first column. Tapping the
/// month title switches to a month list and then a year list for quick
/// jumps. Days outside [firstDate] and [lastDate], and days rejected by
/// [selectableDayPredicate], are disabled.
///
/// The calendar lays itself out with [textDirection], right-to-left by
/// default, so it reads correctly inside a left-to-right app.
class PersianCalendarDatePicker extends StatelessWidget {
  /// The selected day, or null for none.
  final PersianDate? selectedDate;

  /// The month shown first; defaults to [selectedDate], then today, clamped
  /// to [firstDate] and [lastDate].
  final PersianDate? initialMonth;

  /// The earliest day that can be picked; defaults to [PersianDate.min].
  final PersianDate? firstDate;

  /// The latest day that can be picked; defaults to [PersianDate.max].
  final PersianDate? lastDate;

  /// Called with the tapped day.
  final ValueChanged<PersianDate> onDateChanged;

  /// Extra rule for which days can be picked.
  final PersianSelectableDayPredicate? selectableDayPredicate;

  /// Whether numbers are shown as Persian digits.
  final bool persianDigits;

  /// Layout direction of the calendar.
  final TextDirection textDirection;

  /// Creates the calendar.
  const PersianCalendarDatePicker({
    super.key,
    this.selectedDate,
    this.initialMonth,
    this.firstDate,
    this.lastDate,
    required this.onDateChanged,
    this.selectableDayPredicate,
    this.persianDigits = true,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) => PersianCalendar(
        initialMonth: initialMonth ?? selectedDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: selectableDayPredicate,
        persianDigits: persianDigits,
        textDirection: textDirection,
        isSelected: (day) => day == selectedDate,
        isInRange: (_) => false,
        onDayTapped: onDateChanged,
      );
}

/// An inline calendar for picking a range of days.
///
/// The first tap starts a range, the second tap ends it, and a third tap
/// starts a new one. Tapping a day before the start moves the start.
/// [onRangeChanged] gets the range after every tap; while only the start is
/// picked, the range is that single day.
class PersianCalendarRangePicker extends StatefulWidget {
  /// The range selected at first, or null for none.
  final PersianDateRange? initialRange;

  /// The earliest day that can be picked; defaults to [PersianDate.min].
  final PersianDate? firstDate;

  /// The latest day that can be picked; defaults to [PersianDate.max].
  final PersianDate? lastDate;

  /// Called after every tap with the current range.
  final ValueChanged<PersianDateRange> onRangeChanged;

  /// Extra rule for which days can be picked.
  final PersianSelectableDayPredicate? selectableDayPredicate;

  /// Whether numbers are shown as Persian digits.
  final bool persianDigits;

  /// Layout direction of the calendar.
  final TextDirection textDirection;

  /// Creates the calendar.
  const PersianCalendarRangePicker({
    super.key,
    this.initialRange,
    this.firstDate,
    this.lastDate,
    required this.onRangeChanged,
    this.selectableDayPredicate,
    this.persianDigits = true,
    this.textDirection = TextDirection.rtl,
  });

  @override
  State<PersianCalendarRangePicker> createState() =>
      _PersianCalendarRangePickerState();
}

class _PersianCalendarRangePickerState
    extends State<PersianCalendarRangePicker> {
  PersianDate? _start;
  PersianDate? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
  }

  void _tap(PersianDate day) {
    setState(() {
      final start = _start;
      if (start == null || _end != null || day.isBefore(start)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
    });
    widget.onRangeChanged(PersianDateRange(_start!, _end ?? _start!));
  }

  @override
  Widget build(BuildContext context) => PersianCalendar(
        initialMonth: _start,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        selectableDayPredicate: widget.selectableDayPredicate,
        persianDigits: widget.persianDigits,
        textDirection: widget.textDirection,
        isSelected: (day) => day == _start || day == _end,
        isInRange: (day) {
          final start = _start;
          final end = _end;
          return start != null && end != null && day > start && day < end;
        },
        onDayTapped: _tap,
      );
}

enum _View { days, months, years }

/// The calendar behind [PersianCalendarDatePicker] and
/// [PersianCalendarRangePicker], for custom selection rules.
///
/// [isSelected] and [isInRange] decide how each day is painted, and
/// [onDayTapped] receives taps on enabled days.
class PersianCalendar extends StatefulWidget {
  /// The month shown first; defaults to today, clamped to [firstDate] and
  /// [lastDate].
  final PersianDate? initialMonth;

  /// The earliest day that can be picked; defaults to [PersianDate.min].
  final PersianDate? firstDate;

  /// The latest day that can be picked; defaults to [PersianDate.max].
  final PersianDate? lastDate;

  /// Extra rule for which days can be picked.
  final PersianSelectableDayPredicate? selectableDayPredicate;

  /// Whether numbers are shown as Persian digits.
  final bool persianDigits;

  /// Layout direction of the calendar.
  final TextDirection textDirection;

  /// Whether a day is painted as selected.
  final bool Function(PersianDate day) isSelected;

  /// Whether a day is painted as inside a selected range.
  final bool Function(PersianDate day) isInRange;

  /// Called with an enabled day when it is tapped.
  final ValueChanged<PersianDate> onDayTapped;

  /// Creates the calendar.
  ///
  /// Throws [ArgumentError] when [lastDate] is before [firstDate].
  PersianCalendar({
    super.key,
    this.initialMonth,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.persianDigits = true,
    this.textDirection = TextDirection.rtl,
    required this.isSelected,
    required this.isInRange,
    required this.onDayTapped,
  }) {
    if ((lastDate ?? PersianDate.max).isBefore(firstDate ?? PersianDate.min)) {
      throw ArgumentError.value('$lastDate', 'lastDate', 'Before firstDate');
    }
  }

  @override
  State<PersianCalendar> createState() => _PersianCalendarState();
}

class _PersianCalendarState extends State<PersianCalendar> {
  static const _rowHeight = 48.0;

  late PersianDate _month;
  var _view = _View.days;

  PersianDate get _first => widget.firstDate ?? PersianDate.min;
  PersianDate get _last => widget.lastDate ?? PersianDate.max;

  @override
  void initState() {
    super.initState();
    _month = _clampMonth(widget.initialMonth ?? PersianDate.now());
  }

  PersianDate _clampMonth(PersianDate date) {
    if (date.isBefore(_first)) return _first.firstDayOfMonth;
    if (date.isAfter(_last)) return _last.firstDayOfMonth;
    return date.firstDayOfMonth;
  }

  String _digits(String text) =>
      widget.persianDigits ? toPersianDigits(text) : text;

  bool _enabled(PersianDate day) =>
      !day.isBefore(_first) &&
      !day.isAfter(_last) &&
      (widget.selectableDayPredicate?.call(day) ?? true);

  bool get _hasPrevious => _month.isAfter(_first.firstDayOfMonth);
  bool get _hasNext => _month.isBefore(_last.firstDayOfMonth);

  /// First day of [month] in [year], or null past [PersianDate.max].
  static PersianDate? _monthStart(int year, int month) {
    final max = PersianDate.max;
    if (year > max.year || (year == max.year && month > max.month)) {
      return null;
    }
    return PersianDate(year, month, 1);
  }

  void _showMonth(PersianDate month) => setState(() {
        _month = _clampMonth(month);
        _view = _View.days;
      });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.textDirection,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          SizedBox(
            height: _rowHeight * 7,
            child: switch (_view) {
              _View.days => _days(context),
              _View.months => _months(context),
              _View.years => _years(context),
            },
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final title = _view == _View.years
        ? _digits('${_month.year}')
        : _digits(_month.format('MMMM yyyy'));
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
      child: Row(
        children: [
          Flexible(
            child: InkWell(
              key: const ValueKey('persian-calendar-title'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                _view = _view == _View.days ? _View.months : _View.days;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Icon(
                      _view == _View.days
                          ? Icons.arrow_drop_down
                          : Icons.arrow_drop_up,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_view == _View.months)
            TextButton(
              key: const ValueKey('persian-calendar-years'),
              onPressed: () => setState(() => _view = _View.years),
              child: Text(_digits('${_month.year}')),
            ),
          const Spacer(),
          if (_view == _View.days) ...[
            IconButton(
              key: const ValueKey('persian-calendar-previous'),
              tooltip: 'ماه قبل',
              icon: const Icon(Icons.chevron_left),
              onPressed: _hasPrevious
                  ? () => setState(() => _month = _month.addMonths(-1))
                  : null,
            ),
            IconButton(
              key: const ValueKey('persian-calendar-next'),
              tooltip: 'ماه بعد',
              icon: const Icon(Icons.chevron_right),
              onPressed: _hasNext
                  ? () => setState(() => _month = _month.addMonths(1))
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _days(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A Saturday, so the header runs Saturday to Friday.
    final saturday = PersianDate(1403, 1, 4);
    final end = _month.isSameMonth(PersianDate.max)
        ? PersianDate.max
        : _month.lastDayOfMonth;
    final cells = <PersianDate?>[
      for (var i = 1; i < _month.weekdayPersian; i++) null,
      ..._month.daysUntil(end),
    ];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: SizedBox(
                  height: _rowHeight,
                  child: Center(
                    child: Text(
                      saturday.addDays(i).weekdayNameShort,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: i == 6 ? scheme.error : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Six fixed rows fit every month, so the height never jumps.
        for (var row = 0; row < 6; row++)
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: switch (row * 7 + column) {
                      final index when index < cells.length =>
                        cells[index] == null
                            ? const SizedBox.shrink()
                            : _day(context, cells[index]!),
                      _ => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _day(BuildContext context, PersianDate day) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = _enabled(day);
    final selected = widget.isSelected(day);
    final inRange = widget.isInRange(day);
    final today = day.isToday;
    final Color foreground;
    if (selected) {
      foreground = scheme.onPrimary;
    } else if (!enabled) {
      foreground = scheme.onSurface.withValues(alpha: 0.38);
    } else if (day.isWeekend) {
      foreground = scheme.error;
    } else if (today) {
      foreground = scheme.primary;
    } else {
      foreground = scheme.onSurface;
    }
    return Semantics(
      label: day.format('EEEE d MMMM yyyy'),
      selected: selected,
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      child: Container(
        color: inRange ? scheme.primaryContainer : null,
        child: InkWell(
          key: ValueKey('persian-calendar-day-${day.toJson()}'),
          customBorder: const CircleBorder(),
          onTap: enabled ? () => widget.onDayTapped(day) : null,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : null,
                border: today && !selected
                    ? Border.all(color: scheme.primary)
                    : null,
              ),
              child: Text(
                _digits('${day.day}'),
                style: TextStyle(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _months(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget month(int m) {
      final start = _monthStart(_month.year, m);
      final enabled = start != null &&
          !start.isBefore(_first.firstDayOfMonth) &&
          !start.isAfter(_last.firstDayOfMonth);
      return Padding(
        padding: const EdgeInsets.all(4),
        child: TextButton(
          key: ValueKey('persian-calendar-month-$m'),
          style: m == _month.month
              ? TextButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                )
              : null,
          onPressed: enabled ? () => _showMonth(start) : null,
          child: Text(PersianDate.monthNames[m - 1]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Expanded(
              child: Row(
                children: [
                  for (var column = 1; column <= 3; column++)
                    Expanded(child: month(row * 3 + column)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _years(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstYear = _first.year;
    final count = _last.year - firstYear + 1;
    const columns = 3;
    const itemHeight = 52.0;
    final row = (_month.year - firstYear) ~/ columns;
    final controller = ScrollController(
      initialScrollOffset: row > 2 ? (row - 2) * itemHeight : 0,
    );
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: itemHeight,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final year = firstYear + index;
        final current = year == _month.year;
        return Padding(
          padding: const EdgeInsets.all(4),
          child: TextButton(
            key: ValueKey('persian-calendar-year-$year'),
            style: current
                ? TextButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  )
                : null,
            onPressed: () => setState(() {
              _month = _clampMonth(
                _monthStart(year, _month.month) ??
                    PersianDate.max.firstDayOfMonth,
              );
              _view = _View.months;
            }),
            child: Text(_digits('$year')),
          ),
        );
      },
    );
  }
}
