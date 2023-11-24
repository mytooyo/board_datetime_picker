import 'package:board_datetime_picker/src/options/board_item_option.dart';
import 'package:board_datetime_picker/src/ui/parts/calendar.dart';
import 'package:board_datetime_picker/src/ui/parts/during_calendar.dart';
import 'package:board_datetime_picker/src/ui/parts/item.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import '../board_datetime_options.dart';
import '../utils/board_enum.dart';
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

  PickerCalendarArgs get args => widget.arguments;

  Widget calendar({required Color? background, required bool isWide}) {
    return SizedBox(
      child: CalendarWidget(
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
      height: height + args.keyboardHeightRatio() * 160,
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

    return Container(
      height: height + (args.keyboardHeightRatio() * 160),
      decoration: args.options.backgroundDecoration ??
          BoxDecoration(
            color: args.options.getBackgroundColor(context),
          ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              if (args.options.isTopTitleHeader)
                TopTitleWidget(options: args.options),
              args.headerBuilder(context),
              Expanded(child: contents()),
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
