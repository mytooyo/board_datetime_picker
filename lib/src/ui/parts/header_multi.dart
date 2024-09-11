import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../board_datetime_options.dart';
import '../../utils/board_enum.dart';

class BoardDateTimeMultiHeader extends StatefulWidget {
  const BoardDateTimeMultiHeader({
    super.key,
    required this.wide,
    required this.startDate,
    required this.endDate,
    required this.pickerType,
    required this.keyboardHeightRatio,
    required this.calendarAnimation,
    required this.onCalendar,
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
    required this.currentDateType,
    required this.onChangeDateType,
    required this.pickerFormat,
    required this.topMargin,
  });

  /// Wide mode display flag
  final bool wide;

  /// [ValueNotifier] to start date
  final ValueNotifier<DateTime> startDate;

  /// [ValueNotifier] to end date
  final ValueNotifier<DateTime> endDate;

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

  /// Date type being edited
  final ValueNotifier<MultiCurrentDateType> currentDateType;

  /// Callback when date type is changed during editing
  final void Function(MultiCurrentDateType) onChangeDateType;

  /// Picker Date Format
  final String pickerFormat;

  /// Header Top margin
  final double topMargin;

  @override
  State<BoardDateTimeMultiHeader> createState() =>
      _BoardDateTimeMultiHeaderState();
}

class _BoardDateTimeMultiHeaderState extends State<BoardDateTimeMultiHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> startScaleAnimation;
  late Animation<double> endScaleAnimation;

  double get dateItemWidth => 108;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final curve = CurveTween(curve: Curves.easeInOut);
    startScaleAnimation = animationController.drive(curve).drive(
          Tween<double>(begin: 1.0, end: 0.9),
        );
    endScaleAnimation = animationController.drive(curve).drive(
          Tween<double>(begin: 0.9, end: 1.0),
        );

    widget.currentDateType.addListener(_typeListener);
  }

  @override
  void dispose() {
    animationController.dispose();
    widget.currentDateType.removeListener(_typeListener);
    super.dispose();
  }

  void _typeListener() {
    if (widget.currentDateType.value == MultiCurrentDateType.start) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rightIcon = widget.modal
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
          );

    final child = Container(
      height: widget.wide ? 64 : 52,
      margin: EdgeInsets.only(top: widget.topMargin, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.foregroundColor.withOpacity(0.99),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: widget.pickerType != DateTimePickerType.time && !widget.wide
                ? Opacity(
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
                  )
                : const SizedBox(),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return ValueListenableBuilder(
                    valueListenable: widget.currentDateType,
                    builder: (context, value, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: dateItemWidth * startScaleAnimation.value,
                            height: 32 * startScaleAnimation.value,
                            child: _datetimeItem(
                              widget.startDate,
                              MultiCurrentDateType.start,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 2,
                            width: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: widget.backgroundColor,
                            ),
                          ),
                          SizedBox(
                            width: dateItemWidth * endScaleAnimation.value,
                            height: 32 * endScaleAnimation.value,
                            child: _datetimeItem(
                              widget.endDate,
                              MultiCurrentDateType.end,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              width: 40,
              alignment: Alignment.center,
              child: rightIcon,
            ),
            onTap: () {},
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

  Widget _datetimeItem(
    ValueNotifier<DateTime> date,
    MultiCurrentDateType dateType,
  ) {
    final selected = widget.currentDateType.value == dateType;

    String format = '';
    if (widget.pickerType != DateTimePickerType.time) {
      final pickerFormat = widget.pickerFormat;
      for (var i = 0; i < pickerFormat.length; i++) {
        final x = pickerFormat[i];
        if (x == 'y') {
          format += 'yyyy';
        } else if (x == 'M') {
          format += 'MM';
        } else {
          format += 'dd';
        }
        if (i != pickerFormat.length - 1) {
          format += '/';
        }
      }

      if (widget.pickerType == DateTimePickerType.datetime) {
        format += ' HH:mm';
      }
    } else {
      format = 'HH:mm';
    }

    return Material(
      color: selected
          ? widget.activeColor
          : widget.backgroundColor.withOpacity(0.8),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: selected || widget.calendarAnimation.value > 0
            ? null
            : () {
                widget.onChangeDateType.call(dateType);
              },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: widget.wide ? 8 : 8),
          child: ValueListenableBuilder(
            valueListenable: date,
            builder: (context, val, child) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat(format).format(val),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? widget.activeTextColor
                            : widget.textColor?.withOpacity(0.9),
                      ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
