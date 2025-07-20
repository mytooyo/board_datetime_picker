import 'dart:math';

import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import '../board_datetime_contents_state.dart';
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
    required this.onTopActionBuilder,
    required this.actionButtonTypes,
    required this.onReset,
    required this.customCloseButtonBuilder,
    required this.viewMode,
    required this.viewModeOrientation,
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

  /// Specify a Widget to be displayed in the action button area externally
  final Widget Function(BuildContext context)? onTopActionBuilder;

  /// List of buttons to select dates.
  final List<BoardDateButtonType> actionButtonTypes;

  /// reset button callback (if use reset)
  final void Function()? onReset;

  /// Custom Close Button Builder
  final CloseButtonBuilder? customCloseButtonBuilder;

  /// View mode
  final BoardDateTimeViewMode viewMode;

  /// View mode Orientation
  final BoardDateTimeOrientation viewModeOrientation;

  @override
  State<BoardDateTimeHeader> createState() => BoardDateTimeHeaderState();
}

class BoardDateTimeHeaderState extends State<BoardDateTimeHeader> {
  bool isToday = true;
  bool isTomorrow = false;
  bool isYesterday = false;

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
    isYesterday = dateState.value.compareDate(now.addDay(-1));
  }

  double get height => widget.wide ? 64 : 52;

  Widget _defaultCloseButtonBuilder(
    BuildContext context,
    bool isModal,
    void Function() onClose,
  ) =>
      isModal
          ? IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.check_circle_rounded),
              color: widget.activeColor,
            )
          : Opacity(
              opacity: 0.6,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: widget.textColor,
              ),
            );

  @override
  Widget build(BuildContext context) {
    final onReset = widget.onReset;
    final topActionWidget = widget.onTopActionBuilder?.call(context);

    final closeButtonBuilder =
        widget.customCloseButtonBuilder ?? _defaultCloseButtonBuilder;
    final closeButton =
        closeButtonBuilder(context, widget.modal, widget.onClose);

    final child = Container(
      height: height,
      margin: EdgeInsets.only(top: widget.topMargin, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.foregroundColor.withValues(alpha: 0.99),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (topActionWidget == null) ...[
            if (widget.pickerType == DateTimePickerType.time)
              ..._timeItems(context)
            else
              ..._dateItems(context),
            Expanded(child: Container())
          ] else ...[
            if (widget.pickerType != DateTimePickerType.time) _calendarButton(),
            Expanded(child: topActionWidget),
          ],

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
          if (onReset != null)
            GestureDetector(
              child: Container(
                width: 40,
                alignment: Alignment.center,
                child: IconButton(
                  onPressed: () {
                    widget.onReset?.call();
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  color: widget.textColor,
                ),
              ),
              onTap: () {},
            ),

          closeButton,
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

  Widget _calendarButton() {
    if (widget.viewMode == BoardDateTimeViewMode.calendarOnly ||
        widget.viewMode == BoardDateTimeViewMode.pickerOnly) {
      return const SizedBox(width: 16);
    }

    if (widget.wide ||
        widget.viewModeOrientation == BoardDateTimeOrientation.vertical) {
      return const SizedBox(width: 24);
    } else {
      return Opacity(
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
      );
    }
  }

  List<Widget> _dateItems(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.addDay(1);
    final yesterday = today.addDay(-1);

    List<Widget> buttons = [];
    for (final item in widget.actionButtonTypes) {
      switch (item) {
        case BoardDateButtonType.today:
          if (today.isWithinRange(widget.minimumDate, widget.maximumDate)) {
            buttons.add(_textButton(
              context,
              widget.languages.today,
              () => widget.onChangeDate(DateTime.now()),
              selected: isToday,
            ));
          }
          break;
        case BoardDateButtonType.tomorrow:
          if (tomorrow.isWithinRange(widget.minimumDate, widget.maximumDate)) {
            buttons.add(_textButton(
              context,
              widget.languages.tomorrow,
              () => widget.onChangeDate(DateTime.now().addDayWithTime(1)),
              selected: isTomorrow,
            ));
          }
          break;
        case BoardDateButtonType.yesterday:
          if (yesterday.isWithinRange(widget.minimumDate, widget.maximumDate)) {
            buttons.add(_textButton(
              context,
              widget.languages.yesterday,
              () => widget.onChangeDate(DateTime.now().addDayWithTime(-1)),
              selected: isYesterday,
            ));
          }
          break;
      }
    }

    return [
      _calendarButton(),
      Wrap(
        spacing: widget.wide ? 20 : 12,
        children: buttons,
      )
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
          : widget.backgroundColor.withValues(alpha: 0.8),
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
                        : widget.textColor?.withValues(alpha: 0.9),
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
    this.customCloseButtonBuilder,
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

  // Custom Close Button Builder
  final CloseButtonBuilder? customCloseButtonBuilder;

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
          if (widget.pickerType != DateTimePickerType.time &&
              !widget.wide &&
              widget.options.viewModeOrientation ==
                  BoardDateTimeOrientation.normal) ...[
            CustomIconButton(
              icon: Icons.view_day_rounded,
              bgColor: widget.options.getForegroundColor(context),
              fgColor:
                  widget.options.getTextColor(context)?.withValues(alpha: 0.8),
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
    if (widget.options.boardTitleBuilder != null) {
      //title builder
      Widget titleWidget = widget.options.boardTitleBuilder!(
          context,
          widget.options.boardTitleTextStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.options.getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
          widget.dateState.value);

      return FittedBox(
        child: titleWidget,
      );
    }

    if (widget.options.boardTitle != null) {
      //title string
      return FittedBox(
        child: Text(
          widget.options.boardTitle.toString(),
          style: widget.options.boardTitleTextStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.options.getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
          maxLines: 1,
        ),
      );
    }

    return const SizedBox();
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

    Widget child = widget.customCloseButtonBuilder?.call(
          context,
          widget.modal,
          widget.onClose,
        ) ??
        (widget.modal
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
                fgColor: widget.options
                    .getTextColor(context)
                    ?.withValues(alpha: 0.8),
                onTap: widget.onClose,
                buttonSize: buttonSize,
              ));

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
  const TopTitleWidget(
      {super.key, required this.options, required this.selectedDayNotifier});

  final BoardDateTimeOptions options;
  final ValueNotifier<DateTime> selectedDayNotifier;

  Widget _getTitle(BuildContext context, TextStyle? textStyle) {
    if (options.boardTitleBuilder != null) {
      return options.boardTitleBuilder!(
          context, textStyle, selectedDayNotifier.value);
    }

    if (options.boardTitle != null) {
      return Text(
        options.boardTitle.toString(),
        style: textStyle,
        maxLines: 1,
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 8, right: 8),
      alignment: Alignment.center,
      child: _getTitle(
        context,
        options.boardTitleTextStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: options.getTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
      ),
    );
  }
}
