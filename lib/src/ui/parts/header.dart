import 'dart:math';

import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import 'buttons.dart';

class BoardDateTimeHeader extends StatefulWidget {
  const BoardDateTimeHeader({
    super.key,
    required this.wide,
    required this.dateState,
    required this.pickerType,
    required this.keyboardHeightRatio,
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
    required this.modal,
    required this.withTextField,
    required this.pickerFocusNode,
    required this.topMargin,
  });

  /// Wide mode display flag
  final bool wide;

  /// [ValueNotifier] to manage the Datetime under selection
  final ValueNotifier<DateTime> dateState;

  /// Display picker type.
  final DateTimePickerType pickerType;

  /// Animation that detects and resizes the keyboard display
  final double keyboardHeightRatio;

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

  /// Modal Flag
  final bool modal;

  /// TextField Flag
  final bool withTextField;

  /// Picker FocusNode
  final FocusNode? pickerFocusNode;

  /// Header Top margin
  final double topMargin;

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
    isTomorrow = dateState.value.compareDate(now.addDay(1));
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: widget.wide ? 64 : 52,
      margin: EdgeInsets.only(top: widget.topMargin, left: 8, right: 8),
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
          // Visibility(
          //   visible: widget.keyboardHeightRatio == 0,
          //   child: Opacity(
          //     opacity: 0.8 * (1 - widget.keyboardHeightRatio),
          //     child: IconButton(
          //       onPressed: () {
          //         widget.onKeyboadClose();
          //       },
          //       icon: const Icon(
          //         Icons.keyboard_hide_rounded,
          //       ),
          //       color: widget.textColor,
          //     ),
          //   ),
          // ),
          widget.modal
              ? IconButton(
                  onPressed: () {
                    widget.onClose();
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  color: widget.activeColor,
                )
              : Opacity(
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

    if (widget.withTextField) {
      return GestureDetector(
        onTapDown: (_) {
          widget.pickerFocusNode?.requestFocus();
        },
        child: child,
      );
    }
    return child;
  }

  List<Widget> _dateItems(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.addDay(1);
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
            widget.onChangeDate(DateTime.now().addDayWithTime(1));
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

class BoardDateTimeNoneButtonHeader extends StatefulWidget {
  const BoardDateTimeNoneButtonHeader({
    super.key,
    required this.options,
    required this.wide,
    required this.dateState,
    required this.pickerType,
    required this.keyboardHeightRatio,
    required this.calendarAnimation,
    required this.onCalendar,
    required this.onKeyboadClose,
    required this.onClose,
    required this.modal,
    required this.pickerFocusNode,
  });

  final BoardDateTimeOptions options;

  /// Wide mode display flag
  final bool wide;

  /// [ValueNotifier] to manage the Datetime under selection
  final ValueNotifier<DateTime> dateState;

  /// Display picker type.
  final DateTimePickerType pickerType;

  /// Animation that detects and resizes the keyboard display
  final double keyboardHeightRatio;

  /// Animation to show/hide the calendar
  final Animation<double> calendarAnimation;

  /// Callback show calendar
  final void Function() onCalendar;

  /// Keyboard close request
  final void Function() onKeyboadClose;

  /// Picker close request
  final void Function() onClose;

  /// Modal Flag
  final bool modal;

  /// Picker FocusNode
  final FocusNode? pickerFocusNode;

  @override
  State<BoardDateTimeNoneButtonHeader> createState() =>
      _BoardDateTimeNoneButtonHeaderState();
}

class _BoardDateTimeNoneButtonHeaderState
    extends State<BoardDateTimeNoneButtonHeader> {
  double get buttonSize => widget.wide ? 40 : 36;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: buttonSize + 8,
      margin: const EdgeInsets.only(top: 12, left: 8, right: 8),
      child: Row(
        children: [
          if (widget.pickerType != DateTimePickerType.time && !widget.wide) ...[
            CustomIconButton(
              icon: Icons.view_day_rounded,
              bgColor: widget.options.getForegroundColor(context),
              fgColor: widget.options.getTextColor(context)?.withOpacity(0.8),
              onTap: widget.onCalendar,
              buttonSize: buttonSize,
              child: Transform.rotate(
                angle: pi * 4 * widget.calendarAnimation.value,
                child: Icon(
                  widget.calendarAnimation.value > 0.5
                      ? Icons.view_day_rounded
                      : Icons.calendar_month_rounded,
                  size: 20,
                ),
              ),
            ),
          ] else ...[
            SizedBox(width: buttonSize),
          ],
          if (widget.keyboardHeightRatio == 0) SizedBox(width: buttonSize + 8),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _title(),
              ),
            ),
          ),
          ..._rightButton(),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) {
        widget.pickerFocusNode?.requestFocus();
      },
      child: child,
    );
  }

  Widget _title() {
    if (widget.options.boardTitle == null ||
        widget.options.boardTitle!.isEmpty) {
      return const SizedBox();
    }
    return FittedBox(
      child: Text(
        widget.options.boardTitle ?? '',
        style: widget.options.boardTitleTextStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: widget.options.getTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
      ),
    );
  }

  List<Widget> _rightButton() {
    // Widget? closeKeyboard;

    // if (widget.keyboardHeightRatio == 0) {
    //   closeKeyboard = Visibility(
    //     visible: widget.keyboardHeightRatio == 0,
    //     child: CustomIconButton(
    //       icon: Icons.keyboard_hide_rounded,
    //       bgColor: widget.options.getForegroundColor(context),
    //       fgColor: widget.options.getTextColor(context),
    //       onTap: widget.onKeyboadClose,
    //       buttonSize: buttonSize,
    //     ),
    //   );
    // }

    Widget child = widget.modal
        ? CustomIconButton(
            icon: Icons.check_circle_rounded,
            bgColor: widget.options.getActiveColor(context),
            fgColor: widget.options.getActiveTextColor(context),
            onTap: widget.onClose,
            buttonSize: buttonSize,
          )
        : CustomIconButton(
            icon: Icons.close_rounded,
            bgColor: widget.options.getForegroundColor(context),
            fgColor: widget.options.getTextColor(context)?.withOpacity(0.8),
            onTap: widget.onClose,
            buttonSize: buttonSize,
          );

    return [
      // if (closeKeyboard != null) ...[
      //   closeKeyboard,
      //   const SizedBox(width: 8),
      // ],
      child,
    ];
  }
}

class TopTitleWidget extends StatelessWidget {
  const TopTitleWidget({super.key, required this.options});

  final BoardDateTimeOptions options;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 8, right: 8),
      alignment: Alignment.center,
      child: Text(
        options.boardTitle ?? '',
        style: options.boardTitleTextStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: options.getTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
        maxLines: 1,
      ),
    );
  }
}
