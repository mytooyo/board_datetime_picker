## 2.1.5

* Added the ability to customize the action area.

## 2.1.4

* Fixed a bug onFocusChanged not called.

## 2.1.3

* Added Suport for Custom Header Widget.

## 2.1.2

* Added currentDate getter to BoardDateTimeTextController.

## 2.1.1

* Fixed a bug in the value of the initial state result in modal display.
* Fixed problem with list items not displaying in flutter 3.24.

## 2.1.0

* Added the feature to select seconds for `DateTimePickerType.time`.
  * Use with `withSecond` option.

## 2.0.0

* Added multi-selection feature to allow selection of a range of dates.
  * To use it, call `showBoardDateTimeMultiPicker`.
  * Only modal display is supported.

## 1.6.9

* Bug fixes in web release mode.

## 1.6.8

* Fixed a bug that was not reflected in the `setText` of the `BoardDateTimeTextController`.

## 1.6.7

* Added Picker type to display when text field has focus.

## 1.6.6

* Added option (`inputable`) to allow text input. (Default is `true`)

## 1.6.5

* Fixed an issue where the keyboard and picker overlapped in the input field.

## 1.6.4

* Added support for specifying colors for Saturday and Sunday

## 1.6.3

* Fixed an issue where a non-existent date and time could be selected in the picker.

## 1.6.2

* Fixed a problem input textfield
  
## 1.6.1

* Fixed a problem initialDate

## 1.6.0

* Added `BoardDateTimeInputField` Widget.  
  It is a TextField with autocomplete and check functions.  
  An input field with the same functionality as a regular `TextFormField`, but designed for date entry/selection.  
  Both text field and Picker can be used at the same time.  

## 1.5.0

* Upgrade the package.
* Deprecation removed (weekdays)
  
## 1.4.0

* Support for specifying picker title and item subtitle.
* Support for getting results in other than DateTime.

## 1.3.1

* Fixed a problem with focus shifting and difficulty entering text when entering text.
* Improved operability when using hardware keyboard

## 1.3.0

* Support daylight saving time.
* Support for changing the start day of the week.
* Support for changing the date format of the picker.

## 1.2.1

* Supported locale. The option `weekdays` has been deprecated accordingly.

## 1.2.0

* Added `showBoardDateTimePicker` function for modal bottom sheet.

## 1.1.1

* [Bug fix] Fixed a bug that caused the value passed in the change callback
  to be the current date and time when the picker is displayed if no initial date and time is specified.

## 1.1.0

* Added option to specify the value to be displayed or selectable for the time picker.
* Execute change callback if initial date is outside minimum or maximum range
* [Bug fix] Fixed problem with imps and fields not entering values correctly

## 1.0.3

* Allows minimum and maximum dates to be specified
* Added `openPicker` that can be displayed without arguments when open.
* [Bug fix] Fixed date misalignment issue with calendar paging

## 1.0.2

* Changed to allow specification of language data to be displayed
* [Bug fix] Fixed problem with date buttons not becoming selected

## 1.0.1

* Update README

## 1.0.0

* Release board_datetime_picker
