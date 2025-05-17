import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/board_datetime_widget.dart';
import 'package:board_datetime_picker/src/ui/board_datetime_contents_state.dart';
import 'package:flutter/material.dart';

abstract class AbstractBoardDatetimeWidget extends StatefulWidget {
  const AbstractBoardDatetimeWidget({
    super.key,
    this.controller,
    this.breakpoint = 800,
    this.initialDate,
    this.minimumDate,
    this.maximumDate,
    required this.pickerType,
    this.options = const BoardDateTimeOptions(),
    this.valueNotifier,
    this.onChanged,
    this.onResult,
    this.headerWidget,
    this.onTopActionBuilder,
    this.customCloseButtonBuilder,
    this.embeddedOptions = const EmbeddedOptions(),
  });

  final BoardDateTimeController? controller;
  final double breakpoint;
  final DateTime? initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;
  final ValueNotifier<DateTime>? valueNotifier;
  final Widget? headerWidget;
  final void Function(DateTime)? onChanged;
  final void Function(BoardDateTimeCommonResult)? onResult;
  final Widget Function(BuildContext context)? onTopActionBuilder;
  final CloseButtonBuilder? customCloseButtonBuilder;
  final EmbeddedOptions embeddedOptions;
}

abstract class AbstractMultiBoardDatetimeWidget extends StatefulWidget {
  const AbstractMultiBoardDatetimeWidget({
    super.key,
    this.controller,
    this.breakpoint = 800,
    this.startDate,
    this.endDate,
    this.minimumDate,
    this.maximumDate,
    required this.pickerType,
    this.options = const BoardDateTimeOptions(),
    // this.valueNotifier,
    this.onChanged,
    this.onResult,
    this.headerWidget,
    this.onTopActionBuilder,
    this.customCloseButtonBuilder,
    this.multiSelectionMaxDateBuilder,
    this.embeddedOptions = const EmbeddedOptions(),
  });

  final BoardMultiDateTimeController? controller;
  final double breakpoint;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTimePickerType pickerType;
  final BoardDateTimeOptions options;
  final Widget? headerWidget;
  // final ValueNotifier<DateTime>? valueNotifier;
  final void Function(BoardDateTimeMultiSelection)? onChanged;
  final void Function(BoardDateTimeCommonResult, BoardDateTimeCommonResult)?
      onResult;
  final Widget Function(BuildContext context)? onTopActionBuilder;
  final CloseButtonBuilder? customCloseButtonBuilder;
  final MultiSelectionMaxDateBuilder? multiSelectionMaxDateBuilder;
  final EmbeddedOptions embeddedOptions;
}
