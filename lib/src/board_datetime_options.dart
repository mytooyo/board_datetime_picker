import 'package:flutter/material.dart';

/// Class for defining options related to the UI used by [BoardDateTimeBuilder]
class BoardDateTimeOptions {
  BoardDateTimeOptions({
    this.backgroundColor,
    this.foregroundColor,
    this.textColor,
    this.activeColor,
    this.activeTextColor,
    this.backgroundDecoration,
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
}
