import 'dart:math';

import 'package:board_datetime_picker/src/utils/board_datetime_options_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../board_datetime_options.dart';
import '../options/board_item_option.dart';
import '../utils/board_datetime_result.dart';
import '../utils/board_enum.dart';
import '../utils/datetime_util.dart';

abstract class BoardDateTimeContent<T extends BoardDateTimeCommonResult>
    extends StatefulWidget {
  const BoardDateTimeContent({
    super.key,
    required this.pickerType,
    required this.minimumDate,
    required this.maximumDate,
    required this.breakpoint,
    required this.options,
    this.modal = false,
    this.withTextField = false,
    this.onCloseModal,
    this.keyboardHeightNotifier,
    this.onCreatedDateState,
    this.pickerFocusNode,
    this.onKeyboadClose,
  });

  final double breakpoint;

  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;
  final ValueNotifier<double>? keyboardHeightNotifier;

  /// Flag whether modal display is performed
  final bool modal;

  /// Flag indicating whether the text field is used as a Picker or not.
  final bool withTextField;

  /// Callback for closing a modal
  final void Function()? onCloseModal;

  final void Function(ValueNotifier<DateTime>)? onCreatedDateState;

  final FocusNode? pickerFocusNode;

  final void Function()? onKeyboadClose;
}

abstract class BoardDatetimeContentState<T extends BoardDateTimeCommonResult,
        S extends BoardDateTimeContent<T>> extends State<S>
    with TickerProviderStateMixin {
  /// Controller to perform picker show/hide animation
  late AnimationController openAnimationController;

  /// Animation to show/hide the calendar
  late AnimationController calendarAnimationController;
  late Animation<double> calendarAnimation;
  late Animation<double> pickerFormAnimation;

  /// Picker-wide Constraints
  late BoxConstraints boxConstraints;

  /// CurveTween
  final curve = CurveTween(curve: Curves.easeInOut);

  /// Wide mode flag
  bool get isWide => boxConstraints.maxWidth >= widget.breakpoint;

  /// DatePicker Field Options
  List<BoardPickerItemOption> itemOptions = [];
  late DateTimePickerType pickerType;

  /// Flag to keep track of whether the date has been updated
  /// in the Picker at least once.
  bool changedDate = false;

  /// Date and time of initial display
  late DateTime initialDate;

  /// Variables to manage keyboard height
  late ValueNotifier<double> keyboardHeightNotifier;

  /// Get the value of the keyboard within your own class or
  bool get isSelfKeyboardNotifier => widget.keyboardHeightNotifier == null;

  /// Ratio assuming a maximum keyboard height
  double get keyboardHeightRatio =>
      1 - (min(172, keyboardHeightNotifier.value) / 172);

  /// Get the current date
  DateTime get currentDate;

  /// Get initial date (Specified initial date)
  DateTime? get defaultDate;

  DateTime? get minimumDate => widget.minimumDate;
  DateTime? get maximumDate => widget.maximumDate;

  /// Set new value
  void setNewValue(DateTime val, {bool byPicker = false});

  /// on change date and datetime result
  void onChanged(DateTime date, T result);

  /// Open Picker
  void open({DateTime? date, DateTimePickerType? pickerType}) {
    final d = rangeDate(date ?? currentDate);
    final pt = pickerType ?? widget.pickerType;

    // Notification to match the date to be displayed
    // if the specified date differs from the date to be initially displayed.
    if (!changedDate && d.compareTo(initialDate) != 0) {
      final result = defaultDate == null ? d : currentDate;
      onChanged(result, BoardDateTimeCommonResult.init(pt, result) as T);
    }

    setState(() {
      setupOptions(d, pt);
    });

    // If the calendar was displayed in the time display specification, return it.
    if (pt == DateTimePickerType.time &&
        calendarAnimationController.isCompleted) {
      calendarAnimationController.reset();
    }

    openAnimationController.forward();
  }

  /// Close Picker
  void close() {
    if (widget.modal) {
      FocusScope.of(context).unfocus();
      // if modal, close modal sheets
      if (widget.onCloseModal == null) {
        Navigator.of(context).pop();
      } else {
        widget.onCloseModal!.call();
      }
    } else {
      openAnimationController.reverse();
    }
  }

  @override
  void initState() {
    initializeDateFormatting();

    keyboardHeightNotifier = widget.keyboardHeightNotifier ?? ValueNotifier(0);

    openAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.modal ? 1.0 : 0,
    );

    calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    calendarAnimation = calendarAnimationController.drive(curve).drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );
    pickerFormAnimation = calendarAnimationController.drive(curve).drive(
          Tween<double>(begin: 1.0, end: 0.0),
        );

    /// Set up options
    initialDate = defaultDate ?? DateTime.now();
    final d = rangeDate(initialDate);
    setupOptions(d, widget.pickerType);

    super.initState();
  }

  @override
  void dispose() {
    openAnimationController.dispose();
    calendarAnimationController.dispose();
    super.dispose();
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

  /// Checks and corrects if the specified date is within range
  DateTime rangeDate(DateTime date) {
    DateTime d = date;
    if (minimumDate != null && d.isBefore(minimumDate!)) {
      d = minimumDate!;
    }
    if (maximumDate != null && d.isAfter(maximumDate!)) {
      d = maximumDate!;
    }
    return d;
  }

  /// Setup of field options
  void setupOptions(DateTime d, DateTimePickerType type) {
    final minDate = minimumDate;
    final maxDate = maximumDate;

    final opts = widget.options.customOptions;
    final withSecond = widget.options.withSecond;

    List<BoardPickerItemOption> ymdOptions = [];

    if (DateTimePickerType.time != type) {
      // Check the value specified in the picker format.
      // Error if a value other than y, m, or d is specified
      final pickerFormat = widget.options.pickerFormat;
      final reg = RegExp('^(?=.*y)(?=.*M)(?=.*d)');
      assert(reg.hasMatch(pickerFormat));

      for (final pf in pickerFormat.characters) {
        if (pf == 'y') {
          final subTitle = widget.options.getSubTitle(DateType.year);
          ymdOptions.add(
            initItemOption(
              DateType.year,
              d,
              minDate,
              maxDate,
              null,
              subTitle,
              withSecond,
            ),
          );
        } else if (pf == 'M') {
          final subTitle = widget.options.getSubTitle(DateType.month);
          ymdOptions.add(
            initItemOption(
              DateType.month,
              d,
              minDate,
              maxDate,
              null,
              subTitle,
              withSecond,
            ),
          );
        } else if (pf == 'd') {
          final subTitle = widget.options.getSubTitle(DateType.day);
          ymdOptions.add(
            initItemOption(
              DateType.day,
              d,
              minDate,
              maxDate,
              null,
              subTitle,
              withSecond,
            ),
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
          withSecond,
        ),
        initItemOption(
          DateType.minute,
          d,
          minDate,
          maxDate,
          opts?.minutes,
          widget.options.getSubTitle(DateType.minute),
          withSecond,
        ),
      ],
      if (DateTimePickerType.time == type && widget.options.withSecond)
        initItemOption(
          DateType.second,
          d,
          minDate,
          maxDate,
          opts?.seconds,
          widget.options.getSubTitle(DateType.second),
          withSecond,
        ),
    ];

    for (final x in itemOptions) {
      if (x.type == DateType.year) {
        x.focusNode.addListener(yearKeyboardListener);
      } else {
        x.focusNode.addListener(keyboardListener);
      }
    }

    pickerType = type;
  }

  /// Close Keyboard
  void closeKeyboard() {
    for (final x in itemOptions) {
      if (x.focusNode.hasFocus) x.focusNode.unfocus();
    }
    widget.onKeyboadClose?.call();
  }

  /// Handling of date changes made by the picker
  void onChangeByPicker(BoardPickerItemOption opt, int index) {
    // Update option class values to selected values
    opt.selectedIndex = index;

    // 年と月から選択中の日付が存在するか確認する
    // Check to see if the date you are selecting exists from the year and month
    DateTime newVal;
    if ([DateType.year, DateType.month].contains(opt.type)) {
      final year = opt.type == DateType.month ? currentDate.year : opt.value;
      final month = opt.type == DateType.month ? opt.value : currentDate.month;
      final day = currentDate.day;
      // 存在しない日付の場合は最大日付で補正する
      // Correct with the maximum date if the date does not exist
      final newDay = DateTimeUtil.existDay(year, month, day);
      // 範囲外の日付の場合に繰り上がってしまうため
      // ここで日付を指定してDateTimeを作成しておく
      // Because it is carried forward for dates outside the range,
      // create a DateTime with the date here.
      newVal = opt.calcDate(currentDate, newDay: newDay);
    } else {
      newVal = opt.calcDate(currentDate);
    }

    final data = opt.map[index]!;
    final day = DateTimeUtil.getExistsMaxDate(itemOptions, opt, data);
    if (day != null) {
      final dayOpt = itemOptions.firstWhere((x) => x.type == DateType.day);
      // 選択中の日付が最大値より大きい場合は最大値で補正する
      // If the date being selected is greater than the maximum value, correct by the maximum value.
      final newDate = dayOpt.calcDate(
        newVal,
        newDay: currentDate.day > day ? day : null,
      );
      newVal = DateTimeUtil.rangeDate(
        newDate,
        minimumDate,
        maximumDate,
      );
      dayOpt.updateDayMap(day, newVal);
    } else {
      newVal = DateTimeUtil.rangeDate(
        newVal,
        minimumDate,
        maximumDate,
      );
    }
    setNewValue(opt.calcDate(newVal));
  }

  /// Process date changes from calendar or header
  void changeDate(DateTime val) {
    DateTime newVal = DateTimeUtil.rangeDate(
      val,
      minimumDate,
      maximumDate,
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
    setNewValue(newVal);
  }

  /// Process time changes from header
  void changeTime(DateTime val) {
    DateTime newVal = DateTimeUtil.rangeDate(
      val,
      minimumDate,
      maximumDate,
    );

    for (final x in itemOptions) {
      if (x.type == DateType.hour && x.value != newVal.hour) {
        x.changeDate(newVal);
      } else if (x.type == DateType.minute && x.value != newVal.minute) {
        x.changeDate(newVal);
      } else if (x.type == DateType.second && x.value != newVal.second) {
        x.changeDate(newVal);
      }
    }
    setNewValue(newVal);
  }

  void changeDateTime(DateTime val) {
    DateTime newVal = DateTimeUtil.rangeDate(
      val,
      minimumDate,
      maximumDate,
    );

    for (final x in itemOptions) {
      if (x.type == DateType.year && x.value != newVal.year) {
        x.changeDate(newVal);
      } else if (x.type == DateType.month && x.value != newVal.month) {
        x.changeDate(newVal);
      } else if (x.type == DateType.day && x.value != newVal.day) {
        x.changeDate(newVal);
      } else if (x.type == DateType.hour && x.value != newVal.hour) {
        x.changeDate(newVal);
      } else if (x.type == DateType.minute && x.value != newVal.minute) {
        x.changeDate(newVal);
      } else if (x.type == DateType.second && x.value != newVal.second) {
        x.changeDate(newVal);
      }
    }
    setNewValue(newVal);
  }
}
