import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import '../../utils/board_enum.dart';
import 'calendar.dart';

class MultipleCalendarWidget extends CalendarWidget {
  const MultipleCalendarWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChange,
    required super.boxDecoration,
    required super.textColor,
    required super.wide,
    required super.activeColor,
    required super.activeTextColor,
    required super.languages,
    required super.minimumDate,
    required super.maximumDate,
    required super.startDayOfWeek,
    required super.weekend,
    required this.onChangeDateType,
  });

  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<DateTime> endDate;
  final void Function(DateTime start, DateTime end) onChange;

  /// Callback when date type is changed during editing
  final void Function(MultiCurrentDateType) onChangeDateType;

  @override
  CalendarWidgetState<MultipleCalendarWidget> createState() =>
      _MultipleCalendarWidgetState();
}

class _MultipleCalendarWidgetState
    extends CalendarWidgetState<MultipleCalendarWidget> {
  /// Flag if you made the 1st selection.
  bool firstTouched = false;

  late DateTime initialStartDate;
  late DateTime initialEndDate;

  @override
  DateTime get minimumDate {
    if (firstTouched) {
      return selectedDate.first;
    }
    return widget.minimumDate;
  }

  @override
  void initState() {
    initialStartDate = widget.startDate.value;
    initialEndDate = widget.endDate.value;
    initialDate = widget.startDate.value;
    widget.startDate.addListener(changeListener);
    widget.endDate.addListener(changeListener);
    super.initState();

    selectedDate = [
      widget.startDate.value,
      widget.endDate.value,
    ];
  }

  @override
  void dispose() {
    widget.startDate.removeListener(changeListener);
    widget.endDate.removeListener(changeListener);
    super.dispose();
  }

  void changeListener() {
    final d = widget.startDate.value;
    final diff = diffYMD(initialDate, d);
    if (mounted) {
      if (pageController.hasClients && firstTouched) {
        pageController.animateToPage(
          initialPage + diff,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      setState(() {
        selectedDate = [d, widget.endDate.value];
      });
    }
  }

  @override
  bool isSelected(DateTime date) {
    final first = selectedDate.first;
    final last = selectedDate.last;
    final result = date.isWithinRangeAndEqualsDate(first, last);
    return result;
  }

  @override
  void onChange(DateTime date) {}

  @override
  void onTap(DateTime date) {
    final d = firstTouched ? initialEndDate : initialStartDate;
    final to = DateTime(date.year, date.month, date.day, d.hour, d.minute);

    if (firstTouched) {
      firstTouched = false;
      widget.onChange(selectedDate.first, to);
      selectedDate = [selectedDate.first, to];
      widget.onChangeDateType(MultiCurrentDateType.start);
    } else {
      firstTouched = true;
      widget.onChange(
        to,
        DateTime(
          to.year,
          to.month,
          to.day,
          initialEndDate.hour,
          initialEndDate.minute,
        ),
      );
      selectedDate = [to];
      widget.onChangeDateType(MultiCurrentDateType.end);
    }

    setState(() {});
  }

  @override
  CalendarSelectedProps getProps(DateTime date) {
    final first = selectedDate.first;
    final last = selectedDate.last;
    final result = date.isWithinRangeAndEqualsDate(first, last);

    const double space = 4;
    const double radius = 50;

    if (result) {
      if (first.compareDate(last)) {
        return CalendarSelectedProps(
          margin: const EdgeInsets.all(space),
          borderRadius: BorderRadius.circular(radius),
        );
      }
      if (date.compareDate(first)) {
        return CalendarSelectedProps(
          margin: const EdgeInsets.only(left: space, top: space, bottom: space),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
          ),
        );
      } else if (date.compareDate(last)) {
        return CalendarSelectedProps(
          margin:
              const EdgeInsets.only(right: space, top: space, bottom: space),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          ),
        );
      }
      return CalendarSelectedProps(
        margin: const EdgeInsets.symmetric(vertical: space),
        borderRadius: BorderRadius.circular(0),
      );
    }

    return CalendarSelectedProps(
      margin: const EdgeInsets.all(space),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
