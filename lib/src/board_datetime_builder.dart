import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/parts/calendar.dart';
import 'package:board_datetime_picker/src/parts/item.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import 'parts/during_calendar.dart';
import 'parts/header.dart';
import 'utils/board_enum.dart';
import 'utils/board_option.dart';

/// Controller for displaying, hiding, and updating the value of the picker
class BoardDateTimeController {
  // ignore: library_private_types_in_public_api
  final GlobalKey<_BoardDateTimeContentState> _key = GlobalKey();

  void open(DateTimePickerType openType, DateTime val) {
    _key.currentState?.open(val, openType);
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
      return _BoardDateTimeContent(
        builder: widget.builder,
        controller: widget.controller,
        onChange: widget.onChange,
        pickerType: widget.pickerType,
        initialDate: widget.initialDate,
        breakpoint: widget.breakpoint,
        options: widget.options ?? BoardDateTimeOptions(),
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

class _BoardDateTimeContent extends StatefulWidget {
  _BoardDateTimeContent({
    required this.builder,
    required this.controller,
    required this.onChange,
    this.pickerType = DateTimePickerType.datetime,
    this.initialDate,
    this.breakpoint = 800,
    required this.options,
  }) : super(key: controller._key);

  final DateTimeBuilderWidget builder;
  final BoardDateTimeController controller;
  final double breakpoint;
  final void Function(DateTime) onChange;
  final DateTime? initialDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;

  @override
  State<_BoardDateTimeContent> createState() => _BoardDateTimeContentState();
}

class _BoardDateTimeContentState extends State<_BoardDateTimeContent>
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
    _openAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    setupOptions(widget.initialDate ?? DateTime.now(), widget.pickerType);

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

  /// Open Picker
  void open(DateTime date, DateTimePickerType pickerType) {
    setState(() {
      setupOptions(date, pickerType);
    });

    // If the calendar was displayed in the time display specification, return it.
    if (pickerType == DateTimePickerType.time &&
        _calendarAnimationController.isCompleted) {
      _calendarAnimationController.reset();
    }

    _keyboardAnimationController.reset();
    _openAnimationController.forward();
  }

  /// Close Picker
  void close() {
    _openAnimationController.reverse();
  }

  /// Setup of field options
  void setupOptions(DateTime d, DateTimePickerType type) {
    options = [
      if ([DateTimePickerType.date, DateTimePickerType.datetime]
          .contains(type)) ...[
        BoardPickerItemOption.init(DateType.year, d),
        BoardPickerItemOption.init(DateType.month, d),
        BoardPickerItemOption.init(DateType.day, d),
      ],
      if ([DateTimePickerType.time, DateTimePickerType.datetime]
          .contains(type)) ...[
        BoardPickerItemOption.init(DateType.hour, d),
        BoardPickerItemOption.init(DateType.minute, d),
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
  void notify() => widget.onChange(dateState.value);

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
    final day = DateTimeUtil.getExistsDate(options, opt, index);
    if (day != null) {
      final dayOpt = options.firstWhere((x) => x.type == DateType.day);
      dayOpt.updateList(day);
      dateState.value = dayOpt.calcDate(dateState.value);
    }

    // Update option class values to selected values
    opt.selected = index;
    dateState.value = opt.calcDate(dateState.value);
  }

  /// Process date changes from calendar or header
  void changeDate(DateTime val) {
    for (final x in options) {
      if (x.type == DateType.year && x.selected != val.year) {
        x.changeDate(val);
      } else if (x.type == DateType.month && x.selected != val.month) {
        x.changeDate(val);
      } else if (x.type == DateType.day && x.selected != val.day) {
        x.changeDate(val);
      }
    }
    dateState.value = val;
  }

  /// Process time changes from header
  void changeTime(DateTime val) {
    for (final x in options) {
      if (x.type == DateType.hour && x.selected != val.hour) {
        x.changeDate(val);
      } else if (x.type == DateType.minute && x.selected != val.minute) {
        x.changeDate(val);
      }
    }
    dateState.value = val;
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
            (_keyboadAnimation.value * 140),
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
    );
  }
}
