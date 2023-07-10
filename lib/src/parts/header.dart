import 'dart:math';

import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

class BoardDateTimeHeader extends StatefulWidget {
  const BoardDateTimeHeader({
    super.key,
    required this.wide,
    required this.dateState,
    required this.pickerType,
    required this.keyboadAnimation,
    required this.calendarAnimation,
    required this.onCalendar,
    required this.onChangeDate,
    required this.onChangTime,
    required this.onKeyboadClose,
    required this.onClose,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textColor,
    required this.activeColor,
    required this.activeTextColor,
    required this.languages,
    required this.minimumDate,
    required this.maximumDate,
  });

  /// Wide mode display flag
  final bool wide;

  /// [ValueNotifier] to manage the Datetime under selection
  final ValueNotifier<DateTime> dateState;

  /// Display picker type.
  final DateTimePickerType pickerType;

  /// Animation that detects and resizes the keyboard display
  final Animation<double> keyboadAnimation;

  /// Animation to show/hide the calendar
  final Animation<double> calendarAnimation;

  /// Callback show calendar
  final void Function() onCalendar;

  /// Callback on date change
  final void Function(DateTime) onChangeDate;

  /// Callback on datetime change
  final void Function(DateTime) onChangTime;

  /// Keyboard close request
  final void Function() onKeyboadClose;

  /// Picker close request
  final void Function() onClose;

  /// Picker Background Color
  /// default is `Theme.of(context).scaffoldBackgroundColor`
  final Color backgroundColor;

  /// Picket Foreground Color
  /// default is `Theme.of(context).cardColor`
  final Color foregroundColor;

  /// Picker Text Color
  final Color? textColor;

  /// Active Color
  final Color activeColor;

  /// Active Text Color
  final Color activeTextColor;

  /// Class for specifying language information to be used in the picker
  final BoardPickerLanguages languages;

  /// Minimum Date
  final DateTime minimumDate;

  /// Maximum Date
  final DateTime maximumDate;

  @override
  State<BoardDateTimeHeader> createState() => BoardDateTimeHeaderState();
}

class BoardDateTimeHeaderState extends State<BoardDateTimeHeader> {
  bool isToday = true;
  bool isTomorrow = false;

  late ValueNotifier<DateTime> dateState;

  @override
  void initState() {
    setup(widget.dateState);
    super.initState();
  }

  @override
  void dispose() {
    dateState.removeListener(changeListener);
    super.dispose();
  }

  void changeListener() {
    setState(() => judgeDay());
  }

  void setup(ValueNotifier<DateTime> state, {bool rebuild = false}) {
    dateState = state;
    dateState.addListener(changeListener);
    if (rebuild) {
      changeListener();
    } else {
      judgeDay();
    }
  }

  void judgeDay() {
    final now = DateTime.now();
    isToday = dateState.value.compareDate(now);
    isTomorrow = dateState.value.compareDate(now.add(
      const Duration(days: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.wide ? 72 : 52,
      margin: const EdgeInsets.only(top: 20, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.foregroundColor.withOpacity(0.99),
      ),
      child: Row(
        children: [
          if (widget.pickerType == DateTimePickerType.time)
            ..._timeItems(context)
          else
            ..._dateItems(context),
          Expanded(child: Container()),
          Visibility(
            visible: widget.keyboadAnimation.value == 0,
            child: Opacity(
              opacity: 0.8 * (1 - widget.keyboadAnimation.value),
              child: IconButton(
                onPressed: () {
                  widget.onKeyboadClose();
                },
                icon: const Icon(
                  Icons.keyboard_hide_rounded,
                ),
                color: widget.textColor,
              ),
            ),
          ),
          Opacity(
            opacity: 0.6,
            child: IconButton(
              onPressed: () {
                widget.onClose();
              },
              icon: const Icon(Icons.close_rounded),
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _dateItems(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return [
      if (widget.wide)
        const SizedBox(width: 24)
      else
        Opacity(
          opacity: 0.6,
          child: IconButton(
            onPressed: widget.onCalendar,
            icon: Transform.rotate(
              angle: pi * 4 * widget.calendarAnimation.value,
              child: Icon(
                widget.calendarAnimation.value > 0.5
                    ? Icons.view_day_rounded
                    : Icons.calendar_month_rounded,
                size: 20,
              ),
            ),
            color: widget.textColor,
          ),
        ),
      if (today.isWithinRange(widget.minimumDate, widget.maximumDate))
        _textButton(
          context,
          widget.languages.today,
          () => widget.onChangeDate(DateTime.now()),
          selected: isToday,
        ),
      if (tomorrow.isWithinRange(widget.minimumDate, widget.maximumDate)) ...[
        SizedBox(width: widget.wide ? 20 : 12),
        _textButton(
          context,
          widget.languages.tomorrow,
          () {
            widget.onChangeDate(DateTime.now().add(const Duration(days: 1)));
          },
          selected: isTomorrow,
        ),
      ],
    ];
  }

  List<Widget> _timeItems(BuildContext context) {
    if (DateTime.now().isWithinRange(widget.minimumDate, widget.maximumDate)) {
      return [];
    }

    return [
      const SizedBox(width: 24),
      _textButton(
        context,
        widget.languages.now,
        () => widget.onChangTime(DateTime.now()),
      ),
    ];
  }

  Widget _textButton(
    BuildContext context,
    String title,
    void Function() callback, {
    bool selected = false,
  }) {
    return Material(
      color: selected
          ? widget.activeColor
          : widget.backgroundColor.withOpacity(0.8),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: callback,
        child: Container(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: widget.wide ? 24 : 12),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected
                        ? widget.activeTextColor
                        : widget.textColor?.withOpacity(0.9),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
