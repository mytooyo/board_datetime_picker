import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../board_datetime_picker.dart';
import 'board_datetime_builder.dart';
import 'ui/parts/focus_node.dart';
import 'utils/board_enum.dart';
import 'utils/board_input_filed_utilities.dart';
import 'utils/datetime_util.dart';

typedef BoardDateTimeCustomValidator = String? Function(String);

/// Class for handling validation on error.
/// When an error occurs in checking when text is changed or when the focus is lost,
/// a function is called depending on the type of error.
class BoardDateTimeInputFieldValidators {
  /// Message for which the entered message is invalid
  final String Function(String)? onIllegalFormat;

  /// Error messages outside the specified date/time range
  final String Function(String)? onOutOfRange;

  /// Message in case of a required error
  final String? Function()? onRequired;

  /// This is specified when implementing custom validation.
  /// The validations are evaluated sequentially in a list format from top to bottom.
  /// If a validation error occurs, subsequent evaluations will not be performed.
  final List<BoardDateTimeCustomValidator> customValidators;

  /// Specify whether messages are displayed below text fields by default
  /// If true, an error message is displayed at the bottom of the field as in a normal TextFormField.
  final bool showMessage;

  const BoardDateTimeInputFieldValidators({
    this.onIllegalFormat,
    this.onOutOfRange,
    this.onRequired,
    this.showMessage = false,
    this.customValidators = const [],
  });

  String? _errorIllegal(String text) {
    return onIllegalFormat?.call(text) ??
        BoardDateTimeInputError.illegal.message;
  }

  String? _errorOutOfRange(String text) {
    return onOutOfRange?.call(text) ??
        BoardDateTimeInputError.outOfRange.message;
  }

  String? _errorRequired() {
    return onRequired?.call();
  }
}

class BoardDateTimeTextController {
  @protected
  final ValueNotifier<dynamic> _notifier = ValueNotifier(null);

  void setText(String text) {
    _notifier.value = _InoutValue.from(text);
  }

  void setDate(DateTime date) {
    _notifier.value = _InoutValue.from(date);
  }

  DateTime? _selectedDate;

  @protected
  void updateSelectedDate(DateTime? newDate) {
    _selectedDate = newDate;
  }

  DateTime? get selectedDate {
    return _selectedDate;
  }
}

class _InoutValue {
  final String? text;
  final DateTime? date;

  _InoutValue({this.text, this.date});

  factory _InoutValue.from(dynamic val) {
    if (val is String) {
      return _InoutValue(text: val);
    } else if (val is DateTime) {
      return _InoutValue(date: val);
    }
    return _InoutValue();
  }

  String formattedText(String format) {
    if (date != null) {
      return DateFormat(format).format(date!);
    } else if (text != null) {
      return text!;
    }
    return '';
  }
}

/// Picker type if text field has focus
enum BoardDateTimeFieldPickerType { standard, mini }

/// [BoardDateTimeInputField] is a widget for using text field and picker at the same time
///
/// It is a TextField with autocomplete and check functions.
/// An input field with the same functionality
/// as a regular TextFormField, but designed for date entry/selection
///
/// Parameters for TextFormField have been added,
/// but otherwise it is the same as the previous [BoardDateTimeBuilder].
///
/// Example:
/// ```dart
/// BoardDateTimeInputField(
///   controller: textController,
///   pickerType: DateTimePickerType.date,
///   options: const BoardDateTimeOptions(
///     languages: BoardPickerLanguages.en(),
///   ),
///   textStyle: Theme.of(context).textTheme.bodyMedium,
///   onChanged: (date) {
///     print('onchanged: $date');
///   },
///   onFocusChange: (val, date, text) {
///     print('on focus changed date: $val, $date, $text');
///   },
///   onResult: (p0) {
///     // print('on result: ${p0.hour}, ${p0.minute}');
/// },
///
/// ```
class BoardDateTimeInputField<T extends BoardDateTimeCommonResult>
    extends StatefulWidget {
  const BoardDateTimeInputField({
    super.key,
    this.controller,
    required this.options,
    this.pickerType = DateTimePickerType.datetime,
    required this.onChanged,
    this.onResult,
    this.validators = const BoardDateTimeInputFieldValidators(),
    this.onFocusChange,
    this.focusNode,
    this.initialDate,
    this.minimumDate,
    this.maximumDate,
    this.showPicker = true,
    this.showPickerType = BoardDateTimeFieldPickerType.standard,
    this.breakpoint = 800,
    this.delimiter = '/',
    this.keyboardType,
    this.textInputAction,
    this.textStyle,
    this.textAlign,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.decoration,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled,
    this.onTopActionBuilder,
  });

  /// #### Date of initial selection state.
  final DateTime? initialDate;

  /// #### Minimum selectable dates
  final DateTime? minimumDate;

  /// #### Maximum selectable dates
  final DateTime? maximumDate;

  /// #### Display picker type.
  final DateTimePickerType pickerType;

  /// Class for defining options related to the UI used by [BoardDateTimeBuilder]
  final BoardDateTimeOptions options;

  /// #### Callback when date is changed.
  final Function(DateTime date) onChanged;

  /// Callback to allow each value to be retrieved separately,
  /// rather than having the result of the change be of type DateTime
  final void Function(T)? onResult;

  /// Flag whether to display a Picker below when a text field is focused.
  /// If displayed, display in overlay format at the bottom of the screen
  final bool showPicker;

  /// Picker type if text field has focus.
  /// The default is `standard`, which displays the Picker at the bottom of the screen just like a normal Picker.
  /// If `mini` is specified, a small Picker will be displayed directly below the text field.
  final BoardDateTimeFieldPickerType showPickerType;

  /// Delimiter used to separate dates
  /// If a slash[-] is specified, it will look like this: `yyyy-MM-dd`
  /// However, the time delimiter is fixed to a colon[:] and cannot be changed
  final String delimiter;

  /// Set error messages when errors occur in validating against text fields
  /// If not specified, default error messages are displayed
  final BoardDateTimeInputFieldValidators validators;

  /// Callback when the focus state is changed for the corresponding TextField
  final void Function(bool, DateTime?, String)? onFocusChange;

  /// Controller for setting text externally
  /// Text in the feeler can be updated by calling the `setText` method
  final BoardDateTimeTextController? controller;

  /// Specify a Widget to be displayed in the action button area externally
  final Widget Function(BuildContext context)? onTopActionBuilder;

  final double breakpoint;

  // ************************************************************************
  // *
  // * All of the following are parameters to be used for a normal TextField
  // *
  // ************************************************************************

  final BoardDateTimeInputFocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final InputDecoration? decoration;
  final bool autofocus;
  final bool readOnly;
  final bool? enabled;

  @override
  State<BoardDateTimeInputField> createState() =>
      _BoardDateTimeInputFieldState<T>();
}

class _BoardDateTimeInputFieldState<T extends BoardDateTimeCommonResult>
    extends State<BoardDateTimeInputField<T>>
    with SingleTickerProviderStateMixin {
  /// Overlay Widget to display picker
  OverlayEntry? overlay;

  /// Key specified for Focus in TextFormField
  final GlobalKey<FormState> formKey = GlobalKey();

  /// Debounce timer for focus node monitoring
  Timer? focusNodeDebounce;

  SingleBoardDateTimeContentsController? pickerController;

  /// Overlay Animation Controller
  late AnimationController overlayAnimController;

  /// Input field controller
  late TextEditingController textController;

  /// FocusNodes
  late BoardDateTimeInputFocusNode focusNode;
  late PickerContentsFocusNode pickerFocusNode;

  /// Date formatting when displayed in input fields
  late String format;

  /// Format for Picker display
  late String pickerFormat;

  /// Specified minimum date
  late DateTime minimumDate;

  /// Specified maximum date
  late DateTime maximumDate;

  /// Date being selected and entered
  DateTime? selectedDate;

  /// ValueNotifier to work with Picker
  /// Monitor the value and apply it to the Field
  ValueNotifier<DateTime>? pickerDateState;

  BoardDateTimeOptions get options => widget.options;

  /// Number of characters before Field change
  int beforeTextLength = -1;

  /// Widget for use when an error occurs
  /// Basically, only Container is needed because we want to display Border.
  Widget? errorWidget;

  /// Variable to check if your own field is in focus
  bool focused = false;

  /// Target delimiter to be converted on input
  final List<String> delititers = ['/', ';', ':', ',', '.', '-', ' '];

  final BorderRadius borderRadius = BorderRadius.circular(8);

  int get textOffset => textController.selection.extent.offset;

  // Flag to see if you are focused on yourself
  bool? get focusIsSelf {
    final pf = FocusManager.instance.primaryFocus;

    // In the case of the text field itself, whether it is your own or not.
    if (pf is BoardDateTimeInputFocusNode) {
      return pf == focusNode;
    }
    // Whether the focus of the Picker is what you yourself are displaying
    if (pf is PickerContentsFocusNode) {
      return pf == pickerFocusNode;
    }
    return null;
  }

  /// Close the displayed picker
  void closePicker({bool disposed = false, void Function()? completion}) {
    if (disposed) {
      overlay?.remove();
      overlay?.dispose();
      overlay = null;
    } else {
      final future = overlayAnimController.reverse();
      if (overlay != null) {
        future.then((value) {
          overlay?.remove();
          overlay?.dispose();
          overlay = null;
          completion?.call();
        });
      }
    }
  }

  /// Function to monitor the FocusNode of
  /// a TextFormField and process any changes
  void _focusListener() {
    // Determine if it is your own focus
    if (focusIsSelf != null) {
      focused = focusIsSelf!;
    }

    if (!focusNode.hasFocus) {
      if (textController.text.isNotEmpty) {
        checkFormat(textController.text, complete: true);
      }

      // If the focus is out of focus, but the focus has moved to another InputField
      // never tapped on the textfield, but text selected or modified
      final pf = FocusManager.instance.primaryFocus;
      final focusList = pf?.children ?? [];
      final existsBdtFocusNode = focusList.any((x) =>
          x is BoardDateTimeInputFocusNode || x is PickerContentsFocusNode);
      if (!scopeListenerRegistered) {
        closePicker();
        onFinished();
      } else if (!existsBdtFocusNode && pf is! PickerContentsFocusNode) {
        closePicker();
        onFinished();
      }
    } else {
      // Callback when focus is acquired
      initialized = true;
      widget.onFocusChange?.call(true, selectedDate, textController.text);

      if (!widget.showPicker || overlay != null) return;
      pickerController = SingleBoardDateTimeContentsController();
      if (selectedDate != null) {
        pickerController!.changeDate(selectedDate!);
      }

      if (widget.showPickerType == BoardDateTimeFieldPickerType.standard) {
        overlay = _createPickerOverlay();
      } else {
        overlay = _createMiniPickerOverlay();
      }

      // Show DatePicker
      Overlay.of(context).insert(overlay!);
      overlayAnimController.forward();
    }
  }

  /// Listener to detect date and time changes in the picker
  void pickerListener() {
    final val = pickerDateState?.value;
    if (val != null) {
      void apply() {
        textController.text = DateFormat(format).format(val);
        if (selectedDate != val) {
          selectedDate = val;
          widget.controller?.updateSelectedDate(selectedDate);
          widget.onChanged(val);
          widget.onResult?.call(
            BoardDateTimeCommonResult.init(widget.pickerType, val) as T,
          );
        }
      }

      if (!focusNode.hasFocus) {
        apply();
      }
    }
  }

  bool initialized = false;

  void onFinished() {
    widget.onFocusChange?.call(false, selectedDate, textController.text);
    FocusScope.of(context).removeListener(_focusScopeListener);
    scopeListenerRegistered = false;
  }

  void _onFocused() {
    // Determine if it is your own focus
    if (focusIsSelf != null) {
      focused = focusIsSelf!;
    }
    final pf = FocusManager.instance.primaryFocus;
    if (pf is! BoardDateTimeInputFocusNode &&
        pf is! PickerItemFocusNode &&
        pf is! PickerContentsFocusNode &&
        pf is! PickerWheelItemFocusNode) {
      closePicker();
      if (initialized && focused) {
        checkFormat(textController.text, complete: true);
        onFinished();
        initialized = false;
      }
    }
  }

  bool scopeListenerRegistered = false;
  late final void Function() _focusScopeListener = focusScopeListener;

  void focusScopeListener() {
    focusNodeDebounce?.cancel();
    focusNodeDebounce = Timer(const Duration(milliseconds: 100), () {
      _onFocused();
    });
  }

  /// Checks and corrects if the specified date is within range
  DateTime rangeDate(DateTime date) {
    DateTime d = date;
    if (d.isBefore(minimumDate)) {
      d = minimumDate;
    }
    if (d.isAfter(maximumDate)) {
      d = maximumDate;
    }
    return d;
  }

  @override
  void initState() {
    bool withSecond = false;
    switch (widget.pickerType) {
      case DateTimePickerType.date:
        pickerFormat = options.pickerFormat;
        break;
      case DateTimePickerType.datetime:
        pickerFormat = '${options.pickerFormat}Hm';
        break;
      case DateTimePickerType.time:
        if (options.withSecond) {
          pickerFormat = 'Hms';
          withSecond = true;
        } else {
          pickerFormat = 'Hm';
        }

        break;
    }

    // TextFormat
    format = pickerFormat.dateFormat(widget.delimiter, withSecond);

    minimumDate = widget.minimumDate ?? DateTimeUtil.defaultMinDate;
    maximumDate = widget.maximumDate ?? DateTimeUtil.defaultMaxDate;

    DateTime? initial;
    if (widget.initialDate != null) {
      initial = rangeDate(widget.initialDate!);
      selectedDate = initial;
      widget.controller?.updateSelectedDate(selectedDate);
    }

    textController = TextEditingController(
      text: initial != null
          ? DateFormat(format).format(rangeDate(initial))
          : null,
    );
    textController.addListener(() {});

    pickerFocusNode = PickerContentsFocusNode(
      debugLabel: 'Picker Focus Node',
      skipTraversal: true,
    );
    focusNode = widget.focusNode ?? BoardDateTimeInputFocusNode();
    focusNode.addListener(_focusListener);

    overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 260),
    );

    widget.controller?._notifier.addListener(_controllerListener);

    super.initState();
  }

  void _controllerListener() {
    final setVal = widget.controller!._notifier.value;
    String newVal = '';

    if (setVal != null && setVal is _InoutValue) {
      newVal = setVal.formattedText(format);
    }

    if (newVal == textController.text) return;

    // 変更された場合に更新する
    checkFormat(newVal, complete: true);
  }

  @override
  void deactivate() {
    FocusScope.of(context).removeListener(_focusScopeListener);
    scopeListenerRegistered = false;
    super.deactivate();
  }

  @override
  void dispose() {
    focusNodeDebounce?.cancel();
    closePicker(disposed: true);
    focusNodeDebounce?.cancel();
    focusNode.removeListener(_focusListener);
    pickerDateState?.removeListener(pickerListener);
    textController.dispose();
    overlayAnimController.dispose();
    widget.controller?._notifier.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        controller: textController,
        focusNode: focusNode,
        keyboardType: widget.keyboardType ?? TextInputType.datetime,
        textInputAction: widget.textInputAction,
        style: widget.textStyle,
        textAlign: widget.textAlign ?? TextAlign.start,
        maxLines: 1,
        minLines: 1,
        autofocus: widget.autofocus,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        cursorRadius: widget.cursorRadius,
        cursorColor: widget.cursorColor ?? options.activeColor,
        decoration: widget.decoration ??
            InputDecoration(
              border: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: Colors.black,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: options.activeColor ?? Theme.of(context).primaryColor,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                ),
              ),
              errorMaxLines: 2,
              error: errorWidget,
            ),
        validator: widget.validators.showMessage
            ? (value) {
                if (value == null || value.isEmpty) {
                  return widget.validators._errorRequired();
                }

                final error = validate(
                  value,
                  complete: textController.text.length != textOffset ||
                      textOffset == format.length,
                ).error;

                if (error != null) {
                  switch (error) {
                    case BoardDateTimeInputError.illegal:
                      return widget.validators._errorIllegal(value);
                    case BoardDateTimeInputError.outOfRange:
                      return widget.validators._errorOutOfRange(value);
                  }
                }

                final customValidators = widget.validators.customValidators;
                if (customValidators.isNotEmpty) {
                  for (final validator in customValidators) {
                    final result = validator.call(value);
                    if (result != null) {
                      return result;
                    }
                  }
                }
                return null;
              }
            : null,
        inputFormatters: [
          LengthLimitingTextInputFormatter(format.length),
          FilteringTextInputFormatter.allow(
            RegExp(r'[0-9/;:,\-\s\.]'),
          )
        ],
        onTap: () {
          FocusScope.of(context).addListener(_focusScopeListener);
          scopeListenerRegistered = true;
        },
        onChanged: (val) {
          checkFormat(val);
          beforeTextLength = val.length;
        },
        onEditingComplete: () {
          closePicker();
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }

  ValidatorResult validate(String value, {bool complete = false}) {
    List<TextBloc> splited = [];

    //set null if text is empty
    if (value.isEmpty) {
      selectedDate = null;
      widget.controller?.updateSelectedDate(selectedDate);
    }

    String text = '';
    int start = 0;
    for (var i = 0; i < value.length; i++) {
      // In the case of a delimiter, the previous value is stored.
      if (delititers.contains(value[i])) {
        splited.add(
          TextBloc(
            text: text,
            start: start,
            end: i,
          ),
        );
        text = '';
      } else {
        if (text.isEmpty) start = i;
        text += value[i];
      }
    }
    splited.add(
      TextBloc(
        text: text,
        start: start,
        end: value.length,
      ),
    );

    BoardDateTimeInputError? retError;

    // Checks according to the specified format.
    for (var i = 0; i < pickerFormat.length; i++) {
      final f = pickerFormat[i];

      // Retrieve split data and perform checks.
      if (splited.length > i) {
        final data = splited[i];
        splited[i].dateType = f.dateType;

        // Error if the number of characters is larger than the specified number
        if (f.count < data.text.length) {
          selectedDate = null;
          widget.controller?.updateSelectedDate(selectedDate);
          return ValidatorResult(
            error: BoardDateTimeInputError.illegal,
            pickerType: widget.pickerType,
            withSecond: options.withSecond,
          );
        }

        BoardDateTimeInputError? check() {
          BoardDateTimeInputError? err;
          // Fill in zeros if not enough.
          final d = data.text.padLeft(f.count, '0');

          if (data.start <= textOffset && data.end >= textOffset && !complete) {
            return null;
          }
          // Conduct normal range checks.
          try {
            if (f == 'y') {
              final y = int.parse(data.text);
              if (!(minimumDate.year <= y && maximumDate.year >= y)) {
                err = BoardDateTimeInputError.outOfRange;
              }
            } else if (f == 'M') {
              final m = int.parse(data.text);
              if (!(m >= 1 && m <= 12)) {
                err = BoardDateTimeInputError.illegal;
              }
            } else if (f == 'd') {
              final m = int.parse(data.text);
              if (!(m >= 1 && m <= 31)) {
                err = BoardDateTimeInputError.illegal;
              }
            } else if (f == 'H') {
              final m = int.parse(data.text);
              if (!(m >= 0 && m <= 23)) {
                err = BoardDateTimeInputError.illegal;
              }
            } else if (f == 'm' || f == 's') {
              final m = int.parse(data.text);
              if (!(m >= 0 && m <= 59)) {
                err = BoardDateTimeInputError.illegal;
              }
            }
          } catch (ex) {
            if (complete) {
              selectedDate = null;
              widget.controller?.updateSelectedDate(selectedDate);
            }
            return err;
          }

          splited[i].text = d;
          return err;
        }

        // Corrects only if a delimiter is entered and the following data exists
        // However, if the block is being edited from the cursor position, it is not corrected.
        final isLast = splited.length == i + 1;
        // Handling errors for all values if the focus is off and the entire check
        if (complete) {
          retError ??= check();
        } else if (!isLast) {
          retError ??= check();
        }
      }
    }

    if (retError != null) {
      selectedDate = null;
      widget.controller?.updateSelectedDate(selectedDate);
    }

    return ValidatorResult(
      splited: splited,
      error: retError,
      pickerType: widget.pickerType,
      withSecond: options.withSecond,
    );
  }

  void checkFormat(String val, {bool complete = false}) {
    String value = val;
    // If only a delimiter is entered, enter today's date
    if (value.length == 1 && delititers.contains(value)) {
      value = DateFormat(format).format(DateTime.now());
    } else if (val.isEmpty && !widget.validators.showMessage) {
      if (widget.validators.onRequired != null) {
        widget.validators._errorRequired();
      }
      selectedDate = null;
      widget.controller?.updateSelectedDate(selectedDate);
      return;
    }

    // Input value check
    final result = validate(value, complete: complete);

    // If validator is not specified,
    // generate a Container to represent the error
    if (!widget.validators.showMessage) {
      if (result.error != null && errorWidget == null) {
        setState(() => errorWidget = const SizedBox());
      }
      // Hide errors
      else if (result.error == null && errorWidget != null) {
        setState(() => errorWidget = null);
      }

      // Notification of errors
      if (value.isEmpty && widget.validators.onRequired != null) {
        widget.validators._errorRequired();
      } else if (result.error != null) {
        switch (result.error!) {
          case BoardDateTimeInputError.illegal:
            widget.validators._errorIllegal(value);
            break;
          case BoardDateTimeInputError.outOfRange:
            widget.validators._errorOutOfRange(value);
            break;
        }
      }
    }

    if (result.splited == null) return;

    if (widget.pickerType == DateTimePickerType.time) {
      final hour = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.hour,
      );
      final minute = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.minute,
      );
      final second = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.second,
      );

      final existHour = hour != null && hour.text.isNotEmpty;

      if (complete && existHour && (minute == null || minute.text.isEmpty)) {
        final bloc = TextBloc(text: '00', start: 0, end: 0);
        bloc.dateType = DateType.minute;
        if (minute != null) {
          result.splited![result.splited!.length - 1] = bloc;
        } else {
          result.splited!.add(bloc);
        }
      }

      if (complete &&
          options.withSecond &&
          existHour &&
          (second == null || second.text.isEmpty)) {
        final secondBloc = TextBloc(text: '00', start: 0, end: 0);
        secondBloc.dateType = DateType.second;
        if (second != null) {
          result.splited![result.splited!.length - 1] = secondBloc;
        } else {
          result.splited!.add(secondBloc);
        }
      }
    }
    // Corrects for date or datetime if date or datetime
    else {
      // If the month and day have already been entered
      // but the year has not been entered,
      // the year of the initial date and time is corrected.
      final year = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.year,
      );
      final month = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.month,
      );
      final day = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.day,
      );
      if (year != null && year.text.isNotEmpty && complete) {
        if (month == null || month.text.isEmpty) {
          final bloc = TextBloc(text: '01', start: 0, end: 0)
            ..dateType = DateType.month;
          final monthIndex = pickerFormat.indexOf('M');
          if (monthIndex >= 0) {
            if (result.splited!.length <= monthIndex) {
              result.splited!.add(bloc);
            } else {
              result.splited![monthIndex] = bloc;
            }
          }
        }
        if (day == null || day.text.isEmpty) {
          final bloc = TextBloc(text: '01', start: 0, end: 0)
            ..dateType = DateType.day;
          final dayIndex = pickerFormat.indexOf('d');
          if (dayIndex >= 0) {
            if (result.splited!.length <= dayIndex) {
              result.splited!.add(bloc);
            } else {
              result.splited![dayIndex] = bloc;
            }
          }
        }
      }

      if (month != null &&
          month.text.isNotEmpty &&
          day != null &&
          day.text.isNotEmpty) {
        final year = result.splited!
            .firstWhereOrNull((e) => e.dateType == DateType.year);

        void setYear() {
          final bloc = TextBloc(
            text: (widget.initialDate ?? DateTime.now()).year.toString(),
            start: 0,
            end: 0,
          );
          bloc.dateType = DateType.year;
          if (result.splited!.last.text.isEmpty) {
            result.splited![result.splited!.length - 1] = bloc;
          } else {
            result.splited!.add(bloc);
          }
        }

        // Check implemented to not auto-add if string is deleted
        final isDeleted = beforeTextLength > value.length;

        // Compensate for out-of-focus
        if (complete && year == null) {
          setYear();
        }
        // Add only if a delimiter is entered
        else if (year != null && year.text.isEmpty && !isDeleted) {
          setYear();
        }
      }
    }

    // If out of focus, correct as needed
    // Only time correction is performed since the date is corrected for the date
    if (complete && widget.pickerType == DateTimePickerType.datetime) {
      if (result.splited!.length <= 5) {
        final diff = 5 -
            (result.splited!.where((e) => e.text.isNotEmpty).toList().length);
        for (var i = 0; i < diff; i++) {
          TextBloc bloc;
          if (i == diff - 1) {
            bloc = TextBloc(text: '00', start: 0, end: 0);
            bloc.dateType = DateType.minute;
          } else {
            bloc = TextBloc(text: '00', start: 0, end: 0);
            bloc.dateType = DateType.hour;
          }
          final index = result.splited!.indexWhere(
            (e) => e.dateType == bloc.dateType,
          );
          if (index < 0) {
            result.splited!.add(bloc);
          } else {
            result.splited![index] = bloc;
          }
        }
      }
    }

    final splitedText = result.splited!.map((e) => e.text).toList();

    // If the number of splitedTexts is 4 or more, they are merged separately because they contain time.
    String date;
    if (splitedText.length > 3) {
      final ymd = splitedText.sublist(0, 3).join(widget.delimiter);
      final hm = splitedText.sublist(3).join(':');
      date = '$ymd $hm';
    } else {
      if (widget.pickerType == DateTimePickerType.time) {
        date = splitedText.join(':');
      } else {
        date = splitedText.join(widget.delimiter);
      }
    }

    // If the last part is empty, exclude it.
    if (result.splited!.isNotEmpty &&
        result.splited!.last.text.isEmpty &&
        date.length >= format.length) {
      splitedText.removeLast();
      date = splitedText.join(widget.delimiter);
    }

    int offset = textOffset;
    if (textOffset == textController.text.length) {
      offset = date.length;
    }
    textController.text = date;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: offset),
    );

    final datetime = result.datetime;
    // Callback only if there are no errors
    if (datetime != null && result.error == null) {
      if (datetime.isAfter(minimumDate) &&
          datetime.isBefore(maximumDate) &&
          selectedDate != datetime) {
        selectedDate = datetime;
        widget.controller?.updateSelectedDate(selectedDate);
        widget.onChanged.call(datetime);
        widget.onResult?.call(
          BoardDateTimeCommonResult.init(widget.pickerType, datetime) as T,
        );
        pickerController?.changeDate(datetime);
        widget.controller?._notifier.value = _InoutValue.from(date);
      }
    }
  }

  Widget _pickerWidget() {
    void onClosePicker() {
      final hasFocus = pickerFocusNode.hasFocus;
      if (hasFocus) {
        checkFormat(textController.text, complete: true);
        // onFinished();
      }
      closePicker();
      FocusManager.instance.primaryFocus?.unfocus();
    }

    return GestureDetector(
      onTapDown: (_) {
        pickerFocusNode.requestFocus();
      },
      child: Focus(
        focusNode: pickerFocusNode,
        child: SingleBoardDateTimeContent(
          key: pickerController?.key,
          pickerFocusNode: pickerFocusNode,
          onChange: (val) {},
          pickerType: widget.pickerType,
          options: widget.options,
          breakpoint: widget.breakpoint,
          initialDate: selectedDate ?? DateTime.now(),
          minimumDate: widget.minimumDate,
          maximumDate: widget.maximumDate,
          modal: true,
          withTextField: true,
          onCreatedDateState: (val) {
            pickerDateState = val;
            pickerDateState!.addListener(pickerListener);
          },
          onCloseModal: onClosePicker,
          onKeyboadClose: onClosePicker,
          headerWidget: null,
          onTopActionBuilder: widget.onTopActionBuilder,
        ),
      ),
    );
  }

  /// Display small Picker when have focus
  OverlayEntry _createMiniPickerOverlay() {
    const double width = 360;

    // Get position and size of text field
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero);

    // Obtain the position of the right side
    // when displaying the Picker and the width of the entire screen.
    final rightPosition = (offset?.dx ?? 0) + width;
    final windowWidth = MediaQuery.of(context).size.width;

    double? left;
    double? right;

    // If it extends outside the screen,
    // use the right side of the text field as the reference.
    if (windowWidth < rightPosition) {
      right = windowWidth - (offset?.dx ?? 0) - size.width;
    } else {
      left = offset?.dx ?? 0;
    }

    return OverlayEntry(
      maintainState: true,
      builder: (context) {
        return Positioned(
          top: (offset?.dy ?? 0) + (renderBox?.size.height ?? 0),
          left: left,
          right: right,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: width,
              constraints: const BoxConstraints(
                minHeight: 240,
                maxHeight: 480,
              ),
              child: _pickerWidget(),
            ),
          ),
        );
      },
    );
  }

  /// Display standard Picker when have focus
  OverlayEntry _createPickerOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: AnimatedBuilder(
                  animation: overlayAnimController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: overlayAnimController
                          .drive(CurveTween(curve: Curves.easeInOutCubic))
                          .drive(
                            Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ),
                          ),
                      child: child,
                    );
                  },
                  child: _pickerWidget(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
