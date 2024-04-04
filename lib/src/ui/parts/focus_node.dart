import 'package:flutter/material.dart';

class BoardDateTimeInputFocusNode extends FocusNode {
  BoardDateTimeInputFocusNode({
    super.onKeyEvent,
    super.skipTraversal = false,
    super.canRequestFocus = true,
    super.descendantsAreFocusable = true,
    super.descendantsAreTraversable = true,
    super.debugLabel,
  });
}

class PickerItemFocusNode extends FocusNode {}

class PickerWheelItemFocusNode extends FocusNode {}

class PickerContentsFocusNode extends FocusNode {
  PickerContentsFocusNode({
    super.onKeyEvent,
    super.skipTraversal = false,
    super.canRequestFocus = true,
    super.descendantsAreFocusable = true,
    super.descendantsAreTraversable = true,
    super.debugLabel,
  });
}
