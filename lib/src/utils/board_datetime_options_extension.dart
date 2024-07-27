import 'package:flutter/material.dart';

import '../board_datetime_options.dart';
import 'board_enum.dart';

extension BoardDateTimeOptionsExtension on BoardDateTimeOptions {
  Color getBackgroundColor(BuildContext context) =>
      backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

  Color getForegroundColor(BuildContext context) =>
      foregroundColor ?? Theme.of(context).cardColor;

  Color? getTextColor(BuildContext context) =>
      textColor ?? Theme.of(context).textTheme.bodyLarge?.color;

  Color getActiveColor(BuildContext context) =>
      activeColor ?? Theme.of(context).primaryColor;

  Color getActiveTextColor(BuildContext context) =>
      activeTextColor ?? Colors.white;

  bool get isTopTitleHeader =>
      boardTitle != null && boardTitle!.isNotEmpty && showDateButton;

  /// Obtain the title to be displayed on the item.
  /// Correct with default value only if it exists in the middle.
  String? getSubTitle(DateType type) {
    if (pickerSubTitles == null || pickerSubTitles!.notSpecified) {
      return null;
    }

    switch (type) {
      case DateType.year:
        return pickerSubTitles?.year ?? 'Year';
      case DateType.month:
        return pickerSubTitles?.month ?? 'Month';
      case DateType.day:
        return pickerSubTitles?.day ?? 'Day';
      case DateType.hour:
        return pickerSubTitles?.hour ?? 'Hour';
      case DateType.minute:
        return pickerSubTitles?.minute ?? 'Minute';
      case DateType.second:
        return pickerSubTitles?.second ?? 'Second';
    }
  }
}
