import 'dart:math';

import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/ui/parts/item.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../ui/parts/focus_node.dart';
import 'board_custom_item_option.dart';

class ItemOptionArgs {
  ItemOptionArgs({
    required this.pickerType,
    required this.type,
    required this.date,
    required this.minimum,
    required this.maximum,
    this.customList,
    required this.subTitle,
    this.withSecond = false,
    required this.useAmpm,
    required this.monthFormat,
    required this.locale,
    required this.wide,
  });

  final DateTimePickerType pickerType;
  final DateType type;
  final DateTime date;
  final DateTime? minimum;
  final DateTime? maximum;
  final List<int>? customList;
  final String? subTitle;
  final bool withSecond;
  final bool useAmpm;
  final PickerMonthFormat monthFormat;
  final String locale;
  final bool Function() wide;
}

BoardPickerItemOption initItemOption(ItemOptionArgs args) {
  if (args.customList != null && args.customList!.isNotEmpty) {
    return BoardPickerCustomItemOption.init(args: args);
  } else {
    return BoardPickerItemOption.init(args: args);
  }
}

class BoardPickerItemOption {
  BoardPickerItemOption({
    required this.args,
    required this.minimumDate,
    required this.maximumDate,
    required this.focusNode,
    required this.itemMap,
    required this.selectedIndex,
    required this.ampm,
  });

  final ItemOptionArgs args;

  DateTimePickerType get pickerType => args.pickerType;

  /// [PickerMonthFormat] month format
  PickerMonthFormat get monthFormat => args.monthFormat;

  /// [DateType] year, month, day, hour, minute
  DateType get type => args.type;

  /// Title to be displayed on item
  String? get subTitle => args.subTitle;

  /// Flag indicating whether to specify seconds
  /// Specified by 0 if not specified
  bool get withSecond => args.withSecond;

  /// Locale
  String get locale => args.locale;

  bool get useAmpm => args.useAmpm;

  /// Minimum year that can be specified
  final DateTime minimumDate;

  /// Maximum year that can be specified
  final DateTime maximumDate;

  /// TextField [FocusNode].
  final PickerItemFocusNode focusNode;

  /// Picker item map.
  Map<int, int> itemMap;

  /// Selected item for list.
  int selectedIndex;

  AmPm? ampm;

  /// Keys for date item widget
  final stateKey = GlobalKey<ItemWidgetState>();
  final ampmStateKey = GlobalKey<AmpmItemWidgetState>();

  /// Constractor
  factory BoardPickerItemOption.init({required ItemOptionArgs args}) {
    Map<int, int> map = {};
    int selected;
    AmPm? ampm;

    // Define specified minimum and maximum dates
    final mi = args.minimum ?? DateTimeUtil.defaultMinDate;
    final ma = args.maximum ?? DateTimeUtil.defaultMaxDate;

    switch (args.type) {
      case DateType.year:
        return BoardPickerItemOption.year(args: args);
      case DateType.month:
        map = minmaxList(args.pickerType, DateType.month, args.date, mi, ma);
        selected = indexFromValue(args.date.month, map);

        break;
      case DateType.day:
        map = minmaxList(args.pickerType, DateType.day, args.date, mi, ma);
        selected = indexFromValue(args.date.day, map);
        break;
      case DateType.hour:
        map = minmaxList(args.pickerType, DateType.hour, args.date, mi, ma);
        selected = indexFromValue(args.date.hour, map);

        // set ampm
        final hour = map[selected];
        ampm = DateTimeUtil.ampmContrastMap[hour]?.ampm;

        break;
      case DateType.minute:
        map = minmaxList(args.pickerType, DateType.minute, args.date, mi, ma);
        selected = indexFromValue(args.date.minute, map);
        break;
      case DateType.second:
        map = minmaxList(args.pickerType, DateType.second, args.date, mi, ma);
        selected = indexFromValue(args.date.second, map);
        break;
    }

    return BoardPickerItemOption(
      args: args,
      focusNode: PickerItemFocusNode(),
      itemMap: map,
      selectedIndex: selected,
      minimumDate: mi,
      maximumDate: ma,
      ampm: ampm,
    );
  }

  /// Constractor for year item
  factory BoardPickerItemOption.year({required ItemOptionArgs args}) {
    final minY = args.minimum?.year ?? DateTimeUtil.minimumYear;

    // Define specified minimum and maximum dates
    final mi = args.minimum ?? DateTime(DateTimeUtil.minimumYear, 1, 1, 0, 0);
    final ma =
        args.maximum ?? DateTime(DateTimeUtil.maximumYear, 12, 31, 23, 59);

    final map = minmaxList(args.pickerType, DateType.year, args.date, mi, ma);
    return BoardPickerItemOption(
      args: args,
      focusNode: PickerItemFocusNode(),
      itemMap: map,
      selectedIndex: indexFromValue(max(args.date.year, minY), map),
      minimumDate: mi,
      maximumDate: ma,
      ampm: null,
    );
  }

  /// Max Length for TextField
  int get maxLength {
    if (type == DateType.year) {
      return 4;
    } else if (type == DateType.month) {
      if (monthFormat == PickerMonthFormat.number) {
        return 2;
      } else if (monthFormat == PickerMonthFormat.long && args.wide()) {
        final maxLength = monthMap()
            .values
            .reduce((a, b) => a.length > b.length ? a : b)
            .length;
        return maxLength;
      } else {
        return 3;
      }
    }

    return 2;
  }

  /// Flex for Row children
  int get flex {
    if (type == DateType.year) {
      return 2;
    } else if (type == DateType.month &&
        monthFormat == PickerMonthFormat.long &&
        args.wide()) {
      return 2;
    }
    return 1;
  }

  void changeDate(DateTime date) {
    switch (type) {
      case DateType.year:
        selectedIndex = _getIndexFromValue(date.year) ?? 0;
        break;
      case DateType.month:
        selectedIndex = _getIndexFromValue(date.month) ?? 0;
        break;
      case DateType.day:
        selectedIndex = _getIndexFromValue(date.day) ?? 0;
        break;
      case DateType.hour:
        selectedIndex = _getIndexFromValue(date.hour) ?? 0;

        // set ampm
        final hour = itemMap[selectedIndex];
        ampm = DateTimeUtil.ampmContrastMap[hour]?.ampm;
        break;
      case DateType.minute:
        selectedIndex = _getIndexFromValue(date.minute) ?? 0;
        break;
      case DateType.second:
        selectedIndex = _getIndexFromValue(date.second) ?? 0;
        break;
    }
    stateKey.currentState?.toAnimateChange(selectedIndex, button: true);
  }

  /// Get the map index from the value and return it
  int? _getIndexFromValue(int val) {
    for (final index in itemMap.keys) {
      if (itemMap[index] == val) return index;
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
  int get value => itemMap[selectedIndex]!;

  /// input content check
  void checkInputField() {
    final text = stateKey.currentState?.textController.text;
    if (text != null) {
      try {
        final data = int.parse(text);
        if (itemMap.values.contains(data)) return;
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
    itemMap = minmaxList(pickerType, type, date, minimumDate, maximumDate);
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

    // 指定の月の中で最大の日付を設定する
    // Set the maximum date within a given month
    int year = newDate.year;
    int month = newDate.month;
    if (month == 12) {
      year += 1;
      month = 1;
    } else {
      month += 1;
    }
    final target = DateTime(year, month, 1).add(const Duration(days: -1)).day;
    if (target < maxDay) {
      maxDay = target;
    }

    //  Retrieve existing values
    final tmp = value;

    Map<int, int> newMap = {};
    int index = 0;
    for (var i = minDay; i <= maxDay; i++) {
      newMap[index] = i;
      index++;
    }
    itemMap = newMap;
    updateState(tmp, newDate);
  }

  void updateState(int tmpValue, DateTime date) {
    // Get the index of the value that was selected
    // before the update and update it to that value
    final index = _getIndexFromValue(tmpValue);
    if (index != null) {
      selectedIndex = index;
    } else if (itemMap.values.first > tmpValue) {
      selectedIndex = 0;
    } else if (selectedIndex >= itemMap.keys.length) {
      selectedIndex = itemMap.keys.last;
    }

    if (useAmpm && type == DateType.hour) {
      // set ampm
      final hour = itemMap[selectedIndex];
      ampm = DateTimeUtil.ampmContrastMap[hour]?.ampm;
    }
    stateKey.currentState?.updateState(itemMap, selectedIndex);

    if (useAmpm && ampm != null) {
      ampmStateKey.currentState?.updateState(ampm!);
    }
  }

  void updateAmPm(AmPm ap) {
    if (ampm == ap) return;

    // AMとPMの値に合わせて24時間表記の時間を置き換える
    final hour = itemMap[selectedIndex];

    Map<int, AmpmCotrast> current;
    Map<int, AmpmCotrast> next;
    if (ampm == AmPm.am) {
      current = DateTimeUtil.ampmContrastAmMap;
      next = DateTimeUtil.ampmContrastPmMap;
    } else {
      current = DateTimeUtil.ampmContrastPmMap;
      next = DateTimeUtil.ampmContrastAmMap;
    }

    // 現時点の対比情報を取得する
    final entry = current[hour];
    if (entry != null) {
      // 切り替え先の時間が一致する値を取得する
      final nextEntry = next.entries.firstWhereOrNull(
        (e) => e.value.hour == entry.hour,
      );
      if (nextEntry != null) {
        final index = _getIndexFromValue(nextEntry.key);

        if (index != null) {
          selectedIndex = index;
        } else if (itemMap.values.first > nextEntry.key) {
          selectedIndex = 0;
        } else if (selectedIndex >= itemMap.keys.length) {
          selectedIndex = itemMap.keys.last;
        } else {
          selectedIndex = itemMap.keys.last;
        }
      } else {
        if (itemMap.values.first > entry.index) {
          selectedIndex = 0;
        } else if (selectedIndex >= itemMap.keys.length) {
          selectedIndex = itemMap.keys.last;
        } else {
          selectedIndex = itemMap.keys.last;
        }
      }
    }
    ampm = ap;
  }

  static Map<int, int> minmaxList(
    DateTimePickerType pickerType,
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

    // timeのみの場合は日付が異なると正確な制御ができないため、
    // 日付を合わせる
    List<DateTime> dateForTime(DateTime d, DateTime mi, DateTime ma) {
      if (pickerType == DateTimePickerType.time) {
        final now = DateTime.now();
        return [
          DateTime(now.year, now.month, now.day, d.hour, d.minute, d.second),
          DateTime(now.year, now.month, now.day, mi.hour, mi.minute, mi.second),
          DateTime(now.year, now.month, now.day, ma.hour, ma.minute, ma.second),
        ];
      } else {
        return [d, mi, ma];
      }
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

        // 指定の月の中で最大の日付を設定する
        int year = date.year;
        int month = date.month;
        if (month == 12) {
          year += 1;
          month = 1;
        } else {
          month += 1;
        }
        final target =
            DateTime(year, month, 1).add(const Duration(days: -1)).day;
        if (maxDay > target) {
          maxDay = target;
        }
        return createMap(minDay, maxDay);
      case DateType.hour:
        int minHour = 0;
        int maxHour = 23;
        final dateList = dateForTime(date, minimum, maximum);
        if (dateList[0].isMinimum(dateList[1], DateType.day)) {
          minHour = dateList[1].hour;
        }
        if (dateList[0].isMaximum(dateList[2], DateType.day)) {
          maxHour = dateList[2].hour;
        }
        return createMap(minHour, maxHour);
      case DateType.minute:
        int minMinute = 0;
        int maxMinute = 59;
        final dateList = dateForTime(date, minimum, maximum);
        if (dateList[0].isMinimum(dateList[1], DateType.hour)) {
          minMinute = dateList[1].minute;
        }
        if (dateList[0].isMaximum(dateList[2], DateType.hour)) {
          maxMinute = dateList[2].minute;
        }
        return createMap(minMinute, maxMinute);
      case DateType.second:
        int minSecond = 0;
        int maxSecond = 59;
        final dateList = dateForTime(date, minimum, maximum);
        if (dateList[0].isMinimum(dateList[1], DateType.minute)) {
          minSecond = dateList[1].second;
        }
        if (dateList[0].isMaximum(dateList[2], DateType.minute)) {
          maxSecond = dateList[2].second;
        }
        return createMap(minSecond, maxSecond);
    }
  }

  DateTime calcDate(DateTime date, {int? newDay}) {
    switch (type) {
      case DateType.year:
        return DateTime(
          itemMap[selectedIndex]!,
          date.month,
          newDay ?? date.day,
          date.hour,
          date.minute,
          withSecond ? date.second : 0,
        );
      case DateType.month:
        return DateTime(
          date.year,
          itemMap[selectedIndex]!,
          newDay ?? date.day,
          date.hour,
          date.minute,
          withSecond ? date.second : 0,
        );
      case DateType.day:
        return DateTime(
          date.year,
          date.month,
          newDay ?? itemMap[selectedIndex]!,
          date.hour,
          date.minute,
          withSecond ? date.second : 0,
        );
      case DateType.hour:
        return DateTime(
          date.year,
          date.month,
          date.day,
          itemMap[selectedIndex]!,
          date.minute,
          withSecond ? date.second : 0,
        );
      case DateType.minute:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          itemMap[selectedIndex]!,
          withSecond ? date.second : 0,
        );
      case DateType.second:
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          itemMap[selectedIndex]!,
        );
    }
  }

  bool get isMonthText {
    return type == DateType.month && monthFormat != PickerMonthFormat.number;
  }

  Map<int, String> monthMap() {
    // DateFormat
    final dateFormat = monthFormat == PickerMonthFormat.long && args.wide()
        ? DateFormat.MMMM(locale)
        : DateFormat.MMM(locale);

    final now = DateTime.now();
    final map = <int, String>{};
    for (var i = 1; i <= 12; i++) {
      map[i] = dateFormat.format(DateTime(now.year, i, 1));
    }
    return map;
  }
}
