import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:board_datetime_picker/src/ui/board_datetime_contents_state.dart';
import 'package:board_datetime_picker/src/ui/picker_calendar_widget.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'ui/parts/header_multi.dart';

class BoardMultiDateTimeController extends BoardDateTimeController {
  // ignore: library_private_types_in_public_api
  final GlobalKey<_MultiBoardDateTimeContentState> _key = GlobalKey();

  @override
  GlobalKey get boardKey => _key;

  void changeValue(DateTime date, MultiCurrentDateType dateType) {
    _key.currentState?.changeMultiDate(date, dateType);
  }
}

class MultiBoardDateTimeContent<T extends BoardDateTimeCommonResult>
    extends BoardDateTimeContent<T> {
  const MultiBoardDateTimeContent({
    super.key,
    this.controller,
    required super.pickerType,
    required this.startDate,
    required this.endDate,
    required super.minimumDate,
    required super.maximumDate,
    required super.breakpoint,
    required super.options,
    super.modal = false,
    super.onCloseModal,
    super.keyboardHeightNotifier,
    super.onCreatedDateState,
    super.pickerFocusNode,
    super.onKeyboadClose,
    super.onUpdateByClose,
    this.onChange,
    this.onResult,
    required super.headerWidget,
    required super.onTopActionBuilder,
    required super.confirmButton,
  });

  final BoardMultiDateTimeController? controller;
  final DateTime startDate;
  final DateTime endDate;

  final void Function(DateTime start, DateTime end)? onChange;
  final void Function(T, T)? onResult;

  @override
  State<MultiBoardDateTimeContent> createState() =>
      _MultiBoardDateTimeContentState<T>();
}

class _MultiBoardDateTimeContentState<T extends BoardDateTimeCommonResult>
    extends BoardDatetimeContentState<T, MultiBoardDateTimeContent<T>> {
  final currentDateType = ValueNotifier(MultiCurrentDateType.start);

  late ValueNotifier<DateTime> startDate;
  late ValueNotifier<DateTime> endDate;

  @override
  DateTime get currentDate =>
      currentDateType.value == MultiCurrentDateType.start
          ? startDate.value
          : endDate.value;

  @override
  DateTime? get defaultDate => widget.startDate;

  @override
  DateTime? get minimumDate {
    if (widget.pickerType == DateTimePickerType.time) {
      final now = DateTime.now();
      if (currentDateType.value == MultiCurrentDateType.end) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          startDate.value.hour,
          startDate.value.minute,
          startDate.value.second,
        );
      }
      return DateTime(
        now.year,
        now.month,
        now.day,
        widget.minimumDate?.hour ?? 0,
        widget.minimumDate?.minute ?? 0,
        widget.minimumDate?.second ?? 0,
      );
    } else {
      if (currentDateType.value == MultiCurrentDateType.end) {
        return startDate.value;
      }
      return widget.minimumDate;
    }
  }

  @override
  DateTime? get maximumDate {
    if (widget.pickerType == DateTimePickerType.time) {
      final now = DateTime.now();
      if (currentDateType.value == MultiCurrentDateType.start) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          endDate.value.hour,
          endDate.value.minute,
          endDate.value.second,
        );
      }
      return DateTime(
        now.year,
        now.month,
        now.day,
        widget.maximumDate?.hour ?? 23,
        widget.maximumDate?.minute ?? 59,
        widget.maximumDate?.second ?? 59,
      );
    } else {
      if (currentDateType.value == MultiCurrentDateType.start) {
        return endDate.value;
      }
      return widget.maximumDate;
    }
  }

  @override
  void initState() {
    startDate = ValueNotifier(widget.startDate);
    endDate = ValueNotifier(widget.endDate);

    startDate.addListener(notify);
    endDate.addListener(notify);

    super.initState();
  }

  @override
  void dispose() {
    startDate.removeListener(notify);
    endDate.removeListener(notify);
    super.dispose();
  }

  void _setFocusNode(bool byPicker) {
    if (byPicker && widget.pickerFocusNode != null) {
      final fn = widget.pickerFocusNode!;
      if (!fn.hasFocus &&
          FocusManager.instance.primaryFocus! is! BoardDateTimeInputFocusNode) {
        fn.requestFocus();
      }
    }
  }

  @override
  void setNewValue(DateTime val, {bool byPicker = false}) {
    changeMultiDate(val, currentDateType.value, byPicker: byPicker);
  }

  @override
  void onChanged(DateTime date, T result) {}

  void changeMultiDate(
    DateTime val,
    MultiCurrentDateType type, {
    bool byPicker = false,
  }) {
    if (type == MultiCurrentDateType.start) {
      // 同一の値の場合はステート更新のみ実施する(notifyが動かないため)
      if (startDate.value == val) {
        notify();
      }

      startDate.value = val;
    } else {
      // 同一の値の場合はステート更新のみ実施する(notifyが動かないため)
      if (endDate.value == val) {
        notify();
      }

      endDate.value = val;
    }
    _setFocusNode(byPicker);
  }

  /// Notification of change to caller.
  void notify() {
    for (var element in itemOptions) {
      element.updateList(currentDateType.value == MultiCurrentDateType.start
          ? startDate.value
          : endDate.value);
    }
    widget.onChange?.call(startDate.value, endDate.value);
    widget.onResult?.call(
      BoardDateTimeCommonResult.init(pickerType, startDate.value) as T,
      BoardDateTimeCommonResult.init(pickerType, endDate.value) as T,
    );
    changedDate = true;
  }

  /// Reset the start and end dates.
  /// During this process, re-register the Listener to avoid sending unnecessary notifications.
  void reset() {
    startDate.removeListener(notify);
    endDate.removeListener(notify);

    startDate.value = widget.startDate;
    endDate.value = widget.endDate;
    changeDateTime(
      currentDateType.value == MultiCurrentDateType.start
          ? startDate.value
          : endDate.value,
    );

    startDate.addListener(notify);
    endDate.addListener(notify);

    notify();
    _setFocusNode(false);
  }

  /// Set initial value at close
  @override
  void notifyInitialValue() {
    // If the close button is pressed without ever changing the date,
    // the default date is set once
    if (!changedDate) {
      widget.onUpdateByClose?.call(
        rangeDate(startDate.value),
        rangeDate(endDate.value),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSelfKeyboardNotifier) {
      keyboardHeightNotifier.value = MediaQuery.of(context).viewInsets.bottom;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        boxConstraints = constraints;

        return AnimatedBuilder(
          animation: openAnimationController,
          builder: _openAnimationBuilder,
        );
      },
    );
  }

  Widget _openAnimationBuilder(BuildContext context, Widget? child) {
    final animation = openAnimationController.drive(curve).drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );

    final args = PickerCalendarArgs(
      dateState: startDate,
      options: widget.options,
      pickerType: pickerType,
      listOptions: itemOptions,
      minimumDate: widget.minimumDate,
      maximumDate: widget.maximumDate,
      multiple: true,
      headerBuilder: (ctx) => _header,
      onChangeByCalendar: changeDate,
      onChangeByPicker: onChangeByPicker,
      onKeyboadClose: closeKeyboard,
      keyboardHeightRatio: () => keyboardHeightRatio,
      startDate: startDate,
      endDate: endDate,
      onMultiChange: (start, end) {
        startDate.value = start;
        endDate.value = end;
        _setFocusNode(false);
      },
      onChangeDateType: onChangeDateType,
    );

    return Visibility(
      visible: animation.value != 0.0,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        axisAlignment: -1.0,
        // child: isWide ? _widebuilder() : _standardBuilder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.headerWidget != null) widget.headerWidget!,
            isWide
                ? PickerCalendarWideWidget(
                    arguments: args,
                    closeKeyboard: closeKeyboard,
                  )
                : PickerCalendarStandardWidget(
                    arguments: args,
                    calendarAnimationController: calendarAnimationController,
                    calendarAnimation: calendarAnimation,
                    pickerFormAnimation: pickerFormAnimation,
                  ),
          ],
        ),
      ),
    );
  }

  void onChangeDateType(MultiCurrentDateType val) {
    currentDateType.value = val;
    setState(() {
      setupOptions(
        currentDateType.value == MultiCurrentDateType.start
            ? startDate.value
            : endDate.value,
        widget.pickerType,
      );
    });
  }

  Widget get _header {
    void onCalendar() {
      if (calendarAnimationController.value == 0.0) {
        for (final x in itemOptions) {
          if (x.focusNode.hasFocus) {
            x.focusNode.unfocus();
          }
        }
        calendarAnimationController.forward();
        // Change DateType to start if you want to display a calendar
        onChangeDateType(MultiCurrentDateType.start);
      } else if (calendarAnimationController.value == 1.0) {
        calendarAnimationController.reverse();
      }
    }

    return BoardDateTimeMultiHeader(
      // key: _headerKey,
      wide: isWide,
      startDate: startDate,
      endDate: endDate,
      pickerType: pickerType,
      pickerFormat: widget.options.pickerFormat,
      keyboardHeightRatio: keyboardHeightRatio,
      calendarAnimation: calendarAnimation,
      onCalendar: onCalendar,
      onKeyboadClose: closeKeyboard,
      onClose: close,
      backgroundColor: widget.options.getBackgroundColor(context),
      foregroundColor: widget.options.getForegroundColor(context),
      textColor: widget.options.getTextColor(context),
      activeColor: widget.options.getActiveColor(context),
      activeTextColor: widget.options.getActiveTextColor(context),
      languages: widget.options.languages,
      minimumDate: widget.minimumDate ?? DateTimeUtil.defaultMinDate,
      maximumDate: widget.maximumDate ?? DateTimeUtil.defaultMaxDate,
      modal: widget.modal,
      withTextField: false,
      pickerFocusNode: widget.pickerFocusNode,
      currentDateType: currentDateType,
      onChangeDateType: onChangeDateType,
      topMargin: widget.options.topMargin,
      onTopActionBuilder: widget.onTopActionBuilder,
      confirmButton: widget.confirmButton ?? widget.options.confirmButton,
      onReset: widget.options.useResetButton ? reset : null,
      useAmpm: widget.options.useAmpm,
    );
  }
}
