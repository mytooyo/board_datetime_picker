import 'package:board_datetime_picker/src/options/board_item_option.dart';
import 'package:board_datetime_picker/src/ui/parts/calendar.dart';
import 'package:board_datetime_picker/src/ui/parts/during_calendar.dart';
import 'package:board_datetime_picker/src/ui/parts/item.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import '../board_datetime_options.dart';
import '../utils/board_enum.dart';
import 'parts/buttons.dart';
import 'parts/calendar_multi.dart';
import 'parts/header.dart';

class PickerCalendarArgs {
  final ValueNotifier<DateTime> dateState;
  final BoardDateTimeOptions options;
  final DateTimePickerType pickerType;
  final List<BoardPickerItemOption> listOptions;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final Widget Function(BuildContext) headerBuilder;
  final void Function(DateTime) onChange;
  final void Function(BoardPickerItemOption, int) onChangeByPicker;
  final double Function() keyboardHeightRatio;
  final bool multiple;
  final ValueNotifier<DateTime>? startDate;
  final ValueNotifier<DateTime>? endDate;
  final void Function(DateTime start, DateTime end)? onMultiChange;
  final void Function(MultiCurrentDateType)? onChangeDateType;
  final void Function() onKeyboadClose;

  const PickerCalendarArgs({
    required this.dateState,
    required this.options,
    required this.pickerType,
    required this.listOptions,
    required this.minimumDate,
    required this.maximumDate,
    required this.headerBuilder,
    required this.onChange,
    required this.onChangeByPicker,
    required this.keyboardHeightRatio,
    required this.multiple,
    this.startDate,
    this.endDate,
    this.onMultiChange,
    this.onChangeDateType,
    required this.onKeyboadClose,
  });
}

abstract class PickerCalendarWidget extends StatefulWidget {
  const PickerCalendarWidget({
    super.key,
    required this.arguments,
  });

  final PickerCalendarArgs arguments;
}

abstract class PickerCalendarState<T extends PickerCalendarWidget>
    extends State<T> {
  final GlobalKey calendarKey = GlobalKey();

  final double keyboardMenuMaxHeight = 48;

  double get keyboardMenuHeight =>
      keyboardMenuMaxHeight * (1 - args.keyboardHeightRatio());

  PickerCalendarArgs get args => widget.arguments;

  Widget calendar({required Color? background, required bool isWide}) {
    if (args.multiple) {
      return SizedBox(
        child: MultipleCalendarWidget(
          key: calendarKey,
          startDate: args.startDate!,
          endDate: args.endDate!,
          onChange: (start, end) {
            args.onMultiChange?.call(start, end);
          },
          boxDecoration: BoxDecoration(
            color: args.options.backgroundDecoration != null && !isWide
                ? args.options.backgroundDecoration!.color
                : background,
          ),
          // onChange: args.onChange,
          wide: isWide,
          textColor: args.options.getTextColor(context),
          activeColor: args.options.getActiveColor(context),
          activeTextColor: args.options.getActiveTextColor(context),
          languages: args.options.languages,
          minimumDate: args.minimumDate ?? DateTimeUtil.defaultMinDate,
          maximumDate: args.maximumDate ?? DateTimeUtil.defaultMaxDate,
          startDayOfWeek: args.options.startDayOfWeek,
          weekend: args.options.weekend ?? const BoardPickerWeekendOptions(),
          onChangeDateType: args.onChangeDateType!,
          calendarSelectionBuilder: args.options.calendarSelectionBuilder,
          calendarSelectionRadius: args.options.calendarSelectionRadius,
        ),
      );
    }

    return SizedBox(
      child: SingleCalendarWidget(
        key: calendarKey,
        dateState: args.dateState,
        boxDecoration: BoxDecoration(
          color: args.options.backgroundDecoration != null && !isWide
              ? args.options.backgroundDecoration!.color
              : background,
        ),
        onChange: args.onChange,
        wide: isWide,
        textColor: args.options.getTextColor(context),
        activeColor: args.options.getActiveColor(context),
        activeTextColor: args.options.getActiveTextColor(context),
        languages: args.options.languages,
        minimumDate: args.minimumDate ?? DateTimeUtil.defaultMinDate,
        maximumDate: args.maximumDate ?? DateTimeUtil.defaultMaxDate,
        startDayOfWeek: args.options.startDayOfWeek,
        weekend: args.options.weekend ?? const BoardPickerWeekendOptions(),
        calendarSelectionBuilder: args.options.calendarSelectionBuilder,
        calendarSelectionRadius: args.options.calendarSelectionRadius,
      ),
    );
  }

  Widget picker({required bool isWide}) {
    final items = args.listOptions.map(
      (x) {
        return Expanded(
          flex: x.flex,
          child: ItemWidget(
            key: x.stateKey,
            option: x,
            foregroundColor: args.options.getForegroundColor(context),
            textColor: args.options.getTextColor(context),
            onChange: (index) => args.onChangeByPicker(x, index),
            showedKeyboard: () {
              return args.keyboardHeightRatio() < 0.5;
            },
            wide: isWide,
            subTitle: x.subTitle,
            inputable: args.options.inputable,
          ),
        );
      },
    ).toList();

    return SizedBox(
      child: Align(
        alignment: Alignment.topCenter,
        child: Row(
          children: items,
        ),
      ),
    );
  }

  void moveFocus(bool next) {
    for (var i = 0; i < args.listOptions.length; i++) {
      final opt = args.listOptions[i];
      if (opt.focusNode.hasFocus) {
        int move = -1;
        if (next) {
          if (i != args.listOptions.length - 1) {
            move = i + 1;
          }
        } else {
          if (i != 0) {
            move = i - 1;
          }
        }
        if (move != -1) {
          args.listOptions[move].focusNode.requestFocus();
        }
        break;
      }
    }
  }

  Widget keyboardMenu({required bool isWide}) {
    return Container(
      decoration: BoxDecoration(
        color: args.options.getForegroundColor(context).withOpacity(0.9),
      ),
      height: keyboardMenuHeight,
      child: SingleChildScrollView(
        child: Container(
          height: keyboardMenuHeight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              CustomIconButton(
                icon: Icons.arrow_back_rounded,
                bgColor: args.options.getForegroundColor(context),
                fgColor: args.options.getTextColor(context)?.withOpacity(0.6),
                onTap: () => moveFocus(false),
                // buttonSize: buttonSize,
              ),
              const SizedBox(width: 8),
              CustomIconButton(
                icon: Icons.arrow_forward_rounded,
                bgColor: args.options.getForegroundColor(context),
                fgColor: args.options.getTextColor(context)?.withOpacity(0.6),
                onTap: () => moveFocus(true),
                // buttonSize: buttonSize,
              ),
              const Expanded(child: SizedBox()),
              CustomIconButton(
                icon: Icons.keyboard_hide_rounded,
                bgColor: args.options.getForegroundColor(context),
                fgColor: args.options.getTextColor(context)?.withOpacity(0.6),
                onTap: args.onKeyboadClose,
                // buttonSize: buttonSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PickerCalendarWideWidget extends PickerCalendarWidget {
  const PickerCalendarWideWidget({
    super.key,
    required super.arguments,
    required this.closeKeyboard,
  });

  final void Function() closeKeyboard;

  @override
  PickerCalendarState<PickerCalendarWideWidget> createState() =>
      _PickerCalendarWideWidgetState();
}

class _PickerCalendarWideWidgetState
    extends PickerCalendarState<PickerCalendarWideWidget> {
  @override
  Widget build(BuildContext context) {
    double height = args.pickerType == DateTimePickerType.time ? 240 : 304;

    Widget child = Row(
      children: [
        if (args.pickerType != DateTimePickerType.time) ...[
          _left(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            children: [
              args.headerBuilder(context),
              Expanded(child: picker(isWide: true)),
            ],
          ),
        ),
      ],
    );

    Widget wrap = child;
    if (args.options.isTopTitleHeader) {
      height += 40;
      wrap = Column(
        children: [
          TopTitleWidget(options: args.options),
          Expanded(child: child),
        ],
      );
    }

    return Container(
      height: height + args.keyboardHeightRatio() * 172,
      decoration: args.options.backgroundDecoration ??
          BoxDecoration(
            color: args.options.getBackgroundColor(context),
          ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: SafeArea(
        top: false,
        child: wrap,
      ),
    );
  }

  /// Items to be displayed on the left side in wide
  Widget _left() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: args.options.getForegroundColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: calendar(
              background: args.options.getForegroundColor(context),
              isWide: true,
            ),
          ),
          Positioned.fill(
            child: Visibility(
              visible: args.keyboardHeightRatio() < 0.5,
              child: DuringCalendarWidget(
                closeKeyboard: widget.closeKeyboard,
                backgroundColor: args.options.getForegroundColor(context),
                textColor: args.options.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PickerCalendarStandardWidget extends PickerCalendarWidget {
  const PickerCalendarStandardWidget({
    super.key,
    required super.arguments,
    required this.calendarAnimationController,
    required this.calendarAnimation,
    required this.pickerFormAnimation,
  });

  final AnimationController calendarAnimationController;
  final Animation<double> calendarAnimation;
  final Animation<double> pickerFormAnimation;

  @override
  PickerCalendarState<PickerCalendarStandardWidget> createState() =>
      _PickerCalendarStandardWidgetState();
}

class _PickerCalendarStandardWidgetState
    extends PickerCalendarState<PickerCalendarStandardWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.calendarAnimationController,
      builder: builder,
    );
  }

  Widget builder(BuildContext context, Widget? child) {
    double height = 200 + (220 * widget.calendarAnimation.value);

    if (args.options.isTopTitleHeader) {
      height += 40;
    }
    height += keyboardMenuHeight;

    return Container(
      height: height + (args.keyboardHeightRatio() * 172),
      decoration: args.options.backgroundDecoration ??
          BoxDecoration(
            color: args.options.getBackgroundColor(context),
          ),
      // padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (args.options.isTopTitleHeader)
                        TopTitleWidget(options: args.options),
                      args.headerBuilder(context),
                      Expanded(child: contents()),
                    ],
                  ),
                ),
              ),
              // Menu when keyboard is displayed
              keyboardMenu(isWide: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget contents() {
    return Stack(
      children: [
        Visibility(
          visible: widget.calendarAnimation.value != 0,
          child: FadeTransition(
            opacity: widget.calendarAnimation,
            child: calendar(
              background: args.options.getBackgroundColor(context),
              isWide: false,
            ),
          ),
        ),
        Visibility(
          visible: widget.calendarAnimation.value != 1,
          child: FadeTransition(
            opacity: widget.pickerFormAnimation,
            child: picker(isWide: false),
          ),
        ),
      ],
    );
  }
}
