import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../board_datetime_contents_state.dart';
import '../../board_datetime_options.dart';
import '../../utils/board_enum.dart';
import '../../utils/datetime_util.dart';

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
    required this.onTopActionBuilder,
    required this.onReset,
    required this.useAmpm,
    required this.customCloseButtonBuilder,
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

  /// Specify a Widget to be displayed in the action button area externally
  final Widget Function(BuildContext context)? onTopActionBuilder;

  /// reset button callback (if use reset)
  final void Function()? onReset;

  /// Flag whether AM/PM mode is used
  final bool useAmpm;

  /// Custom Close Button Builder
  final CloseButtonBuilder? customCloseButtonBuilder;

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

  Widget _defaultCloseButtonBuilder(
    BuildContext context,
    bool isModal,
    void Function() onClose,
  ) =>
      Container(
        width: 40,
        alignment: Alignment.center,
        child: isModal
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
              ),
      );

  @override
  Widget build(BuildContext context) {
    final onReset = widget.onReset;
    final topActionWidget = widget.onTopActionBuilder?.call(context);

    final closeButtonBuilder =
        widget.customCloseButtonBuilder ?? _defaultCloseButtonBuilder;
    final rightIcon = closeButtonBuilder(context, widget.modal, widget.onClose);

    final child = Container(
      height: widget.wide ? 64 : 52,
      margin: EdgeInsets.only(top: widget.topMargin, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.foregroundColor.withValues(alpha: 0.99),
      ),
      child: Row(
        children: [
          if (widget.pickerType != DateTimePickerType.time)
            _calendarButton()
          else
            SizedBox(width: onReset != null ? 8 : 40),
          if (topActionWidget == null) ...[
            Expanded(
              child: Align(
                alignment: onReset != null && !widget.wide
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                                width:
                                    dateItemWidth * startScaleAnimation.value,
                                height: 32 * startScaleAnimation.value,
                                child: _datetimeItem(
                                  widget.startDate,
                                  MultiCurrentDateType.start,
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
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
            ),
          ] else ...[
            Expanded(child: topActionWidget),
          ],
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
          GestureDetector(
            child: rightIcon,
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

  Widget _calendarButton() {
    if (widget.wide) {
      if (widget.onReset == null) {
        return const SizedBox(width: 40);
      } else {
        return const SizedBox(width: 80);
      }
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
      if (widget.useAmpm) {
        format = 'hh:mm';
      } else {
        format = 'HH:mm';
      }
    }

    return Material(
      color: selected
          ? widget.activeColor
          : widget.backgroundColor.withValues(alpha: 0.8),
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
              String prefix = '';
              if (widget.pickerType == DateTimePickerType.time &&
                  widget.useAmpm) {
                final ampmData = DateTimeUtil.ampmContrastMap[val.hour]!;
                prefix = '${ampmData.ampm.display} ';
              }
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$prefix${DateFormat(format).format(val)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? widget.activeTextColor
                            : widget.textColor?.withValues(alpha: 0.9),
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
