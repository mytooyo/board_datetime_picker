import 'package:board_datetime_picker/src/utils/board_option.dart';

import 'board_enum.dart';

class DateTimeUtil {
  /// Update the date when the year or month is changed.
  /// Therefore, get the last date that exists in year and month.
  static int? getExistsDate(
    List<BoardPickerItemOption> options,
    BoardPickerItemOption selected,
    int val,
  ) {
    if (![DateType.year, DateType.month].contains(selected.type)) {
      return null;
    }

    var year = options.firstWhere((x) => x.type == DateType.year).selected;
    var month = options.firstWhere((x) => x.type == DateType.month).selected;

    if (selected.type == DateType.year) {
      year = val;
    } else if (selected.type == DateType.month) {
      month = val;
    }

    month += 1;
    if (month > 12) month = 1;
    final date = DateTime(year, month, 1).add(const Duration(days: -1));

    return date.day;
  }
}

extension DateTimeExtension on DateTime {
  bool compareDate(DateTime d1) {
    return d1.year == year && d1.month == month && d1.day == day;
  }

  DateTime calcMonth(int diff) {
    DateTime date = this;
    if (diff > 0) {
      var nextYear = year;
      var nextMonth = month + diff;

      if (month >= 12) {
        final x = nextMonth % 12;
        nextYear += x;
        nextMonth = nextMonth ~/ 12;
      }
      date = DateTime(nextYear, nextMonth, 1);
    } else if (diff < 0) {
      DateTime x0 = DateTime(date.year, date.month, 1);
      for (var i = 0; i < diff.abs(); i++) {
        final y = x0.add(const Duration(days: -1));
        x0 = DateTime(y.year, y.month, 1);
      }
      date = x0;
    }
    return date;
  }
}
