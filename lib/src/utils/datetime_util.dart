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

  /// Pushes [minimum] forward to the earliest reachable hour/minute/second
  /// given the [custom] step lists. Resolves hour, then minute, then second;
  /// once a field moves past its original value, everything below it resets
  /// to its smallest value (e.g. 8:30 with hours 9-17 becomes 9:00, not 9:30).
  static DateTime normalizeMinimumForCustomOptions(
    DateTime minimum,
    BoardPickerCustomOptions? custom,
  ) {
    if (custom == null) return minimum;
    if (custom.hours.isEmpty &&
        custom.minutes.isEmpty &&
        custom.seconds.isEmpty) {
      return minimum;
    }

    final hours = _stepList(custom.hours, 24);
    final minutes = _stepList(custom.minutes, 60);
    final seconds = _stepList(custom.seconds, 60);

    var h = minimum.hour;
    var m = minimum.minute;
    var s = minimum.second;
    var dayCarry = 0;

    while (true) {
      final hh = hours.firstWhereOrNull((v) => v >= h);
      if (hh == null) {
        h = hours.first;
        m = minutes.first;
        s = seconds.first;
        dayCarry = 1;
        break;
      }
      if (hh > h) {
        h = hh;
        m = minutes.first;
        s = seconds.first;
        break;
      }
      final mm = minutes.firstWhereOrNull((v) => v >= m);
      if (mm == null) {
        h += 1;
        m = 0;
        s = 0;
        continue;
      }
      if (mm > m) {
        h = hh;
        m = mm;
        s = seconds.first;
        break;
      }
      final ss = seconds.firstWhereOrNull((v) => v >= s);
      if (ss == null) {
        m += 1;
        s = 0;
        continue;
      }
      h = hh;
      m = mm;
      s = ss;
      break;
    }

    return DateTime(minimum.year, minimum.month, minimum.day + dayCarry, h, m,
        s);
  }

  /// Symmetric to [normalizeMinimumForCustomOptions]: pulls [maximum] back
  /// to the latest reachable value, resetting fields below a moved one to
  /// their largest value (e.g. 18:10 with hours 9-17 becomes 17:45, not 17:00).
  static DateTime normalizeMaximumForCustomOptions(
    DateTime maximum,
    BoardPickerCustomOptions? custom,
  ) {
    if (custom == null) return maximum;
    if (custom.hours.isEmpty &&
        custom.minutes.isEmpty &&
        custom.seconds.isEmpty) {
      return maximum;
    }

    final hours = _stepList(custom.hours, 24);
    final minutes = _stepList(custom.minutes, 60);
    final seconds = _stepList(custom.seconds, 60);

    var h = maximum.hour;
    var m = maximum.minute;
    var s = maximum.second;
    var dayCarry = 0;

    while (true) {
      final hh = hours.lastWhereOrNull((v) => v <= h);
      if (hh == null) {
        h = hours.last;
        m = minutes.last;
        s = seconds.last;
        dayCarry = -1;
        break;
      }
      if (hh < h) {
        h = hh;
        m = minutes.last;
        s = seconds.last;
        break;
      }
      final mm = minutes.lastWhereOrNull((v) => v <= m);
      if (mm == null) {
        h -= 1;
        m = 59;
        s = 59;
        continue;
      }
      if (mm < m) {
        h = hh;
        m = mm;
        s = seconds.last;
        break;
      }
      final ss = seconds.lastWhereOrNull((v) => v <= s);
      if (ss == null) {
        m -= 1;
        s = 59;
        continue;
      }
      h = hh;
      m = mm;
      s = ss;
      break;
    }

    return DateTime(maximum.year, maximum.month, maximum.day + dayCarry, h, m,
        s);
  }

  /// [custom] sorted, or the full `0..fallbackLength-1` range if unset.
  static List<int> _stepList(List<int> custom, int fallbackLength) {
    if (custom.isEmpty) {
      return List<int>.generate(fallbackLength, (i) => i);
    }
    return [...custom]..sort();
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
