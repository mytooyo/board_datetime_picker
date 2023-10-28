import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';

import 'board_datetime_builder.dart';

/// Show a BoardDateTimePicker modal bottom sheet.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the bottom sheet.
///
/// The `pickerType` argument is type of picker to display mode.
/// [date] or [time] or [datetime].
///
/// The `valueNotifier` is a parameter to detect changes and notify you immediately.
/// If it is changed in the picker, it is set to value so that the caller will
/// receive a change callback immediately.
/// With or without specification, pressing the check button in the
/// header will return the selected date.
///
/// The `initialDate` and `minimumDate` and `maximumDate` are parameters related to dates,
/// respectively. Initial value, minimum date, and maximum date.
///
/// The `options` is an option to customize the picker display.
///
/// The `breakpoint` is the width that switches between wide and standard display.
/// The `radius` is a rounded corner on both sides of the top in modal display.
///
/// `barrierColor`, `routeSettings`, `transitionAnimationController`, etc. are
/// the parameters that are specified in the normal modal bottom sheet,
/// so please check there for a description of the parameters.
Future<DateTime?> showBoardDateTimePicker({
  required BuildContext context,
  required DateTimePickerType pickerType,
  ValueNotifier<DateTime>? valueNotifier,
  DateTime? initialDate,
  DateTime? minimumDate,
  DateTime? maximumDate,
  BoardDateTimeOptions? options,
  double breakpoint = 800,
  double radius = 24,
  Color? barrierColor,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
}) async {
  final opt = options ?? const BoardDateTimeOptions();

  return await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    barrierColor: barrierColor,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    backgroundColor:
        opt.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _BoardDateTimeWidget(
          breakpoint: breakpoint,
          pickerType: pickerType,
          initialDate: initialDate,
          minimumDate: minimumDate,
          maximumDate: maximumDate,
          options: opt,
          valueNotifier: valueNotifier,
        ),
      );
    },
  );
}

class _BoardDateTimeWidget extends StatefulWidget {
  const _BoardDateTimeWidget({
    this.breakpoint = 800,
    this.initialDate,
    this.minimumDate,
    this.maximumDate,
    required this.pickerType,
    this.options = const BoardDateTimeOptions(),
    this.valueNotifier,
  });

  final double breakpoint;
  final DateTime? initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;
  final ValueNotifier<DateTime>? valueNotifier;

  @override
  State<_BoardDateTimeWidget> createState() => _BoardDateTimeWidgetState();
}

class _BoardDateTimeWidgetState extends State<_BoardDateTimeWidget> {
  late DateTime date;

  @override
  void initState() {
    date = widget.initialDate ?? DateTime.now();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BoardDateTimeContent(
      onChange: (val) {
        date = val;
        widget.valueNotifier?.value = val;
      },
      pickerType: widget.pickerType,
      options: widget.options,
      breakpoint: widget.breakpoint,
      initialDate: date,
      minimumDate: widget.minimumDate,
      maximumDate: widget.maximumDate,
      modal: true,
      onCloseModal: () {
        Navigator.of(context).pop(date);
      },
    );
  }
}
