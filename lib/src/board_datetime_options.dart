import 'package:flutter/material.dart';

/// Class for defining options related to the UI used by [BoardDateTimeBuilder]
class BoardDateTimeOptions {
  const BoardDateTimeOptions({
    this.backgroundColor,
    this.foregroundColor,
    this.textColor,
    this.activeColor,
    this.activeTextColor,
    this.backgroundDecoration,
    this.languages = const BoardPickerLanguages.en(),
    this.customOptions,
    this.startDayOfWeek = DateTime.sunday,
    this.pickerFormat = PickerFormat.ymd,
    this.showDateButton = true,
    this.boardTitle,
    this.boardTitleTextStyle,
    this.pickerSubTitles,
    this.weekend,
    this.inputable = true,
    this.withSecond = false,
    this.topMargin = 20,
    this.actionButtonTypes = const [
      BoardDateButtonType.today,
      BoardDateButtonType.tomorrow
    ],
  });

  /// #### Picker Background Color
  /// default is `Theme.of(context).scaffoldBackgroundColor`
  final Color? backgroundColor;

  /// #### Picket Foreground Color
  /// default is `Theme.of(context).cardColor`
  final Color? foregroundColor;

  /// #### Picker Text Color
  /// default is `Theme.of(context).textTheme.bodyLarge?.color`
  final Color? textColor;

  /// #### Active Color
  /// Use the color of the currently selected date or button
  /// in the calendar as a color to indicate the selection status.
  /// If not specified, `Theme.of(context).primaryColor` color by default.
  final Color? activeColor;

  /// #### Active Text Color
  /// activeColor is used as the background color and activeTextColor as the text color.
  /// Default color is white.
  final Color? activeTextColor;

  /// BoxDecoration of the widget displayed on the backmost side of the picker.
  /// If not specified, it will be a standard BoxDecoration with
  /// the color specified in the normal backgroundColor (default).
  ///
  /// If both [backgroundColor] and backgroundColor are specified, this one takes precedence.
  final BoxDecoration? backgroundDecoration;

  /// Class for specifying language information to be used in the picker
  final BoardPickerLanguages languages;

  /// Option to specify items to be displayed in the picker by date and time.
  /// Only time can be specified.
  ///
  /// example:
  /// ```
  /// customOptions: BoardPickerCustomOptions.every15minutes(),
  /// ```
  /// Picker will show [0, 15, 30, 45].
  final BoardPickerCustomOptions? customOptions;

  /// First day of the week in the calendar.
  /// Defailt is `DateTime.sunday`.
  ///
  /// example:
  /// ```dart
  /// calendarStartWeekday: DateTime.monday,
  /// ```
  final int startDayOfWeek;

  /// Date format for pickers.
  /// Specify if you want to change the display order of year, month, date.
  ///
  /// - y: Year
  /// - m: Month
  /// - d: Day
  ///
  /// Default is `PickerFormat.ymd`
  ///
  final BoardDateTimePickerFormat pickerFormat;

  /// Flag whether or not the button to set the date should be displayed.
  /// If false, do not display buttons such as "today", "tomorrow", etc.
  /// at the top of the picker, only the action buttons. Default is true.
  ///
  /// When setting to false, it is recommended to specify the title together.
  final bool showDateButton;

  /// Title to be displayed at the top of the picker
  final String? boardTitle;

  /// BoardTitle text style
  final TextStyle? boardTitleTextStyle;

  /// You can specify a subtitle for each item in the picker.
  /// Default is unspecified and no subtitle is displayed.
  ///
  /// If specified halfway, defaults to the specified value.
  final BoardDateTimeItemTitles? pickerSubTitles;

  /// Option to configure settings related to weekends
  /// Used to set the text color to be displayed
  final BoardPickerWeekendOptions? weekend;

  /// Flag whether the date to be selected should be text-enabled or not.
  /// If `true`, text can be entered by tapping on the selected area of the Picker.
  /// If `false`, text input is not possible, only scrolling picker.
  /// Default is `true`.
  final bool inputable;

  /// Flag to allow seconds to be specified.
  /// This parameter is only valid if `DateTimePickerType` is `time`.
  /// The `datetime` case is not supported at this time due to width issues.
  final bool withSecond;

  /// Set the margins above the top menu bar (calendar button, etc.).
  /// Default is `20`
  final double topMargin;

  /// List of buttons to select dates.
  /// Set the enum you want to display with a choice of yesterday, today, or tomorrow.
  /// The order in which the buttons are displayed must match the order of the list,
  /// and if empty, they will not be displayed.
  final List<BoardDateButtonType> actionButtonTypes;
}

enum BoardDateButtonType { yesterday, today, tomorrow }

/// Optional settings for weekends
class BoardPickerWeekendOptions {
  /// Colors for displaying Saturday.
  /// Default color is `Colors.blue`
  final Color saturdayColor;

  /// Colors for displaying Sunday.
  /// Default Color is `Colors.red`
  final Color sundayColor;

  const BoardPickerWeekendOptions({
    this.saturdayColor = Colors.blue,
    this.sundayColor = Colors.red,
  });
}

/// Class for specifying the language to be displayed
class BoardPickerLanguages {
  /// Button text to move date to today.
  /// Default is [TODAY].
  final String today;

  /// Button text to move date to tomorrow.
  /// Default is [TOMORROW].
  final String tomorrow;

  /// Button text to move date to yesterday.
  /// Default is [YESTERDAY].
  final String yesterday;

  /// Button text to move date/time to current time
  /// Default is [NOW].
  final String now;

  /// Locale to be displayed in the calendar
  /// Default is [en]
  final String locale;

  static const _enToday = 'TODAY';
  static const _enTomorrow = 'TOMORROW';
  static const _enYesterday = 'YESTERDAY';
  static const _enNow = 'NOW';

  const BoardPickerLanguages({
    this.today = _enToday,
    this.tomorrow = _enTomorrow,
    this.yesterday = _enYesterday,
    this.now = _enNow,
    this.locale = 'en',
  });

  /// Constructor in English notation
  const BoardPickerLanguages.en()
      : today = _enToday,
        tomorrow = _enTomorrow,
        yesterday = _enYesterday,
        now = _enNow,
        locale = 'en';

  /// Constructor in Japanese notation
  const BoardPickerLanguages.ja()
      : today = '今日',
        tomorrow = '明日',
        yesterday = '昨日',
        now = '現在',
        locale = 'ja';

  /// Constructor in Italian notation
  const BoardPickerLanguages.it()
      : today = 'oggi',
        tomorrow = 'domani',
        yesterday = 'ieri',
        now = 'adesso',
        locale = 'it';
}

/// Class specifying custom items to be displayed in the picker.
/// (time only)
class BoardPickerCustomOptions {
  /// List to be displayed in the picker of the year.
  // final List<int> years;

  /// List to be displayed in the picker of the month.
  // final List<int> months;

  /// List to be displayed in the picker of the day.
  // final List<int> days;

  /// List to be displayed in the picker of the hour.
  final List<int> hours;

  /// List to be displayed in the picker of the minute.
  final List<int> minutes;

  /// List to be displayed in the picker of the second.
  final List<int> seconds;

  BoardPickerCustomOptions({
    // this.years = const [],
    // this.months = const [],
    // this.days = const [],
    this.hours = const [],
    this.minutes = const [],
    this.seconds = const [],
  });

  /// Picker display every 15 minutes
  factory BoardPickerCustomOptions.every15minutes() => BoardPickerCustomOptions(
        minutes: [0, 15, 30, 45],
      );
}

typedef BoardDateTimePickerFormat = String;

/// Definition of possible values for the picker format
class PickerFormat {
  /// year - month - day
  static const BoardDateTimePickerFormat ymd = 'yMd';

  /// month - day - yaer
  static const BoardDateTimePickerFormat mdy = 'Mdy';

  /// day - month - yaer
  static const BoardDateTimePickerFormat dmy = 'dMy';
}

/// Specify the title of each item to be displayed in the picker.
///
/// If none is specified, the item title is unspecified.
/// The default value is used to compensate for the missing items.
class BoardDateTimeItemTitles {
  final String? year;
  final String? month;
  final String? day;
  final String? hour;
  final String? minute;
  final String? second;

  const BoardDateTimeItemTitles({
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
  });

  bool get notSpecified {
    return year == null &&
        month == null &&
        day == null &&
        hour == null &&
        minute == null &&
        second == null;
  }
}
