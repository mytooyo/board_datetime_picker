library board_datetime_picker;

import 'package:intl/intl.dart';

export 'src/board_datetime_builder.dart'
    show BoardDateTimeController, BoardDateTimeBuilder;
export 'src/board_datetime_options.dart' show BoardDateTimeOptions;
export 'src/utils/board_enum.dart' show DateTimePickerType;

class BoardDateFormat {
  BoardDateFormat(this.f);
  final String f;
  String format(DateTime d) {
    return DateFormat(f).format(d);
  }
}
