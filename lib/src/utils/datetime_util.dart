import 'package:board_datetime_picker/src/options/board_item_option.dart';

import 'board_enum.dart';

class DateTimeUtil {
  ///. Default Minimum Date Year
  static const int minimumYear = 1970;

  /// Default Maximum Date Year
  static const int maximumYear = 2050;

  ///. Default Minimum Date
  static DateTime defaultMinDate = DateTime(minimumYear, 1, 1, 0, 0, 0);

  /// Default Maximum Date
  static DateTime defaultMaxDate = DateTime(maximumYear, 12, 31, 23, 59, 59);

  /// List of days of the week beginning on Sunday
  static List<int> weekdayVals = [7, 1, 2, 3, 4, 5, 6];

  /// Update the date when the year or month is changed.
  /// Therefore, get the last date that exists in year and month.
  static int? getExistsMaxDate(
    List<BoardPickerItemOption> options,
    BoardPickerItemOption selected,
    int val,
  ) {
    if (![DateType.year, DateType.month].contains(selected.type)) {
      return null;
    }

    final yearOption = options.firstWhere((x) => x.type == DateType.year);
    final monthOption = options.firstWhere((x) => x.type == DateType.month);

    var year = yearOption.value;
    var month = monthOption.value;

    if (selected.type == DateType.year) {
      year = val;
    } else if (selected.type == DateType.month) {
      month = val;
    }

    month += 1;
    if (month > 12) month = 1;
    final date = DateTime(year, month, 1).addDay(-1);

    return date.day;
  }

  /// If minimum and maximum dates are specified,
  /// check whether they are within the range and return values that fall within the range.
  static DateTime rangeDate(
    DateTime date,
    DateTime? minimumDate,
    DateTime? maximumDate,
  ) {
    DateTime newVal = date;
    if (minimumDate != null && date.isBefore(minimumDate)) {
      newVal = minimumDate;
    } else if (maximumDate != null && date.isAfter(maximumDate)) {
      newVal = maximumDate;
    }
    return newVal;
  }

  static int? existDay(int year, int month, int day) {
    final val = DateTime(year, month, day);
    final same = year == val.year && month == val.month && day == val.day;

    // 指定の日付と実際の変換した値が異なる場合は
    // 日(day)が存在しない範囲である
    if (!same) {
      if (month == 12) {
        year += 1;
        month = 1;
      } else {
        month += 1;
      }
      return DateTime(year, month, 1).add(const Duration(days: -1)).day;
    }
    return null;
  }
}

extension DateTimeExtension on DateTime {
  /// Add day
  /// Generate a new DateTime using the constructor of
  /// DateTime to account for daylight saving time
  DateTime addDay(int v) {
    return DateTime(year, month, day + v);
  }

  DateTime addDayWithTime(int v) {
    return DateTime(year, month, day + v, hour, minute, second);
  }

  bool isMinimum(DateTime date, DateType dt, {bool equal = true}) {
    bool operator(a, b) {
      if (equal) {
        return a <= b;
      }
      return a < b;
    }

    switch (dt) {
      case DateType.year:
        return operator(year, date.year);
      case DateType.month:
        if (year < date.year) return true;
        return year <= date.year && operator(month, date.month);
      case DateType.day:
        if (year < date.year) return true;
        if (year <= date.year && month < date.month) return true;
        return year <= date.year &&
            month <= date.month &&
            operator(day, date.day);
      case DateType.hour:
        if (year < date.year) return true;
        if (year <= date.year && month < date.month) return true;
        if (year <= date.year && month <= date.month && day < date.day) {
          return true;
        }
        return year <= date.year &&
            month <= date.month &&
            day <= date.day &&
            operator(hour, date.hour);
      case DateType.minute:
        if (year < date.year) return true;
        if (year <= date.year && month < date.month) return true;
        if (year <= date.year && month <= date.month && day < date.day) {
          return true;
        }
        if (year <= date.year &&
            month <= date.month &&
            day <= date.day &&
            hour < date.hour) {
          return true;
        }
        return year <= date.year &&
            month <= date.month &&
            day <= date.day &&
            hour <= date.hour &&
            operator(minute, date.minute);

      case DateType.second:
        if (year < date.year) return true;
        if (year <= date.year && month < date.month) return true;
        if (year <= date.year && month <= date.month && day < date.day) {
          return true;
        }
        if (year <= date.year &&
            month <= date.month &&
            day <= date.day &&
            hour < date.hour) {
          return true;
        }
        if (year <= date.year &&
            month <= date.month &&
            day <= date.day &&
            hour <= date.hour &&
            minute < date.minute) {
          return true;
        }
        return year <= date.year &&
            month <= date.month &&
            day <= date.day &&
            hour <= date.hour &&
            minute <= date.minute &&
            operator(second, date.second);
    }
  }

  bool isMaximum(DateTime date, DateType dt, {bool equal = true}) {
    bool operator(a, b) {
      if (equal) {
        return a >= b;
      }
      return a > b;
    }

    switch (dt) {
      case DateType.year:
        return operator(year, date.year);
      case DateType.month:
        if (year > date.year) return true;
        return year >= date.year && operator(month, date.month);
      case DateType.day:
        if (year > date.year) return true;
        if (year >= date.year && month > date.month) return true;
        return year >= date.year &&
            month >= date.month &&
            operator(day, date.day);
      case DateType.hour:
        if (year > date.year) return true;
        if (year >= date.year && month > date.month) return true;
        if (year >= date.year && month >= date.month && day > date.day) {
          return true;
        }
        return year >= date.year &&
            month >= date.month &&
            day >= date.day &&
            operator(hour, date.hour);
      case DateType.minute:
        if (year > date.year) return true;
        if (year >= date.year && month > date.month) return true;
        if (year >= date.year && month >= date.month && day > date.day) {
          return true;
        }
        if (year >= date.year &&
            month >= date.month &&
            day >= date.day &&
            hour > date.hour) {
          return true;
        }
        return year >= date.year &&
            month >= date.month &&
            day >= date.day &&
            hour >= date.hour &&
            operator(minute, date.minute);

      case DateType.second:
        if (year > date.year) return true;
        if (year >= date.year && month > date.month) return true;
        if (year >= date.year && month >= date.month && day > date.day) {
          return true;
        }
        if (year >= date.year &&
            month >= date.month &&
            day >= date.day &&
            hour > date.hour) {
          return true;
        }
        if (year >= date.year &&
            month >= date.month &&
            day >= date.day &&
            hour >= date.hour &&
            minute > date.minute) {
          return true;
        }

        return year >= date.year &&
            month >= date.month &&
            day >= date.day &&
            hour >= date.hour &&
            minute >= date.minute &&
            operator(second, date.second);
    }
  }

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
        nextYear += nextMonth ~/ 12;
        nextMonth = x;
      }
      date = DateTime(nextYear, nextMonth, 1);
    } else if (diff < 0) {
      DateTime x0 = DateTime(date.year, date.month, 1);
      for (var i = 0; i < diff.abs(); i++) {
        final y = x0.addDay(-1);
        x0 = DateTime(y.year, y.month, 1);
      }
      date = x0;
    }
    return date;
  }

  /// Check if the date is within the specified range
  bool isWithinRange(DateTime minimum, DateTime maximum) {
    return isAfter(minimum) && isBefore(maximum);
  }

  /// Check if only dates are within the specified range
  bool isWithinRangeAndEqualsDate(DateTime minimum, DateTime maximum) {
    final result = isAfter(minimum) && isBefore(maximum);
    if (result) {
      return result;
    }

    if (minimum.year == year && minimum.month == month && minimum.day == day) {
      return true;
    } else if (maximum.year == year &&
        maximum.month == month &&
        maximum.day == day) {
      return true;
    }
    return false;
  }

  /// Obtain a value of a specified type from DateTime
  int valFromType(DateType type) {
    switch (type) {
      case DateType.year:
        return year;
      case DateType.month:
        return month;
      case DateType.day:
        return day;
      case DateType.hour:
        return hour;
      case DateType.minute:
        return minute;
      case DateType.second:
        return second;
    }
  }
}
