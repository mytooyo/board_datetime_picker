import 'dart:math';

import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'options/board_item_option.dart';
import 'ui/parts/header.dart';
import 'ui/picker_calendar_widget.dart';
import 'utils/board_enum.dart';

/// Controller for displaying, hiding, and updating the value of the picker
class BoardDateTimeController {
  // ignore: library_private_types_in_public_api
  final GlobalKey<_BoardDateTimeContentState> _key = GlobalKey();

  void open(DateTimePickerType openType, DateTime val) {
    _key.currentState?.open(date: val, pickerType: openType);
  }

  void openPicker({DateTimePickerType? openType, DateTime? date}) {
    _key.currentState?.open(date: date, pickerType: openType);
  }

  void close() {
    _key.currentState?.close();
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
class BoardDateTimeBuilder extends StatefulWidget {
  const BoardDateTimeBuilder({
    super.key,
    required this.builder,
    required this.controller,
    required this.onChange,
    this.pickerType = DateTimePickerType.datetime,
    this.initialDate,
    this.minimumDate,
    this.maximumDate,
    this.breakpoint = 800,
    this.options,
    this.resizeBottom = true,
  });

  /// #### [DateTimeBuilder] Builder
  final DateTimeBuilderWidget builder;

  /// [BoardDateTimeController] for Datetime picker
  final BoardDateTimeController controller;

  /// Breakpoints for determining wide and standard. Default is 800.
  final double breakpoint;

  /// #### Callback when date is changed.
  final void Function(DateTime) onChange;

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

  @override
  State<BoardDateTimeBuilder> createState() => _BoardDateTimeBuilderState();
}

class _BoardDateTimeBuilderState extends State<BoardDateTimeBuilder> {
  /// Variables to manage keyboard height
  ValueNotifier<double> keyboardHeightNotifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    keyboardHeightNotifier.value = MediaQuery.of(context).viewInsets.bottom;

    Widget child() {
      return BoardDateTimeContent(
        key: widget.controller._key,
        onChange: widget.onChange,
        pickerType: widget.pickerType,
        initialDate: widget.initialDate,
        minimumDate: widget.minimumDate,
        maximumDate: widget.maximumDate,
        breakpoint: widget.breakpoint,
        options: widget.options ?? const BoardDateTimeOptions(),
        keyboardHeightNotifier: keyboardHeightNotifier,
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

class BoardDateTimeContent extends StatefulWidget {
  const BoardDateTimeContent({
    super.key,
    required this.onChange,
    required this.pickerType,
    required this.initialDate,
    required this.minimumDate,
    required this.maximumDate,
    required this.breakpoint,
    required this.options,
    this.modal = false,
    this.onCloseModal,
    this.keyboardHeightNotifier,
  });

  final double breakpoint;
  final void Function(DateTime) onChange;
  final DateTime? initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;
  final ValueNotifier<double>? keyboardHeightNotifier;

  /// Flag whether modal display is performed
  final bool modal;

  /// Callback for closing a modal
  final void Function()? onCloseModal;

  @override
  State<BoardDateTimeContent> createState() => _BoardDateTimeContentState();
}

class _BoardDateTimeContentState extends State<BoardDateTimeContent>
    with TickerProviderStateMixin {
  /// Controller to perform picker show/hide animation
  late AnimationController _openAnimationController;

  /// Animation to show/hide the calendar
  late AnimationController _calendarAnimationController;
  late Animation<double> _calendarAnimation;
  late Animation<double> _pickerFormAnimation;

  final GlobalKey<BoardDateTimeHeaderState> _headerKey = GlobalKey();

  /// Picker-wide Constraints
  late BoxConstraints _constraints;

  /// CurveTween
  final curve = CurveTween(curve: Curves.easeInOut);

  /// Wide mode flag
  bool get isWide => _constraints.maxWidth >= widget.breakpoint;

  /// DatePicker Field Options
  List<BoardPickerItemOption> itemOptions = [];
  late DateTimePickerType pickerType;

  /// [ValueNotifier] to manage the Datetime under selection
  late ValueNotifier<DateTime> dateState;

  /// Flag to keep track of whether the date has been updated
  /// in the Picker at least once.
  bool _changedDate = false;

  /// Date and time of initial display
  late DateTime initialDate;

  /// Variables to manage keyboard height
  late ValueNotifier<double> keyboardHeightNotifier;

  /// Get the value of the keyboard within your own class or
  bool get isSelfKeyboardNotifier => widget.keyboardHeightNotifier == null;

  @override
  void initState() {
    initializeDateFormatting();

    keyboardHeightNotifier = widget.keyboardHeightNotifier ?? ValueNotifier(0);

    _openAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.modal ? 1.0 : 0,
    );

    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _calendarAnimation = _calendarAnimationController.drive(curve).drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );
    _pickerFormAnimation = _calendarAnimationController.drive(curve).drive(
          Tween<double>(begin: 1.0, end: 0.0),
        );

    /// Set up options
    initialDate = widget.initialDate ?? DateTime.now();
    final d = rangeDate(initialDate);
    setupOptions(d, widget.pickerType);

    super.initState();
  }

  @override
  void dispose() {
    _openAnimationController.dispose();
    _calendarAnimationController.dispose();
    dateState.removeListener(notify);
    super.dispose();
  }

  /// Checks and corrects if the specified date is within range
  DateTime rangeDate(DateTime date) {
    DateTime d = date;
    if (widget.minimumDate != null && d.isBefore(widget.minimumDate!)) {
      d = widget.minimumDate!;
    }
    if (widget.maximumDate != null && d.isAfter(widget.maximumDate!)) {
      d = widget.maximumDate!;
    }
    return d;
  }

  /// Open Picker
  void open({DateTime? date, DateTimePickerType? pickerType}) {
    final d = rangeDate(date ?? dateState.value);
    final pt = pickerType ?? widget.pickerType;

    // Notification to match the date to be displayed
    // if the specified date differs from the date to be initially displayed.
    if (!_changedDate && d.compareTo(initialDate) != 0) {
      widget.onChange(widget.initialDate == null ? d : dateState.value);
    }

    setState(() {
      setupOptions(d, pt);
    });

    // If the calendar was displayed in the time display specification, return it.
    if (pt == DateTimePickerType.time &&
        _calendarAnimationController.isCompleted) {
      _calendarAnimationController.reset();
    }

    _openAnimationController.forward();
  }

  /// Close Picker
  void close() {
    if (widget.modal) {
      // if modal, close modal sheets
      if (widget.onCloseModal == null) {
        Navigator.of(context).pop();
      } else {
        widget.onCloseModal!.call();
      }
    } else {
      _openAnimationController.reverse();
    }
  }

  /// Setup of field options
  void setupOptions(DateTime d, DateTimePickerType type) {
    final minDate = widget.minimumDate;
    final maxDate = widget.maximumDate;

    final opts = widget.options.customOptions;

    List<BoardPickerItemOption> ymdOptions = [];

    if (DateTimePickerType.time != type) {
      // Check the value specified in the picker format.
      // Error if a value other than y, m, or d is specified
      final pickerFormat = widget.options.pickerFormat;
      final reg = RegExp('^(?=.*y)(?=.*m)(?=.*d)');
      assert(reg.hasMatch(pickerFormat));

      for (final pf in pickerFormat.characters) {
        if (pf == 'y') {
          final subTitle = widget.options.getSubTitle(DateType.year);
          ymdOptions.add(
            initItemOption(DateType.year, d, minDate, maxDate, null, subTitle),
          );
        } else if (pf == 'm') {
          final subTitle = widget.options.getSubTitle(DateType.month);
          ymdOptions.add(
            initItemOption(DateType.month, d, minDate, maxDate, null, subTitle),
          );
        } else if (pf == 'd') {
          final subTitle = widget.options.getSubTitle(DateType.day);
          ymdOptions.add(
            initItemOption(DateType.day, d, minDate, maxDate, null, subTitle),
          );
        }
      }
    }

    itemOptions = [
      if ([DateTimePickerType.date, DateTimePickerType.datetime].contains(type))
        ...ymdOptions,
      if ([DateTimePickerType.time, DateTimePickerType.datetime]
          .contains(type)) ...[
        initItemOption(
          DateType.hour,
          d,
          minDate,
          maxDate,
          opts?.hours,
          widget.options.getSubTitle(DateType.hour),
        ),
        initItemOption(
          DateType.minute,
          d,
          minDate,
          maxDate,
          opts?.minutes,
          widget.options.getSubTitle(DateType.minute),
        ),
      ],
    ];

    for (final x in itemOptions) {
      if (x.type == DateType.year) {
        x.focusNode.addListener(yearKeyboardListener);
      } else {
        x.focusNode.addListener(keyboardListener);
      }
    }

    pickerType = type;
    dateState = ValueNotifier(d);
    dateState.addListener(notify);
    _headerKey.currentState?.setup(dateState, rebuild: true);
  }

  /// Notification of change to caller.
  void notify() {
    for (var element in itemOptions) {
      element.updateList(dateState.value);
    }
    widget.onChange(dateState.value);
    _changedDate = true;
  }

  /// FocusNode (keyboard) listener
  void keyboardListener() {
    // empty
  }

  /// Year focusNode (keyboard) listener
  void yearKeyboardListener() {
    keyboardListener();
    // Checks the input when the focus is removed and changes to the year
    // and month of the current time if the value does not exist.
    final opt = itemOptions.firstWhere((x) => x.type == DateType.year);
    if (opt.focusNode.hasFocus) return;
    opt.checkInputField();
  }

  /// Handling of date changes made by the picker
  void onChangeByPicker(BoardPickerItemOption opt, int index) {
    // Update option class values to selected values
    opt.selectedIndex = index;
    DateTime newVal = opt.calcDate(dateState.value);

    final data = opt.map[index]!;
    final day = DateTimeUtil.getExistsDate(itemOptions, opt, data);
    if (day != null) {
      final dayOpt = itemOptions.firstWhere((x) => x.type == DateType.day);
      final newDate = dayOpt.calcDate(newVal);
      newVal = DateTimeUtil.rangeDate(
        newDate,
        widget.minimumDate,
        widget.maximumDate,
      );
      dayOpt.updateDayMap(day, newVal);
    } else {
      newVal = DateTimeUtil.rangeDate(
        newVal,
        widget.minimumDate,
        widget.maximumDate,
      );
    }
    dateState.value = opt.calcDate(newVal);
  }

  /// Process date changes from calendar or header
  void changeDate(DateTime val) {
    DateTime newVal = DateTimeUtil.rangeDate(
      val,
      widget.minimumDate,
      widget.maximumDate,
    );

    for (final x in itemOptions) {
      if (x.type == DateType.year && x.value != newVal.year) {
        x.changeDate(newVal);
      } else if (x.type == DateType.month && x.value != newVal.month) {
        x.changeDate(newVal);
      } else if (x.type == DateType.day && x.value != newVal.day) {
        x.changeDate(newVal);
      }
    }
    dateState.value = newVal;
  }

  /// Process time changes from header
  void changeTime(DateTime val) {
    DateTime newVal = DateTimeUtil.rangeDate(
      val,
      widget.minimumDate,
      widget.maximumDate,
    );

    for (final x in itemOptions) {
      if (x.type == DateType.hour && x.value != newVal.hour) {
        x.changeDate(newVal);
      } else if (x.type == DateType.minute && x.value != newVal.minute) {
        x.changeDate(newVal);
      }
    }
    dateState.value = newVal;
  }

  /// Close Keyboard
  void closeKeyboard() {
    for (final x in itemOptions) {
      if (x.focusNode.hasFocus) x.focusNode.unfocus();
    }
  }

  /// Ratio assuming a maximum keyboard height
  double get keyboardHeightRatio =>
      1 - (min(160, keyboardHeightNotifier.value) / 160);

  @override
  Widget build(BuildContext context) {
    if (isSelfKeyboardNotifier) {
      keyboardHeightNotifier.value = MediaQuery.of(context).viewInsets.bottom;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _constraints = constraints;

        return AnimatedBuilder(
          animation: _openAnimationController,
          builder: _openAnimationBuilder,
        );
      },
    );
  }

  Widget _openAnimationBuilder(BuildContext context, Widget? child) {
    final animation = _openAnimationController.drive(curve).drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );

    final args = PickerCalendarArgs(
      dateState: dateState,
      options: widget.options,
      pickerType: pickerType,
      listOptions: itemOptions,
      minimumDate: widget.minimumDate,
      maximumDate: widget.maximumDate,
      headerBuilder: (ctx) => _header,
      onChange: changeDate,
      onChangeByPicker: onChangeByPicker,
      keyboardHeightRatio: () => keyboardHeightRatio,
    );

    return Visibility(
      visible: animation.value != 0.0,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        axisAlignment: -1.0,
        // child: isWide ? _widebuilder() : _standardBuilder(),
        child: isWide
            ? PickerCalendarWideWidget(
                arguments: args,
                closeKeyboard: closeKeyboard,
              )
            : PickerCalendarStandardWidget(
                arguments: args,
                calendarAnimationController: _calendarAnimationController,
                calendarAnimation: _calendarAnimation,
                pickerFormAnimation: _pickerFormAnimation,
              ),
      ),
    );
  }

  Widget get _header {
    void onCalendar() {
      if (_calendarAnimationController.value == 0.0) {
        for (final x in itemOptions) {
          if (x.focusNode.hasFocus) {
            x.focusNode.unfocus();
          }
        }
        _calendarAnimationController.forward();
      } else if (_calendarAnimationController.value == 1.0) {
        _calendarAnimationController.reverse();
      }
    }

    if (!widget.options.showDateButton) {
      return BoardDateTimeNoneButtonHeader(
        options: widget.options,
        wide: isWide,
        dateState: dateState,
        pickerType: pickerType,
        keyboardHeightRatio: keyboardHeightRatio,
        calendarAnimation: _calendarAnimation,
        onCalendar: onCalendar,
        onKeyboadClose: closeKeyboard,
        onClose: close,
        modal: widget.modal,
      );
    }

    return BoardDateTimeHeader(
      key: _headerKey,
      wide: isWide,
      dateState: dateState,
      pickerType: pickerType,
      keyboardHeightRatio: keyboardHeightRatio,
      calendarAnimation: _calendarAnimation,
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
    );
  }
}
