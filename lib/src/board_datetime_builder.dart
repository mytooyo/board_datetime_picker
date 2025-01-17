import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import 'ui/board_datetime_contents_state.dart';
import 'ui/parts/focus_node.dart';
import 'ui/parts/header.dart';
import 'ui/picker_calendar_widget.dart';
import 'utils/board_datetime_result.dart';
import 'utils/board_enum.dart';

/// Controller for displaying, hiding, and updating the value of the picker
class BoardDateTimeController {
  // ignore: library_private_types_in_public_api
  final GlobalKey<_SingleBoardDateTimeContentState> _key = GlobalKey();

  void open(DateTimePickerType openType, DateTime val) {
    _key.currentState?.open(date: val, pickerType: openType);
  }

  void openPicker({DateTimePickerType? openType, DateTime? date}) {
    _key.currentState?.open(date: date, pickerType: openType);
  }

  void close() {
    _key.currentState?.close();
  }

  /// Update the picker on the specified date
  void changeDate(DateTime val) {
    _key.currentState?.changeDate(val);
  }

  /// Update the picker on the specified time
  void changeTime(DateTime val) {
    _key.currentState?.changeTime(val);
  }

  /// Update the picker on the specified datetime
  void changeDateTime(DateTime val) {
    _key.currentState?.changeDateTime(val);
  }

  GlobalKey get boardKey => _key;
}

/// Controller for displaying, hiding, and updating the value of the picker
class SingleBoardDateTimeContentsController {
  // ignore: library_private_types_in_public_api
  final GlobalKey<_SingleBoardDateTimeContentState> key = GlobalKey();

  void changeDate(DateTime date) {
    key.currentState?.changeDateTime(date);
  }
}

typedef DateTimeBuilderWidget = Widget Function(BuildContext context);

/// ### BoardDateTimeBuilder
///
/// Display the Date picker like a keyboard at the bottom of the page.
/// Provide picker with text input and scrolling.
///
/// If the size exceeds the breakpoint, the calendar is displayed
/// on the left side and the picker on the right side.
/// if the size is smaller than the breakpoint, the default is to display the picker,
/// and the display is switched between the calendar and the buttons.
/// Only the picker can be selected while the keyboard is displayed,
/// and the calendar can be selected only while the keyboard is not displayed.
///
/// Example:
/// ```dart
/// final controller = BoardDateTimeController();
///
/// @override
/// Widget build(BuildContext context) {
///   return BoardDateTimeBuilder(
///     controller: controller,
///     builder: (context, constraints) {
///       return Scaffold(
///         ...
///       );
///     },
///     onChange: (val) => setState(() => date = val),
///   );
/// }
///
/// void open() {
///   controller.open(DateTimePickerType.date, DateTime.now());
/// }
/// ```
class BoardDateTimeBuilder<T extends BoardDateTimeCommonResult>
    extends StatefulWidget {
  const BoardDateTimeBuilder({
    super.key,
    required this.builder,
    required this.controller,
    this.onChange,
    this.onResult,
    this.pickerType = DateTimePickerType.datetime,
    this.initialDate,
    this.minimumDate,
    this.maximumDate,
    this.breakpoint = 800,
    this.options,
    this.resizeBottom = true,
    this.headerWidget,
    this.onTopActionBuilder,
    this.customCloseButtonBuilder,
  });

  /// #### [DateTimeBuilder] Builder
  final DateTimeBuilderWidget builder;

  /// [BoardDateTimeController] for Datetime picker
  final BoardDateTimeController controller;

  /// Breakpoints for determining wide and standard. Default is 800.
  final double breakpoint;

  /// #### Callback when date is changed.
  final void Function(DateTime)? onChange;

  /// Callback to allow each value to be retrieved separately,
  /// rather than having the result of the change be of type DateTime
  final void Function(T)? onResult;

  /// #### Date of initial selection state.
  final DateTime? initialDate;

  /// #### Minimum selectable dates
  final DateTime? minimumDate;

  /// #### Maximum selectable dates
  final DateTime? maximumDate;

  /// #### Display picker type.
  final DateTimePickerType pickerType;

  /// Class for defining options related to the UI used by [BoardDateTimeBuilder]
  final BoardDateTimeOptions? options;

  /// Flag whether to resize the bottom of the specified Builder.
  /// If true, the picker is displayed under the builder in `Column`.
  final bool resizeBottom;

  /// This widget should be displayed above the picker.
  final Widget? headerWidget;

  /// Specify a Widget to be displayed in the action button area externally
  final Widget Function(BuildContext context)? onTopActionBuilder;

  final CloseButtonBuilder? customCloseButtonBuilder;

  @override
  State<BoardDateTimeBuilder> createState() => _BoardDateTimeBuilderState<T>();
}

class _BoardDateTimeBuilderState<T extends BoardDateTimeCommonResult>
    extends State<BoardDateTimeBuilder<T>> {
  /// Variables to manage keyboard height
  ValueNotifier<double> keyboardHeightNotifier = ValueNotifier(0);

  @override
  void initState() {
    assert(() {
      if (T.toString() != "BoardDateTimeCommonResult") {
        void throwInvalidType() {
          throw Exception('Oops..Type and type do not match.: ${T.toString()}');
        }

        // Perform type checks
        if (widget.pickerType == DateTimePickerType.datetime) {
          if (T.toString() != "BoardDateTimeResult") throwInvalidType();
        } else if (widget.pickerType == DateTimePickerType.date) {
          if (T.toString() != "BoardDateResult") throwInvalidType();
        } else if (widget.pickerType == DateTimePickerType.time) {
          if (T.toString() != "BoardTimeResult") throwInvalidType();
        }
      }
      return true;
    }());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    keyboardHeightNotifier.value = MediaQuery.of(context).viewInsets.bottom;

    Widget child() {
      return SingleBoardDateTimeContent<T>(
        key: widget.controller.boardKey,
        onChange: widget.onChange,
        onResult: widget.onResult,
        pickerType: widget.pickerType,
        initialDate: widget.initialDate,
        minimumDate: widget.minimumDate,
        maximumDate: widget.maximumDate,
        breakpoint: widget.breakpoint,
        options: widget.options ?? const BoardDateTimeOptions(),
        keyboardHeightNotifier: keyboardHeightNotifier,
        headerWidget: widget.headerWidget,
        onTopActionBuilder: widget.onTopActionBuilder,
      );
    }

    if (widget.resizeBottom) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [Expanded(child: widget.builder(context)), child()],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: widget.builder(context)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: child(),
            ),
          ],
        ),
      );
    }
  }
}

class SingleBoardDateTimeContent<T extends BoardDateTimeCommonResult>
    extends BoardDateTimeContent<T> {
  const SingleBoardDateTimeContent({
    super.key,
    this.onChange,
    this.onResult,
    required super.pickerType,
    required this.initialDate,
    required super.minimumDate,
    required super.maximumDate,
    required super.breakpoint,
    required super.options,
    super.modal = false,
    super.withTextField = false,
    super.onCloseModal,
    super.keyboardHeightNotifier,
    super.onCreatedDateState,
    super.pickerFocusNode,
    super.onKeyboadClose,
    super.onUpdateByClose,
    required super.headerWidget,
    required super.onTopActionBuilder,
    super.customCloseButtonBuilder,
  });

  final void Function(DateTime)? onChange;
  final void Function(T)? onResult;

  final DateTime? initialDate;

  @override
  State<SingleBoardDateTimeContent> createState() =>
      _SingleBoardDateTimeContentState<T>();
}

class _SingleBoardDateTimeContentState<T extends BoardDateTimeCommonResult>
    extends BoardDatetimeContentState<T, SingleBoardDateTimeContent<T>> {
  /// [ValueNotifier] to manage the Datetime under selection
  late ValueNotifier<DateTime> dateState;

  final GlobalKey<BoardDateTimeHeaderState> _headerKey = GlobalKey();

  @override
  DateTime get currentDate => dateState.value;

  @override
  DateTime? get defaultDate => widget.initialDate;

  @override
  void dispose() {
    dateState.removeListener(notify);
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
    dateState.value = val;
    _setFocusNode(byPicker);
  }

  @override
  void onChanged(DateTime date, T result) {
    widget.onChange?.call(date);
    widget.onResult?.call(result);
  }

  @override
  void setupOptions(DateTime d, DateTimePickerType type) {
    super.setupOptions(d, type);
    dateState = ValueNotifier(d);
    dateState.addListener(notify);
    widget.onCreatedDateState?.call(dateState);
    _headerKey.currentState?.setup(dateState, rebuild: true);
  }

  /// Notification of change to caller.
  void notify() {
    for (var element in itemOptions) {
      element.updateList(dateState.value);
    }
    widget.onChange?.call(dateState.value);
    widget.onResult?.call(
      BoardDateTimeCommonResult.init(pickerType, dateState.value) as T,
    );
    changedDate = true;
  }

  /// Reset date.
  /// During this process, re-register the Listener to avoid sending unnecessary notifications.
  void reset() {
    dateState.removeListener(notify);
    dateState.value = defaultDate ?? DateTime.now();
    changeDateTime(dateState.value);
    dateState.addListener(notify);

    notify();
    _setFocusNode(false);
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
      dateState: dateState,
      options: widget.options,
      pickerType: pickerType,
      listOptions: itemOptions,
      minimumDate: widget.minimumDate,
      maximumDate: widget.maximumDate,
      multiple: false,
      headerBuilder: (ctx) => _header,
      onChangeByCalendar: changeDate,
      onChangeByPicker: onChangeByPicker,
      onKeyboadClose: closeKeyboard,
      keyboardHeightRatio: () => keyboardHeightRatio,
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

  Widget get _header {
    void onCalendar() {
      if (calendarAnimationController.value == 0.0) {
        for (final x in itemOptions) {
          if (x.focusNode.hasFocus) {
            x.focusNode.unfocus();
          }
        }
        calendarAnimationController.forward();
      } else if (calendarAnimationController.value == 1.0) {
        calendarAnimationController.reverse();
      }
    }

    if (!widget.options.showDateButton) {
      return BoardDateTimeNoneButtonHeader(
        options: widget.options,
        wide: isWide,
        dateState: dateState,
        pickerType: pickerType,
        keyboardHeightRatio: keyboardHeightRatio,
        calendarAnimation: calendarAnimation,
        onCalendar: onCalendar,
        onKeyboadClose: closeKeyboard,
        onClose: close,
        modal: widget.modal,
        pickerFocusNode: widget.pickerFocusNode,
      );
    }

    return BoardDateTimeHeader(
      key: _headerKey,
      wide: isWide,
      dateState: dateState,
      pickerType: pickerType,
      keyboardHeightRatio: keyboardHeightRatio,
      calendarAnimation: calendarAnimation,
      onCalendar: onCalendar,
      onChangeDate: changeDate,
      onChangTime: changeTime,
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
      withTextField: widget.withTextField,
      pickerFocusNode: widget.pickerFocusNode,
      topMargin: widget.options.topMargin,
      onTopActionBuilder: widget.onTopActionBuilder,
      actionButtonTypes: widget.options.actionButtonTypes,
      onReset: widget.options.useResetButton ? reset : null,
      customCloseButtonBuilder: widget.customCloseButtonBuilder,
    );
  }
}
