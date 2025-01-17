enum DateTimePickerType { date, time, datetime }

enum DateType { year, month, day, hour, minute, second }

enum MultiCurrentDateType { start, end }

enum AmPm {
  am('AM'),
  pm('PM');

  const AmPm(this.display);

  final String display;
}
