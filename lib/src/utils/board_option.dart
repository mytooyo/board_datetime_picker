import 'package:flutter/material.dart';

import '../parts/item.dart';
import 'board_enum.dart';

class BoardPickerItemOption {
  BoardPickerItemOption({
    required this.type,
    required this.focusNode,
    required this.list,
    required this.selected,
  });

  /// [DateType] year, month, day, hour, minute
  final DateType type;

  /// TextField [FocusNode].
  final FocusNode focusNode;

  /// Picker item list.
  List<int> list;

  /// Selected item for list.
  int selected;

  /// Keys for date item widget
  final stateKey = GlobalKey<ItemWidgetState>();

  /// Minimum year that can be specified
  static const int minYear = 1900;

  /// Constractor
  factory BoardPickerItemOption.init(DateType type, DateTime date) {
    List<int> list = [];
    int selected;
    switch (type) {
      case DateType.year:
        return BoardPickerItemOption.year(date);
      case DateType.month:
        for (var i = 1; i <= 12; i++) {
          list.add(i);
        }
        selected = date.month;
        break;
      case DateType.day:
        for (var i = 1; i <= 31; i++) {
          list.add(i);
        }
        selected = date.day;
        break;
      case DateType.hour:
        for (var i = 0; i <= 23; i++) {
          list.add(i);
        }
        selected = date.hour;
        break;
      case DateType.minute:
        for (var i = 0; i <= 59; i++) {
          list.add(i);
        }
        selected = date.minute;
        break;
    }

    return BoardPickerItemOption(
      focusNode: FocusNode(),
      list: list,
      type: type,
      selected: selected,
    );
  }

  /// Constractor for year item
  factory BoardPickerItemOption.year(DateTime date) {
    List<int> list = [];
    for (var i = minYear; i < 2099; i++) {
      list.add(i);
    }
    return BoardPickerItemOption(
      focusNode: FocusNode(),
      list: list,
      type: DateType.year,
      selected: date.year,
    );
  }

  /// Max Length for TextField
  int get maxLength {
    if (type == DateType.year) {
      return 4;
    }
    return 2;
  }

  /// Flex for Row children
  int get flex {
    if (type == DateType.year) {
      return 2;
    }
    return 1;
  }

  int getIndex({int? index}) {
    switch (type) {
      case DateType.year:
        return (index ?? selected) - minYear;
      case DateType.month:
      case DateType.day:
        return (index ?? selected) - 1;
      default:
        return index ?? selected;
    }
  }

  int getValueFromIndex(int index) {
    switch (type) {
      case DateType.year:
        return minYear + index;
      case DateType.month:
      case DateType.day:
        return index + 1;
      default:
        return index;
    }
  }

  void updateList(int maxDay) {
    List<int> tmp = [];
    for (var i = 1; i <= maxDay; i++) {
      tmp.add(i);
    }
    list = tmp;

    if (selected >= list.length) {
      selected = list.last;
    }

    stateKey.currentState?.updateState(list);
  }

  void changeDate(DateTime date) {
    switch (type) {
      case DateType.year:
        selected = date.year;
        break;
      case DateType.month:
        selected = date.month;
        break;
      case DateType.day:
        selected = date.day;
        break;
      case DateType.hour:
        selected = date.hour;
        break;
      case DateType.minute:
        selected = date.minute;
        break;
    }
    stateKey.currentState?.toAnimateChange(selected, button: true);
  }

  /// input content check
  void checkInputField() {
    final text = stateKey.currentState?.textController.text;
    if (text != null) {
      try {
        final data = int.parse(text);
        if (list.contains(data)) return;
      } catch (_) {}
    }

    // Update to the current year and month
    // because the value does not exist in the list
    final date = DateTime.now();
    changeDate(date);
    stateKey.currentState?.textController.text = date.year.toString();
  }

  DateTime calcDate(DateTime date, {int? index}) {
    switch (type) {
      case DateType.year:
        return DateTime(
          (index ?? selected),
          date.month,
          date.day,
          date.hour,
          date.minute,
        );
      case DateType.month:
        return DateTime(
          date.year,
          (index ?? selected),
          date.day,
          date.hour,
          date.minute,
        );
      case DateType.day:
        return DateTime(
          date.year,
          date.month,
          (index ?? selected),
          date.hour,
          date.minute,
        );
      case DateType.hour:
        return DateTime(
          date.year,
          date.month,
          date.day,
          (index ?? selected),
          date.minute,
        );
      case DateType.minute:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          (index ?? selected),
        );
    }
  }
}
