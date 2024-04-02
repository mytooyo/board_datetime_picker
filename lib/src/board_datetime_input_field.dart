import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../board_datetime_picker.dart';
import 'board_datetime_builder.dart';
import 'ui/parts/focus_node.dart';
import 'utils/board_enum.dart';
import 'utils/datetime_util.dart';

enum BoardDateTimeInputError { illegal, outOfRange }

extension BoardDateTimeInputErrorExtension on BoardDateTimeInputError {
  String get message {
    switch (this) {
      case BoardDateTimeInputError.illegal:
        return 'Illegal format error';
      case BoardDateTimeInputError.outOfRange:
        return 'Out of Range';
    }
  }
}

class BoardDateTimeInputFieldValidators {
  /// Message for which the entered message is invalid
  final String Function(String)? onIllegalFormat;

  /// Error messages outside the specified date/time range
  final String Function(String)? onOutOfRange;

  /// Message in case of a required error
  final String? Function()? onRequired;

  /// Specify whether messages are displayed below text fields by default
  /// If true, an error message is displayed at the bottom of the field as in a normal TextFormField.
  final bool showMessage;

  const BoardDateTimeInputFieldValidators({
    this.onIllegalFormat,
    this.onOutOfRange,
    this.onRequired,
    this.showMessage = false,
  });

  String? errorIllegal(String text) {
    return onIllegalFormat?.call(text) ??
        BoardDateTimeInputError.illegal.message;
  }

  String? errorOutOfRange(String text) {
    return onOutOfRange?.call(text) ??
        BoardDateTimeInputError.outOfRange.message;
  }

  String? errorRequired() {
    return onRequired?.call();
  }
}

class BoardDateTimeInputField<T extends BoardDateTimeCommonResult>
    extends StatefulWidget {
  const BoardDateTimeInputField({
    super.key,
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

  /// Delimiter used to separate dates
  /// If a slash[-] is specified, it will look like this: `yyyy-MM-dd`
  /// However, the time delimiter is fixed to a colon[:] and cannot be changed
  final String delimiter;

  /// Set error messages when errors occur in validating against text fields
  /// If not specified, default error messages are displayed
  final BoardDateTimeInputFieldValidators validators;

  /// Callback when the focus state is changed for the corresponding TextField
  final void Function(bool, DateTime?)? onFocusChange;

  final double breakpoint;

  // ************************************************************************
  // *
  // * All of the following are parameters to be used for a normal TextField
  // *
  // ************************************************************************

  final FocusNode? focusNode;
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
  /// Overlay
  final GlobalKey overlayKey = GlobalKey();
  OverlayEntry? overlay;

  /// フォーカスノード監視用
  Timer? focusNodeDebounce;

  BoardDateTimeContentsController? pickerController;

  /// Overlay Animation Controller
  late AnimationController overlayAnimController;

  /// 入力フィールドのコントローラ
  late TextEditingController textController;

  /// FocusNode
  late BoardDateTimeInputFocusNode focusNode;
  late PickerContentsFocusNode pickerFocusNode;

  /// 選択中の日付
  DateTime? selectedDate;

  /// Text Format
  late String format;

  late String pickerFormat;

  final GlobalKey<FormState> formKey = GlobalKey();

  /// Date
  late DateTime minimumDate;
  late DateTime maximumDate;

  ValueNotifier<DateTime>? pickerDateState;

  BoardDateTimeOptions get options => widget.options;

  final BorderRadius borderRadius = BorderRadius.circular(8);

  final List<String> delititers = ['/', ';', ':', ',', '.', '-', ' '];

  /// 変更前の文字数
  int beforeTextLength = -1;

  int get textOffset => textController
      .selection.extent.offset; //textController.selection.base.offset;

  /// エラー発生時に利用するためのWidget
  /// Borderを表示したいので基本的にContainerのみでOK
  Widget? errorWidget;

  void closePicker({bool disposed = false}) {
    if (disposed) {
      overlay?.remove();
    } else {
      final future = overlayAnimController.reverse();
      if (overlay != null) {
        future.then((value) {
          overlay?.remove();
          overlay = null;
        });
      }
    }
  }

  void openPicker() {}

  void _focusListener() {
    if (!focusNode.hasFocus) {
      if (textController.text.isNotEmpty) {
        checkFormat(textController.text, complete: true);
      }
    } else {
      if (!widget.showPicker || overlay != null) return;
      pickerController = BoardDateTimeContentsController();
      if (selectedDate != null) {
        pickerController!.changeDate(selectedDate!);
      }

      // フォーカスを取得した際のコールバック
      widget.onFocusChange?.call(true, selectedDate);

      overlay = OverlayEntry(
        builder: (context) {
          return Align(
            alignment: Alignment.bottomCenter,
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
                  child: GestureDetector(
                    onTap: () {
                      pickerFocusNode.requestFocus();
                    },
                    child: Focus(
                      focusNode: pickerFocusNode,
                      child: BoardDateTimeContent(
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
                        onCreatedDateState: (val) {
                          pickerDateState = val;
                          pickerDateState!.addListener(pickerListener);
                        },
                        onCloseModal: () {
                          focusNode.unfocus();
                          closePicker();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
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

  void focusScopeListener() {
    focusNodeDebounce?.cancel();
    focusNodeDebounce = Timer(const Duration(milliseconds: 100), () {
      // print('*** focus scope: ${FocusManager.instance.primaryFocus}');
      final pf = FocusManager.instance.primaryFocus;
      if (pf is! BoardDateTimeInputFocusNode &&
          pf is! PickerItemFocusNode &&
          pf is! PickerContentsFocusNode &&
          pf is! PickerWheelItemFocusNode) {
        closePicker();
        if (initialized) {
          widget.onFocusChange?.call(false, selectedDate);
        }
        initialized = true;
      }
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
    switch (widget.pickerType) {
      case DateTimePickerType.date:
        pickerFormat = options.pickerFormat;
        break;
      case DateTimePickerType.datetime:
        pickerFormat = '${options.pickerFormat}Hm';
        break;
      case DateTimePickerType.time:
        pickerFormat = 'Hm';
        break;
    }

    // TextFormat
    format = pickerFormat.dateFormat(widget.delimiter);

    DateTime? initial;
    if (widget.initialDate != null) {
      initial = rangeDate(widget.initialDate!);
      selectedDate = initial;
    }
    minimumDate = widget.minimumDate ?? DateTimeUtil.defaultMinDate;
    maximumDate = widget.maximumDate ?? DateTimeUtil.defaultMaxDate;

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
    focusNode = BoardDateTimeInputFocusNode();
    focusNode.addListener(_focusListener);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      FocusScope.of(context).addListener(focusScopeListener);
    });

    overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 260),
    );

    super.initState();
  }

  @override
  void deactivate() {
    FocusScope.of(context).removeListener(focusScopeListener);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        key: overlayKey,
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
              errorMaxLines: 2,
              // validatorを指定しない場合はこれを指定することでエラーを表現できる
              error: errorWidget,
            ),
        validator: widget.validators.showMessage
            ? (value) {
                // 必須でエラーの場合
                if (value == null || value.isEmpty) {
                  return widget.validators.errorRequired();
                }

                final error = validate(
                  value,
                  complete: textController.text.length != textOffset ||
                      textOffset == format.length,
                ).error;

                if (error == null) return null;

                switch (error) {
                  case BoardDateTimeInputError.illegal:
                    return widget.validators.errorIllegal(value);
                  case BoardDateTimeInputError.outOfRange:
                    return widget.validators.errorOutOfRange(value);
                }
              }
            : null,
        inputFormatters: [
          LengthLimitingTextInputFormatter(format.length),
          FilteringTextInputFormatter.allow(
            RegExp(r'[0-9/;:,\-\s\.]'),
          )
        ],
        onChanged: (val) {
          checkFormat(val);
          beforeTextLength = val.length;
        },
        onEditingComplete: () {
          closePicker();
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  ValidatorResult validate(String value, {bool complete = false}) {
    List<TextBloc> splited = [];

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
          return ValidatorResult(
            error: BoardDateTimeInputError.illegal,
            pickerType: widget.pickerType,
          );
        }

        BoardDateTimeInputError? check() {
          BoardDateTimeInputError? err;
          // Fill in zeros if not enough.
          final d = data.text.padLeft(f.count, '0');

          if (data.start <= textOffset && data.end >= textOffset && !complete) {
            return null;
          }

          // 通常の範囲チェックを実施
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
            } else if (f == 'm') {
              final m = int.parse(data.text);
              if (!(m >= 0 && m <= 59)) {
                err = BoardDateTimeInputError.illegal;
              }
            }
          } catch (ex) {
            return err;
          }

          splited[i].text = d;
          return err;
        }

        // デリミターが入力されて次のデータが存在する場合のみ補正
        // ただし、カーゾルの位置から編集中のブロックの場合は補正しない
        final isLast = splited.length == i + 1;
        // フォーカスが外れて全体のチェックの場合はすべての値に対してのエラーをハンドリングする
        if (complete) {
          retError ??= check();
        } else if (!isLast) {
          retError ??= check();
        }
      }
    }

    if (retError != null) selectedDate = null;

    return ValidatorResult(
      splited: splited,
      error: retError,
      pickerType: widget.pickerType,
    );
  }

  void checkFormat(String val, {bool complete = false}) {
    String value = val;
    // デリミターのみ入力された場合は今日の日付を入力する
    if (value.length == 1 && delititers.contains(value)) {
      value = DateFormat(format).format(DateTime.now());
    }

    // 入力値チェック
    final result = validate(value, complete: complete);

    // validatorが指定されていない場合はエラーを表現するために
    // Containerを生成する
    if (!widget.validators.showMessage) {
      if (result.error != null && errorWidget == null) {
        setState(() => errorWidget = Container());
      }
      // エラーを非表示
      else if (result.error == null && errorWidget != null) {
        setState(() => errorWidget = null);
      }

      // エラーを通知
      if (value.isEmpty && widget.validators.onRequired != null) {
        widget.validators.errorRequired();
      } else if (result.error != null) {
        switch (result.error!) {
          case BoardDateTimeInputError.illegal:
            widget.validators.errorIllegal(value);
            break;
          case BoardDateTimeInputError.outOfRange:
            widget.validators.errorOutOfRange(value);
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
      if (complete &&
          hour != null &&
          hour.text.isNotEmpty &&
          (minute == null || minute.text.isEmpty)) {
        final bloc = TextBloc(text: '00', start: 0, end: 0);
        bloc.dateType = DateType.minute;
        if (minute != null) {
          result.splited![result.splited!.length - 1] = bloc;
        } else {
          result.splited!.add(bloc);
        }
      }
    }
    // dateまたはdatetimeの場合は年月日を補正
    else {
      // 月と日が入力済みで年が未入力の場合は初期日時の年で補正する
      final month = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.month,
      );
      final day = result.splited!.firstWhereOrNull(
        (e) => e.dateType == DateType.day,
      );
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

        // 文字列を削除した場合は自動追加しないようにチェックを実施
        final isDeleted = beforeTextLength > value.length;

        // フォーカスが外れた場合は補正する
        if (complete && year == null) {
          setYear();
        }
        // デリミターが入力された場合のみ追加
        else if (year != null && year.text.isEmpty && !isDeleted) {
          setYear();
        }
      }
    }

    // フォーカスが外れた場合、必要に応じて補正する
    // 日付については補正されるため、時間の補正のみを実施
    if (complete && widget.pickerType == DateTimePickerType.datetime) {
      if (result.splited!.length <= 5) {
        final diff = 5 -
            (result.splited!.where((e) => e.text.isNotEmpty).toList().length);
        for (var i = 0; i < diff; i++) {
          TextBloc bloc;
          // 最終の場合は分を追加
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

    // splitedTextの数が4以上の場合は時間を含むため、分けて結合する
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

    // 最後が空の場合は除外する
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
    // エラーがない場合のみコールバックを実施
    if (datetime != null && result.error == null) {
      if (datetime.isAfter(minimumDate) &&
          datetime.isBefore(maximumDate) &&
          selectedDate != datetime) {
        selectedDate = datetime;
        widget.onChanged.call(datetime);
        widget.onResult?.call(
          BoardDateTimeCommonResult.init(widget.pickerType, datetime) as T,
        );
        pickerController?.changeDate(datetime);
      }
    }
  }
}

class ValidatorResult {
  final List<TextBloc>? splited;
  final BoardDateTimeInputError? error;
  final DateTimePickerType pickerType;

  ValidatorResult({
    this.splited,
    this.error,
    required this.pickerType,
  });

  DateTime? get datetime {
    if (pickerType == DateTimePickerType.time) {
      final date = DateTime.now();

      final hour = splited?.firstWhereOrNull(
        (e) => e.dateType == DateType.hour,
      );
      final minute = splited?.firstWhereOrNull(
        (e) => e.dateType == DateType.minute,
      );

      return DateTime(
        date.year,
        date.month,
        date.day,
        hour == null || hour.text.isEmpty ? 0 : int.parse(hour.text),
        minute == null || minute.text.isEmpty ? 0 : int.parse(minute.text),
      );
    }

    final year = splited?.firstWhereOrNull(
      (e) => e.dateType == DateType.year,
    );
    final month = splited?.firstWhereOrNull(
      (e) => e.dateType == DateType.month,
    );
    final day = splited?.firstWhereOrNull(
      (e) => e.dateType == DateType.day,
    );
    final hour = splited?.firstWhereOrNull(
      (e) => e.dateType == DateType.hour,
    );
    final minute = splited?.firstWhereOrNull(
      (e) => e.dateType == DateType.minute,
    );
    if (year == null ||
        month == null ||
        year.text.isEmpty ||
        month.text.isEmpty) return null;
    return DateTime(
      int.parse(year.text),
      int.parse(month.text),
      day == null || day.text.isEmpty ? 1 : int.parse(day.text),
      hour == null || hour.text.isEmpty ? 0 : int.parse(hour.text),
      minute == null || minute.text.isEmpty ? 0 : int.parse(minute.text),
    );
  }
}

class TextBloc {
  String text;
  final int start;
  final int end;
  DateType? dateType;

  TextBloc({
    required this.text,
    required this.start,
    required this.end,
  });
}

extension StringExtension on String {
  int get count {
    switch (this) {
      case 'y':
        return 4;
      case 'M':
      case 'd':
      case 'H':
      case 'm':
        return 2;
      default:
        return 0;
    }
  }

  DateType get dateType {
    switch (this) {
      case 'y':
        return DateType.year;
      case 'M':
        return DateType.month;
      case 'd':
        return DateType.day;
      case 'H':
        return DateType.hour;
      case 'm':
        return DateType.minute;
      default:
        return DateType.year;
    }
  }

  String dateFormat(String delimiter) {
    switch (this) {
      case PickerFormat.mdy:
        return 'MM${delimiter}dd${delimiter}yyyy';
      case '${PickerFormat.mdy}Hm':
        return 'MM${delimiter}dd${delimiter}yyyy HH:mm';
      case PickerFormat.dmy:
        return 'dd${delimiter}MM${delimiter}yyyy';
      case '${PickerFormat.dmy}Hm':
        return 'dd${delimiter}MM${delimiter}yyyy HH:mm';
      case PickerFormat.ymd:
        return 'yyyy${delimiter}MM${delimiter}dd';
      case '${PickerFormat.ymd}Hm':
        return 'yyyy${delimiter}MM${delimiter}dd HH:mm';
      default:
        return 'HH:mm';
    }
  }
}
