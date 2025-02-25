import 'dart:math';

import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';

import '../ui/parts/focus_node.dart';
import 'board_item_option.dart';

/// Options for customizing the items displayed in the picker.
/// Create at each date and time.
class BoardPickerCustomItemOption extends BoardPickerItemOption {
  BoardPickerCustomItemOption({
    required super.args,
    required this.customList,
    required super.focusNode,
    required super.itemMap,
    required super.selectedIndex,
    required super.minimumDate,
    required super.maximumDate,
    required super.ampm,
  });

  final List<int> customList;

  factory BoardPickerCustomItemOption.init({required ItemOptionArgs args}) {
    Map<int, int> map = {};
    int selected;

    // Define specified minimum and maximum dates
    final mi = args.minimum ?? DateTimeUtil.defaultMinDate;
    final ma = args.maximum ?? DateTimeUtil.defaultMaxDate;

    if (args.type == DateType.year) {
      final list =
          args.customList!.where((x) => x >= mi.year && x <= ma.year).toList();
      for (var i = 0; i < list.length; i++) {
        map[i] = list[i];
      }
    } else {
      final m = BoardPickerItemOption.minmaxList(
        args.pickerType,
        args.type,
        args.date,
        mi,
        ma,
      );
      final values = m.values.toList();
      int count = 0;
      for (var i = 0; i < values.length; i++) {
        final val = values[i];
        if (args.customList!.contains(val)) {
          map[count] = val;
          count++;
        }
      }
    }

    switch (args.type) {
      case DateType.year:
        final minY = args.minimum?.year ?? DateTimeUtil.minimumYear;
        selected = BoardPickerItemOption.indexFromValue(
          max(args.date.year, minY),
          map,
        );
        break;
      case DateType.month:
        selected = BoardPickerItemOption.indexFromValue(args.date.month, map);
        break;
      case DateType.day:
        selected = BoardPickerItemOption.indexFromValue(args.date.day, map);
        break;
      case DateType.hour:
        selected = BoardPickerItemOption.indexFromValue(args.date.hour, map);
        break;
      case DateType.minute:
        selected = BoardPickerItemOption.indexFromValue(args.date.minute, map);
        break;
      case DateType.second:
        selected = BoardPickerItemOption.indexFromValue(args.date.second, map);
        break;
    }

    return BoardPickerCustomItemOption(
      args: args,
      focusNode: PickerItemFocusNode(),
      itemMap: map,
      selectedIndex: selected,
      minimumDate: mi,
      maximumDate: ma,
      ampm: null,
      customList: args.customList!,
    );
  }

  @override
  void updateList(DateTime date) {
    //  Retrieve existing values
    final tmp = value;
    // Generate new maps
    final m = BoardPickerItemOption.minmaxList(
      pickerType,
      type,
      date,
      minimumDate,
      maximumDate,
    );
    final values = m.values.toList();

    Map<int, int> newMap = {};

    int count = 0;
    for (var i = 0; i < values.length; i++) {
      final val = values[i];
      if (customList.contains(val)) {
        newMap[count] = val;
        count++;
      }
    }
    itemMap = newMap;
    updateState(tmp, date);
  }

  @override
  void updateDayMap(int maxDay, DateTime newDate) {
    int minDay = 1;
    int maxDay = 31;
    if (newDate.isMinimum(minimumDate, DateType.month)) {
      minDay = minimumDate.day;
    }
    if (newDate.isMaximum(maximumDate, DateType.month)) {
      maxDay = min(maxDay, maximumDate.day);
    } else {
      // 指定の月の中で最大の日付を設定する
      int year = newDate.year;
      int month = newDate.month;
      if (month == 12) {
        year += 1;
        month = 1;
      } else {
        month += 1;
      }
      maxDay = DateTime(year, month, 1).add(const Duration(days: -1)).day;
    }

    //  Retrieve existing values
    final tmp = value;

    Map<int, int> newMap = {};
    int index = 0;
    for (var i = minDay; i <= maxDay; i++) {
      if (customList.contains(i)) {
        newMap[index] = i;
        index++;
      }
    }
    itemMap = newMap;
    updateState(tmp, newDate);
  }
}
