import 'dart:math';

import 'package:board_datetime_picker/src/ui/parts/item.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';

import 'board_custom_item_option.dart';

BoardPickerItemOption initItemOption(
  DateType type,
  DateTime date,
  DateTime? minimum,
  DateTime? maximum,
  List<int>? customList,
  String? subTitle,
) {
  if (customList != null && customList.isNotEmpty) {
    return BoardPickerCustomItemOption.init(
      type,
      customList,
      date,
      minimum,
      maximum,
      subTitle,
    );
  } else {
    return BoardPickerItemOption.init(type, date, minimum, maximum, subTitle);
  }
}

class BoardPickerItemOption {
  BoardPickerItemOption({
    required this.type,
    required this.focusNode,
    required this.map,
    required this.selectedIndex,
    required this.minimumDate,
    required this.maximumDate,
    required this.subTitle,
  });

  /// [DateType] year, month, day, hour, minute
  final DateType type;

  /// TextField [FocusNode].
  final FocusNode focusNode;

  /// Picker item map.
  Map<int, int> map;

  /// Selected item for list.
  int selectedIndex;

  /// Keys for date item widget
  final stateKey = GlobalKey<ItemWidgetState>();

  /// Minimum year that can be specified
  final DateTime minimumDate;

  /// Maximum year that can be specified
  final DateTime maximumDate;

  /// Title to be displayed on item
  final String? subTitle;

  /// Constractor
  factory BoardPickerItemOption.init(
    DateType type,
    DateTime date,
    DateTime? minimum,
    DateTime? maximum,
    String? subTitle,
  ) {
    Map<int, int> map = {};
    int selected;

    // Define specified minimum and maximum dates
    final mi = minimum ?? DateTimeUtil.defaultMinDate;
    final ma = maximum ?? DateTimeUtil.defaultMaxDate;

    switch (type) {
      case DateType.year:
        return BoardPickerItemOption.year(date, minimum, maximum, subTitle);
      case DateType.month:
        map = minmaxList(DateType.month, date, mi, ma);
        selected = indexFromValue(date.month, map);

        break;
      case DateType.day:
        map = minmaxList(DateType.day, date, mi, ma);
        selected = indexFromValue(date.day, map);
        break;
      case DateType.hour:
        map = minmaxList(DateType.hour, date, mi, ma);
        selected = indexFromValue(date.hour, map);
        break;
      case DateType.minute:
        map = minmaxList(DateType.minute, date, mi, ma);
        selected = indexFromValue(date.minute, map);
        break;
    }

    return BoardPickerItemOption(
      focusNode: FocusNode(),
      map: map,
      type: type,
      selectedIndex: selected,
      minimumDate: mi,
      maximumDate: ma,
      subTitle: subTitle,
    );
  }

  /// Constractor for year item
  factory BoardPickerItemOption.year(
    DateTime date,
    DateTime? minimum,
    DateTime? maximum,
    String? subTitle,
  ) {
    final minY = minimum?.year ?? DateTimeUtil.minimumYear;

    // Define specified minimum and maximum dates
    final mi = minimum ?? DateTime(DateTimeUtil.minimumYear, 1, 1, 0, 0);
    final ma = maximum ?? DateTime(DateTimeUtil.maximumYear, 12, 31, 23, 59);

    final map = minmaxList(DateType.year, date, mi, ma);
    return BoardPickerItemOption(
      focusNode: FocusNode(),
      map: map,
      type: DateType.year,
      selectedIndex: indexFromValue(max(date.year, minY), map),
      minimumDate: mi,
      maximumDate: ma,
      subTitle: subTitle,
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

  void changeDate(DateTime date) {
    switch (type) {
      case DateType.year:
        selectedIndex = getIndexFromValue(date.year) ?? 0;
        break;
      case DateType.month:
        selectedIndex = getIndexFromValue(date.month) ?? 0;
        break;
      case DateType.day:
        selectedIndex = getIndexFromValue(date.day) ?? 0;
        break;
      case DateType.hour:
        selectedIndex = getIndexFromValue(date.hour) ?? 0;
        break;
      case DateType.minute:
        selectedIndex = getIndexFromValue(date.minute) ?? 0;
        break;
    }
    stateKey.currentState?.toAnimateChange(selectedIndex, button: true);
  }

  /// Get the map index from the value and return it
  int? getIndexFromValue(int val) {
    for (final index in map.keys) {
      if (map[index] == val) return index;
    }
    return null;
  }

  static int indexFromValue(int val, Map<int, int> map) {
    for (final index in map.keys) {
      if (map[index] == val) return index;
    }
    return 0;
  }

  /// Get the currently selected value
  int get value => map[selectedIndex]!;

  /// input content check
  void checkInputField() {
    final text = stateKey.currentState?.textController.text;
    if (text != null) {
      try {
        final data = int.parse(text);
        if (map.values.contains(data)) return;
      } catch (_) {}
    }

    // Update to the current year and month
    // because the value does not exist in the list
    final date = DateTime.now();
    changeDate(date);
    stateKey.currentState?.textController.text = date.year.toString();
  }

  void updateList(DateTime date) {
    //  Retrieve existing values
    final tmp = value;
    // Generate new maps
    map = minmaxList(type, date, minimumDate, maximumDate);
    updateState(tmp, date);
  }

  void updateDayMap(int maxDay, DateTime newDate) {
    int minDay = 1;
    int maxDay = 31;
    if (newDate.isMinimum(minimumDate, DateType.month)) {
      minDay = minimumDate.day;
    }
    if (newDate.isMaximum(maximumDate, DateType.month)) {
      maxDay = min(maxDay, maximumDate.day);
    }

    //  Retrieve existing values
    final tmp = value;

    Map<int, int> newMap = {};
    int index = 0;
    for (var i = minDay; i <= maxDay; i++) {
      newMap[index] = i;
      index++;
    }
    map = newMap;
    updateState(tmp, newDate);
  }

  void updateState(int tmpValue, DateTime date) {
    // Get the index of the value that was selected
    // before the update and update it to that value
    final index = getIndexFromValue(tmpValue);
    if (index != null) {
      selectedIndex = index;
    } else if (map.values.first > tmpValue) {
      selectedIndex = 0;
    } else if (selectedIndex >= map.keys.length) {
      selectedIndex = map.keys.last;
    }
    stateKey.currentState?.updateState(map, selectedIndex);
  }

  static Map<int, int> minmaxList(
    DateType dt,
    DateTime date,
    DateTime minimum,
    DateTime maximum,
  ) {
    Map<int, int> createMap(int start, int end) {
      Map<int, int> map = {};
      int index = 0;
      for (var i = start; i <= end; i++) {
        map[index] = i;
        index++;
      }
      return map;
    }

    switch (dt) {
      case DateType.year:
        return createMap(minimum.year, maximum.year);
      case DateType.month:
        int minMonth = 1;
        int maxMonth = 12;
        if (date.isMinimum(minimum, DateType.year)) {
          minMonth = minimum.month;
        }
        if (date.isMaximum(maximum, DateType.year)) {
          maxMonth = maximum.month;
        }
        return createMap(minMonth, maxMonth);
      case DateType.day:
        int minDay = 1;
        int maxDay = 31;
        if (date.isMinimum(minimum, DateType.month)) {
          minDay = minimum.day;
        }
        if (date.isMaximum(maximum, DateType.month)) {
          maxDay = maximum.day;
        }
        return createMap(minDay, maxDay);
      case DateType.hour:
        int minHour = 0;
        int maxHour = 23;
        if (date.isMinimum(minimum, DateType.day)) {
          minHour = minimum.hour;
        }
        if (date.isMaximum(maximum, DateType.day)) {
          maxHour = maximum.hour;
        }
        return createMap(minHour, maxHour);
      case DateType.minute:
        int minMinute = 0;
        int maxMinute = 59;
        if (date.isMinimum(minimum, DateType.hour)) {
          minMinute = minimum.minute;
        }
        if (date.isMaximum(maximum, DateType.hour)) {
          maxMinute = maximum.minute;
        }
        return createMap(minMinute, maxMinute);
    }
  }

  DateTime calcDate(DateTime date) {
    switch (type) {
      case DateType.year:
        return DateTime(
          map[selectedIndex]!,
          date.month,
          date.day,
          date.hour,
          date.minute,
        );
      case DateType.month:
        return DateTime(
          date.year,
          map[selectedIndex]!,
          date.day,
          date.hour,
          date.minute,
        );
      case DateType.day:
        return DateTime(
          date.year,
          date.month,
          map[selectedIndex]!,
          date.hour,
          date.minute,
        );
      case DateType.hour:
        return DateTime(
          date.year,
          date.month,
          date.day,
          map[selectedIndex]!,
          date.minute,
        );
      case DateType.minute:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          map[selectedIndex]!,
        );
    }
  }
}
