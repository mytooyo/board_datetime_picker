import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/options/board_item_option.dart';
import 'package:collection/collection.dart';

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

  /// Push [minimum] forward to the earliest hour/minute/second that is
  /// actually reachable given the configured [custom] hour/minute/second
  /// lists (e.g. a 15-minute step picker).
  ///
  /// Without this, a minimum such as 9:46 combined with minute steps
  /// [0, 15, 30, 45] leaves the picker with an empty minute list for hour 9
  /// (no step is >= 46), since nothing ever advances the boundary hour to
  /// one where a step actually exists.
  static DateTime normalizeMinimumForCustomOptions(
    DateTime minimum,
    BoardPickerCustomOptions? custom,
  ) {
    if (custom == null) return minimum;
    var result = minimum;
    if (custom.seconds.isNotEmpty) {
      result = _ceilField(result, custom.seconds, DateType.second);
    }
    if (custom.minutes.isNotEmpty) {
      result = _ceilField(result, custom.minutes, DateType.minute);
    }
    if (custom.hours.isNotEmpty) {
      result = _ceilField(result, custom.hours, DateType.hour);
    }
    return result;
  }

  /// Pull [maximum] back to the latest hour/minute/second that is actually
  /// reachable given the configured [custom] hour/minute/second lists.
  ///
  /// Symmetric to [normalizeMinimumForCustomOptions]: a maximum of 8:59 with
  /// minute steps [0, 15, 30, 45] becomes 8:45, the last step that still
  /// satisfies the maximum.
  static DateTime normalizeMaximumForCustomOptions(
    DateTime maximum,
    BoardPickerCustomOptions? custom,
  ) {
    if (custom == null) return maximum;
    var result = maximum;
    if (custom.seconds.isNotEmpty) {
      result = _floorField(result, custom.seconds, DateType.second);
    }
    if (custom.minutes.isNotEmpty) {
      result = _floorField(result, custom.minutes, DateType.minute);
    }
    if (custom.hours.isNotEmpty) {
      result = _floorField(result, custom.hours, DateType.hour);
    }
    return result;
  }

  /// Set [date]'s [type] field to the smallest [values] entry >= its
  /// current value. If none exists, wrap to the smallest entry and carry
  /// one unit into the next coarser field (e.g. minute -> hour).
  static DateTime _ceilField(DateTime date, List<int> values, DateType type) {
    final sorted = [...values]..sort();
    final current = date.valFromType(type);
    final next = sorted.firstWhereOrNull((v) => v >= current);
    if (next != null) {
      return date._withField(type, next);
    }
    return date._withField(type, sorted.first)._stepParentUnit(type, 1);
  }

  /// Set [date]'s [type] field to the largest [values] entry <= its
  /// current value. If none exists, wrap to the largest entry and carry
  /// one unit back from the next coarser field (e.g. minute -> hour).
  static DateTime _floorField(DateTime date, List<int> values, DateType type) {
    final sorted = [...values]..sort();
    final current = date.valFromType(type);
    final prev = sorted.lastWhereOrNull((v) => v <= current);
    if (prev != null) {
      return date._withField(type, prev);
    }
    return date._withField(type, sorted.last)._stepParentUnit(type, -1);
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

  static Map<int, AmpmContrast> ampmContrastMap = {
    ...ampmContrastAmMap,
    ...ampmContrastPmMap,
  };

  static Map<int, AmpmContrast> ampmContrastAmMap = {
    0: AmpmContrast.am(12, 0),
    for (var i = 1; i <= 11; i++) i: AmpmContrast.am(i, i),
  };

  static Map<int, AmpmContrast> ampmContrastPmMap = {
    12: AmpmContrast.pm(12, 0),
    for (var i = 13; i <= 23; i++) i: AmpmContrast.pm(i - 12, i - 12),
  };
}

class AmpmContrast {
  final AmPm ampm;
  final int hour;
  final int index;

  AmpmContrast({required this.ampm, required this.hour, required this.index});

  factory AmpmContrast.am(int hour, int index) {
    return AmpmContrast(
      ampm: AmPm.am,
      hour: hour,
      index: index,
    );
  }

  factory AmpmContrast.pm(int hour, int index) {
    return AmpmContrast(
      ampm: AmPm.pm,
      hour: hour,
      index: index,
    );
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

  /// Returns a copy of this date with [type]'s field replaced by [value].
  /// Only hour, minute and second are supported (the only types that can
  /// carry a custom step list).
  DateTime _withField(DateType type, int value) {
    switch (type) {
      case DateType.hour:
        return DateTime(year, month, day, value, minute, second);
      case DateType.minute:
        return DateTime(year, month, day, hour, value, second);
      case DateType.second:
        return DateTime(year, month, day, hour, minute, value);
      default:
        return this;
    }
  }

  /// Steps the field one level coarser than [type] by [direction]
  /// (+1/-1), letting [DateTime] normalize any overflow/underflow
  /// (e.g. hour 24 rolls into the next day).
  DateTime _stepParentUnit(DateType type, int direction) {
    switch (type) {
      case DateType.second:
        return DateTime(year, month, day, hour, minute + direction, second);
      case DateType.minute:
        return DateTime(year, month, day, hour + direction, minute, second);
      case DateType.hour:
        return DateTime(year, month, day + direction, hour, minute, second);
      default:
        return this;
    }
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
