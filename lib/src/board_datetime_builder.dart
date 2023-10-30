import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/parts/calendar.dart';
import 'package:board_datetime_picker/src/parts/item.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'options/board_option.dart';
import 'parts/during_calendar.dart';
import 'parts/header.dart';
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
  @override
  Widget build(BuildContext context) {
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
  });

  final double breakpoint;
  final void Function(DateTime) onChange;
  final DateTime? initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;

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

  /// Animation that detects and resizes the keyboard display
  late AnimationController _keyboardAnimationController;
  late Animation<double> _keyboadAnimation;

  /// Animation to show/hide the calendar
  late AnimationController _calendarAnimationController;
  late Animation<double> _calendarAnimation;
  late Animation<double> _pickerFormAnimation;

  final GlobalKey calendarKey = GlobalKey();
  final GlobalKey<BoardDateTimeHeaderState> _headerKey = GlobalKey();

  /// Picker-wide Constraints
  late BoxConstraints _constraints;

  /// CurveTween
  final curve = CurveTween(curve: Curves.easeInOut);

  /// Wide mode flag
  bool get isWide => _constraints.maxWidth >= widget.breakpoint;

  /// DatePicker Field Options
  List<BoardPickerItemOption> options = [];
  late DateTimePickerType pickerType;

  /// [ValueNotifier] to manage the Datetime under selection
  late ValueNotifier<DateTime> dateState;

  /// Flag to keep track of whether the date has been updated
  /// in the Picker at least once.
  bool _changedDate = false;

  /// Date and time of initial display
  late DateTime initialDate;

  // Color Schema
  Color get backgroundColor =>
      widget.options.backgroundColor ??
      Theme.of(context).scaffoldBackgroundColor;
  Color get foregroundColor =>
      widget.options.foregroundColor ?? Theme.of(context).cardColor;
  Color? get textColor =>
      widget.options.textColor ?? Theme.of(context).textTheme.bodyLarge?.color;
  Color get activeColor =>
      widget.options.activeColor ?? Theme.of(context).primaryColor;
  Color get activeTextColor => widget.options.activeTextColor ?? Colors.white;

  @override
  void initState() {
    initializeDateFormatting();

    _openAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.modal ? 1.0 : 0,
    );

    _keyboardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _keyboadAnimation = _keyboardAnimationController.drive(curve).drive(
          Tween<double>(begin: 1.0, end: 0.0),
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
    _keyboardAnimationController.dispose();
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

    _keyboardAnimationController.reset();
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
          ymdOptions.add(
            initItemOption(DateType.year, d, minDate, maxDate, null),
          );
        } else if (pf == 'm') {
          ymdOptions.add(
            initItemOption(DateType.month, d, minDate, maxDate, null),
          );
        } else if (pf == 'd') {
          ymdOptions.add(
            initItemOption(DateType.day, d, minDate, maxDate, null),
          );
        }
      }
    }

    options = [
      if ([DateTimePickerType.date, DateTimePickerType.datetime].contains(type))
        ...ymdOptions,
      if ([DateTimePickerType.time, DateTimePickerType.datetime]
          .contains(type)) ...[
        initItemOption(DateType.hour, d, minDate, maxDate, opts?.hours),
        initItemOption(DateType.minute, d, minDate, maxDate, opts?.minutes),
      ],
    ];

    for (final x in options) {
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
    for (var element in options) {
      element.updateList(dateState.value);
    }
    widget.onChange(dateState.value);
    _changedDate = true;
  }

  /// FocusNode (keyboard) listener
  void keyboardListener() {
    // Retrieve the field item in focus
    final opts = options.where((x) => x.focusNode.hasFocus).toList();

    // if not has focus
    if (opts.isEmpty && _keyboardAnimationController.isCompleted) {
      _keyboardAnimationController.reverse();
    } else if (opts.isNotEmpty && _keyboardAnimationController.value == 0.0) {
      _keyboardAnimationController.forward();
    }
  }

  /// Year focusNode (keyboard) listener
  void yearKeyboardListener() {
    keyboardListener();
    // Checks the input when the focus is removed and changes to the year
    // and month of the current time if the value does not exist.
    final opt = options.firstWhere((x) => x.type == DateType.year);
    if (opt.focusNode.hasFocus) return;
    opt.checkInputField();
  }

  /// Handling of date changes made by the picker
  void onChangeByPicker(BoardPickerItemOption opt, int index) {
    // Update option class values to selected values
    opt.selectedIndex = index;
    DateTime newVal = opt.calcDate(dateState.value);

    final data = opt.map[index]!;
    final day = DateTimeUtil.getExistsDate(options, opt, data);
    if (day != null) {
      final dayOpt = options.firstWhere((x) => x.type == DateType.day);
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

    for (final x in options) {
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

    for (final x in options) {
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
    for (final x in options) {
      if (x.focusNode.hasFocus) x.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return Visibility(
      visible: animation.value != 0.0,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        axisAlignment: -1.0,
        child: AnimatedBuilder(
          animation: _keyboardAnimationController,
          builder: isWide ? _widebuilder : _standardBuilder,
        ),
      ),
    );
  }

  /// Widget for wide size
  Widget _widebuilder(BuildContext context, Widget? child) {
    return Container(
      height: (pickerType == DateTimePickerType.time ? 240 : 328) +
          (_keyboadAnimation.value * 160),
      decoration: widget.options.backgroundDecoration ??
          BoxDecoration(
            color: backgroundColor,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (pickerType != DateTimePickerType.time) ...[
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: foregroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _calendar(
                        background: foregroundColor,
                      ),
                    ),
                    Positioned.fill(
                      child: Visibility(
                        visible: _keyboadAnimation.value < 0.5,
                        child: DuringCalendarWidget(
                          closeKeyboard: closeKeyboard,
                          backgroundColor: foregroundColor,
                          textColor: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                children: [
                  _header,
                  Expanded(child: _picker),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget for standard size
  Widget _standardBuilder(BuildContext context, Widget? child) {
    Widget contents() {
      return Stack(
        children: [
          Visibility(
            visible: _calendarAnimation.value != 0,
            child: FadeTransition(
              opacity: _calendarAnimation,
              child: _calendar(background: backgroundColor),
            ),
          ),
          Visibility(
            visible: _calendarAnimation.value != 1,
            child: FadeTransition(
              opacity: _pickerFormAnimation,
              child: _picker,
            ),
          ),
        ],
      );
    }

    Widget builder(BuildContext context, Widget? child) {
      return Container(
        height: 200 +
            (220 * _calendarAnimation.value) +
            (_keyboadAnimation.value * 160),
        decoration: widget.options.backgroundDecoration ??
            BoxDecoration(
              color: backgroundColor,
            ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                _header,
                Expanded(child: contents()),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _calendarAnimationController,
      builder: builder,
    );
  }

  Widget get _picker {
    final items = options.map(
      (x) {
        return Expanded(
          flex: x.flex,
          child: ItemWidget(
            key: x.stateKey,
            option: x,
            foregroundColor: foregroundColor,
            textColor: textColor,
            onChange: (index) => onChangeByPicker(x, index),
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

  Widget _calendar({Color? background}) {
    return SizedBox(
      child: CalendarWidget(
        key: calendarKey,
        dateState: dateState,
        boxDecoration: BoxDecoration(
          color: widget.options.backgroundDecoration != null && !isWide
              ? widget.options.backgroundDecoration!.color
              : background,
        ),
        onChange: changeDate,
        wide: isWide,
        textColor: textColor,
        activeColor: activeColor,
        activeTextColor: activeTextColor,
        languages: widget.options.languages,
        minimumDate: widget.minimumDate ?? DateTimeUtil.defaultMinDate,
        maximumDate: widget.maximumDate ?? DateTimeUtil.defaultMaxDate,
        startDayOfWeek: widget.options.startDayOfWeek,
      ),
    );
  }

  Widget get _header {
    return BoardDateTimeHeader(
      key: _headerKey,
      wide: isWide,
      dateState: dateState,
      pickerType: pickerType,
      keyboadAnimation: _keyboadAnimation,
      calendarAnimation: _calendarAnimation,
      onCalendar: () {
        if (_calendarAnimationController.value == 0.0) {
          for (final x in options) {
            if (x.focusNode.hasFocus) {
              x.focusNode.unfocus();
            }
          }
          _calendarAnimationController.forward();
        } else if (_calendarAnimationController.isCompleted) {
          _calendarAnimationController.reverse();
        }
      },
      onChangeDate: changeDate,
      onChangTime: changeTime,
      onKeyboadClose: closeKeyboard,
      onClose: close,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      textColor: textColor,
      activeColor: activeColor,
      activeTextColor: activeTextColor,
      languages: widget.options.languages,
      minimumDate: widget.minimumDate ?? DateTimeUtil.defaultMinDate,
      maximumDate: widget.maximumDate ?? DateTimeUtil.defaultMaxDate,
      modal: widget.modal,
    );
  }
}
