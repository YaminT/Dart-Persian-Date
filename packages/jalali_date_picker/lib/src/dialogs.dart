import 'package:flutter/material.dart';
import 'package:jalali_date/jalali_date.dart';

import 'calendar.dart';

/// Shows a dialog for picking one day and returns it, or null when the
/// dialog is cancelled or dismissed.
///
/// [initialDate] defaults to today, clamped to [firstDate] and [lastDate],
/// which default to [PersianDate.min] and [PersianDate.max]. The labels
/// default to Persian; pass [helpText], [confirmText], and [cancelText] to
/// change them.
///
/// Throws [ArgumentError] when [lastDate] is before [firstDate], or when
/// [initialDate] is outside them.
Future<PersianDate?> showPersianDatePicker({
  required BuildContext context,
  PersianDate? initialDate,
  PersianDate? firstDate,
  PersianDate? lastDate,
  PersianSelectableDayPredicate? selectableDayPredicate,
  bool persianDigits = true,
  String helpText = 'انتخاب تاریخ',
  String confirmText = 'تأیید',
  String cancelText = 'لغو',
  TextDirection textDirection = TextDirection.rtl,
}) {
  final first = firstDate ?? PersianDate.min;
  final last = lastDate ?? PersianDate.max;
  _checkLimits(first, last);
  final initial = initialDate ?? _clamp(PersianDate.now(), first, last);
  if (initial.isBefore(first) || initial.isAfter(last)) {
    throw ArgumentError.value('$initial', 'initialDate', 'Outside the limits');
  }
  return showDialog<PersianDate>(
    context: context,
    builder: (context) {
      var selected = PersianDate(initial.year, initial.month, initial.day);
      return StatefulBuilder(
        builder: (context, setState) => _PickerDialog(
          textDirection: textDirection,
          helpText: helpText,
          headline: _label(selected.format('EEEE d MMMM'), persianDigits),
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: () => Navigator.of(context).pop(selected),
          calendar: PersianCalendarDatePicker(
            selectedDate: selected,
            firstDate: first,
            lastDate: last,
            selectableDayPredicate: selectableDayPredicate,
            persianDigits: persianDigits,
            textDirection: textDirection,
            onDateChanged: (day) => setState(() => selected = day),
          ),
        ),
      );
    },
  );
}

/// Shows a dialog for picking a range of days and returns it, or null when
/// the dialog is cancelled or dismissed.
///
/// The first tap picks the start and the second the end; confirming with
/// only a start returns a one-day range. [firstDate] and [lastDate] default
/// to [PersianDate.min] and [PersianDate.max].
///
/// Throws [ArgumentError] when [lastDate] is before [firstDate], or when
/// [initialRange] is outside them.
Future<PersianDateRange?> showPersianDateRangePicker({
  required BuildContext context,
  PersianDateRange? initialRange,
  PersianDate? firstDate,
  PersianDate? lastDate,
  PersianSelectableDayPredicate? selectableDayPredicate,
  bool persianDigits = true,
  String helpText = 'انتخاب بازه',
  String confirmText = 'تأیید',
  String cancelText = 'لغو',
  TextDirection textDirection = TextDirection.rtl,
}) {
  final first = firstDate ?? PersianDate.min;
  final last = lastDate ?? PersianDate.max;
  _checkLimits(first, last);
  if (initialRange != null &&
      (initialRange.start.isBefore(first) || initialRange.end.isAfter(last))) {
    throw ArgumentError.value(
        '$initialRange', 'initialRange', 'Outside the limits');
  }
  return showDialog<PersianDateRange>(
    context: context,
    builder: (context) {
      var range = initialRange;
      return StatefulBuilder(
        builder: (context, setState) {
          final current = range;
          final headline = current == null
              ? '-'
              : '${current.start.format('d MMMM')} - '
                  '${current.end.format('d MMMM')}';
          return _PickerDialog(
            textDirection: textDirection,
            helpText: helpText,
            headline: _label(headline, persianDigits),
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: current == null
                ? null
                : () => Navigator.of(context).pop(current),
            calendar: PersianCalendarRangePicker(
              initialRange: initialRange,
              firstDate: first,
              lastDate: last,
              selectableDayPredicate: selectableDayPredicate,
              persianDigits: persianDigits,
              textDirection: textDirection,
              onRangeChanged: (value) => setState(() => range = value),
            ),
          );
        },
      );
    },
  );
}

void _checkLimits(PersianDate first, PersianDate last) {
  if (last.isBefore(first)) {
    throw ArgumentError.value('$last', 'lastDate', 'Before firstDate $first');
  }
}

PersianDate _clamp(PersianDate date, PersianDate first, PersianDate last) {
  if (date.isBefore(first)) return first;
  if (date.isAfter(last)) return last;
  return date;
}

String _label(String text, bool persianDigits) =>
    persianDigits ? toPersianDigits(text) : text;

class _PickerDialog extends StatelessWidget {
  final TextDirection textDirection;
  final String helpText;
  final String headline;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final Widget calendar;

  const _PickerDialog({
    required this.textDirection,
    required this.helpText,
    required this.headline,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.calendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: textDirection,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(helpText, style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(
                        headline,
                        key: const ValueKey('persian-picker-headline'),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                calendar,
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(cancelText),
                      ),
                      TextButton(
                        onPressed: onConfirm,
                        child: Text(confirmText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
