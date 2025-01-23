import 'package:flutter/material.dart';

typedef CalendarSelectionBuilder = Widget Function(
    BuildContext context, String day, TextStyle? textStyle);

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
    this.calendarSelectionRadius,
    this.actionButtonTypes = const [
      BoardDateButtonType.today,
      BoardDateButtonType.tomorrow
    ],
    this.calendarSelectionBuilder,
    this.useResetButton = false,
    this.useAmpm = false,
    this.separators,
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

  /// Callback to build a Widget that displays the selected item in the calendar.
  /// The date and text style to be displayed as parameters.
  ///
  /// ### example
  /// ```dart
  /// calendarSelectionBuilder: (context, day, textStyle) {
  ///   return Column(
  ///     mainAxisSize: MainAxisSize.min,
  ///     children: [
  ///       Text(day, style: textStyle),
  ///       Padding(
  ///         padding: EdgeInsets.only(top: 2),
  ///         child: Text(
  ///           'selected',
  ///           style: textStyle?.copyWith(
  ///             fontSize: 10,
  ///           ),
  ///         ),
  ///       ),
  ///     ],
  ///   );
  /// },
  /// ```
  final CalendarSelectionBuilder? calendarSelectionBuilder;

  /// Background radius for the date selected in the calendar.
  /// If not specified, display as a circle
  final double? calendarSelectionRadius;

  /// If you want to use the reset button, please set it to true.
  /// The reset button will be displayed on the right side of the header section.
  final bool useResetButton;

  /// Set if the time is to be displayed as AM/PM.
  /// This value is valid only for `DateTimePickerType.time`
  final bool useAmpm;

  /// Specify the separator between items displayed in the Picker.
  /// If not specified, no separator will be displayed.
  /// By default, nothing is specified.
  final BoardDateTimePickerSeparators? separators;
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

enum PickerSeparator {
  /// '/'
  slash('/'),

  /// '-'
  hyphen('-'),

  /// '.'
  period('.'),

  /// ':'
  colon(':'),

  /// ''
  none('');

  final String display;
  const PickerSeparator(this.display);
}

typedef PickerSeparatorBuilder = Widget Function(
  BuildContext context,
  TextStyle? defaultTextStyle,
);

/// [BoardDateTimePickerSeparators] is used to specify the separators for dates and times displayed in the Picker.
///
/// By default, there are no separators.
/// `dateSeparatorBuilder` specifies the widget placed between the year and month,
/// as well as between the month and day.
/// If unspecified, `date` value is displayed (the default is /)
///
/// `timeSeparatorBuilder` specifies the widget placed between the hour and minute.
/// If unspecified, `time` value is displayed (the default is :).
///
/// `dateTimeSeparatorBuilder` specifies the widget placed between the day and hour.
/// If unspecified, `dateTime` value is displayed (the default is none)
/// `dateTimeSeparatorBuilder` and `dateTime` parameter are only valid when the PickerType is set to `datetime`.
///
class BoardDateTimePickerSeparators {
  /// `dateSeparatorBuilder` specifies the widget placed between the year and month,
  /// and between the month
  final PickerSeparatorBuilder? dateSeparatorBuilder;

  /// If unspecified, the date value is displayed (the default is /)
  final PickerSeparator date;

  /// `timeSeparatorBuilder` specifies the widget placed between hours and minutes.
  final PickerSeparatorBuilder? timeSeparatorBuilder;

  /// If unspecified, the time value is displayed (the default is :).
  final PickerSeparator time;

  /// If unspecified, the dateTime value is displayed (the default is none)
  final PickerSeparator dateTime;

  /// `dateTimeSeparatorBuilder` specifies the widget placed between day and hour.
  final PickerSeparatorBuilder? dateTimeSeparatorBuilder;

  const BoardDateTimePickerSeparators({
    this.dateSeparatorBuilder,
    this.timeSeparatorBuilder,
    this.dateTimeSeparatorBuilder,
    this.date = PickerSeparator.slash,
    this.time = PickerSeparator.colon,
    this.dateTime = PickerSeparator.none,
  });
}
