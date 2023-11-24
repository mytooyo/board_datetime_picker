import 'board_enum.dart';

/// Common classes for returning results.
///
/// Only classes that inherit from this class can be specified as the return class
abstract class BoardDateTimeCommonResult {
  const BoardDateTimeCommonResult();

  static BoardDateTimeCommonResult init(
      DateTimePickerType pickerType, DateTime date) {
    switch (pickerType) {
      case DateTimePickerType.datetime:
        return BoardDateTimeResult(
          year: date.year,
          month: date.month,
          day: date.day,
          hour: date.hour,
          minute: date.minute,
        );
      case DateTimePickerType.date:
        return BoardDateResult(
          year: date.year,
          month: date.month,
          day: date.day,
        );
      case DateTimePickerType.time:
        return BoardTimeResult(
          hour: date.hour,
          minute: date.minute,
        );
    }
  }
}

class BoardDateTimeResult extends BoardDateTimeCommonResult {
  /// Year of the selected date and time
  final int year;

  /// Month of the selected date and time
  final int month;

  /// Day of the selected date and time
  final int day;

  /// Hour of the selected date and time
  final int hour;

  /// Minute of the selected date and time
  final int minute;

  const BoardDateTimeResult({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
  });
}

class BoardDateResult extends BoardDateTimeCommonResult {
  /// Year of the selected date and time
  final int year;

  /// Month of the selected date and time
  final int month;

  /// Day of the selected date and time
  final int day;

  const BoardDateResult({
    required this.year,
    required this.month,
    required this.day,
  });
}

class BoardTimeResult extends BoardDateTimeCommonResult {
  /// Hour of the selected date and time
  final int hour;

  /// Minute of the selected date and time
  final int minute;

  const BoardTimeResult({
    required this.hour,
    required this.minute,
  });
}
