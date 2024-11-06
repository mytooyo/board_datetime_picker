import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board DateTime Picker Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 235, 235, 241),
        useMaterial3: false,
      ),
      // home: const Home(),
      home: const MySampleApp(),
    );
  }
}

class MySampleApp extends StatefulWidget {
  const MySampleApp({super.key});

  @override
  State<MySampleApp> createState() => _MySampleAppState();
}

class _MySampleAppState extends State<MySampleApp> {
  final scrollController = ScrollController();
  final controller = BoardDateTimeController();

  final ValueNotifier<DateTime> builderDate = ValueNotifier(DateTime.now());

  @override
  Widget build(BuildContext context) {
    Widget scaffold() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Board DateTime Picker Example'),
        ),
        backgroundColor: const Color.fromARGB(255, 245, 245, 250),
        body: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 560,
              ),
              child: Column(
                children: [
                  SectionWidget(
                    title: 'Form',
                    items: [InputFieldWidget()],
                  ),
                  const SizedBox(height: 24),
                  SectionWidget(
                    title: 'Picker (Single Selection)',
                    items: [
                      PickerItemWidget(
                        pickerType: DateTimePickerType.datetime,
                      ),
                      PickerItemWidget(
                        pickerType: DateTimePickerType.date,
                      ),
                      PickerItemWidget(
                        pickerType: DateTimePickerType.time,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionWidget(
                    title: 'Picker (Multi Selection)',
                    items: [
                      PickerMultiSelectionItemWidget(
                        pickerType: DateTimePickerType.datetime,
                      ),
                      PickerMultiSelectionItemWidget(
                        pickerType: DateTimePickerType.date,
                      ),
                      PickerMultiSelectionItemWidget(
                        pickerType: DateTimePickerType.time,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionWidget(
                    title: 'Builder Picker',
                    items: [
                      PickerBuilderItemWidget(
                        pickerType: DateTimePickerType.datetime,
                        date: builderDate,
                        onOpen: () async {
                          controller.open(
                            DateTimePickerType.datetime,
                            builderDate.value,
                          );
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BoardDateTimeBuilder<BoardDateTimeCommonResult>(
      builder: (context) => scaffold(),
      controller: controller,
      options: const BoardDateTimeOptions(
        languages: BoardPickerLanguages.en(),
        // boardTitle: 'Board Picker',
        // backgroundColor: Colors.black,
        // textColor: Colors.white,
        // foregroundColor: const Color(0xff303030),
        // activeColor: Colors.blueGrey,
        // backgroundDecoration: const BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: <Color>[
        //       Color(0xff1A2980),
        //       Color(0xff26D0CE),
        //     ],
        //   ),
        // ),
        // pickerSubTitles: BoardDateTimeItemTitles(year: 'year'),
        // customOptions: BoardPickerCustomOptions.every15minutes(),
        // customOptions: BoardPickerCustomOptions(
        //   hours: [0, 6, 12, 18],
        //   minutes: [0, 15, 30, 45],
        // ),
        // weekend: BoardPickerWeekendOptions(
        //   sundayColor: Colors.yellow,
        //   saturdayColor: Colors.red,
        // ),
      ),
      // minimumDate: DateTime(2023, 12, 15, 0, 15),
      // maximumDate: DateTime(2024, 12, 31),
      onChange: (val) {
        builderDate.value = val;
      },
    );
  }
}

class SectionWidget extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const SectionWidget({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8, left: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Material(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items,
          ),
        ),
      ],
    );
  }
}

class PickerItemWidget extends StatelessWidget {
  PickerItemWidget({
    super.key,
    required this.pickerType,
  });

  final DateTimePickerType pickerType;

  final ValueNotifier<DateTime> date = ValueNotifier(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final controller = BoardDateTimeController();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await showBoardDateTimePicker(
            context: context,
            pickerType: pickerType,
            // initialDate: DateTime.now(),
            // minimumDate: DateTime.now().add(const Duration(days: 1)),
            options: BoardDateTimeOptions(
              languages: const BoardPickerLanguages.en(),
              startDayOfWeek: DateTime.sunday,
              pickerFormat: PickerFormat.ymd,
              // boardTitle: 'Board Picker',
              // pickerSubTitles: BoardDateTimeItemTitles(year: 'year'),
              withSecond: DateTimePickerType.time == pickerType,
              customOptions: DateTimePickerType.time == pickerType
                  ? BoardPickerCustomOptions(
                      seconds: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55],
                    )
                  : null,
            ),
            // Specify if you want changes in the picker to take effect immediately.
            valueNotifier: date,
            controller: controller,
            // onTopActionBuilder: (context) {
            //   return Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 16),
            //     child: Wrap(
            //       alignment: WrapAlignment.center,
            //       spacing: 8,
            //       children: [
            //         IconButton(
            //           onPressed: () {
            //             controller.changeDateTime(
            //                 date.value.add(const Duration(days: -1)));
            //           },
            //           icon: const Icon(Icons.arrow_back_rounded),
            //         ),
            //         IconButton(
            //           onPressed: () {
            //             controller.changeDateTime(DateTime.now());
            //           },
            //           icon: const Icon(Icons.stop_circle_rounded),
            //         ),
            //         IconButton(
            //           onPressed: () {
            //             controller.changeDateTime(
            //                 date.value.add(const Duration(days: 1)));
            //           },
            //           icon: const Icon(Icons.arrow_forward_rounded),
            //         ),
            //       ],
            //     ),
            //   );
            // },
          );
          if (result != null) {
            date.value = result;
            print('result: $result');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Material(
                color: pickerType.color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(
                    child: Icon(
                      pickerType.icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pickerType.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: date,
                builder: (context, data, _) {
                  return Text(
                    BoardDateFormat(pickerType.formatter(
                      withSecond: DateTimePickerType.time == pickerType,
                    )).format(data),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PickerMultiSelectionItemWidget extends StatelessWidget {
  PickerMultiSelectionItemWidget({
    super.key,
    required this.pickerType,
  });

  final DateTimePickerType pickerType;

  final ValueNotifier<DateTime> start = ValueNotifier(DateTime.now());
  final ValueNotifier<DateTime> end = ValueNotifier(
    DateTime.now().add(const Duration(days: 7)),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await showBoardDateTimeMultiPicker(
            context: context,
            pickerType: pickerType,
            // minimumDate: DateTime.now().add(const Duration(days: 1)),
            startDate: start.value,
            endDate: end.value,
            options: const BoardDateTimeOptions(
              languages: BoardPickerLanguages.en(),
              startDayOfWeek: DateTime.sunday,
              pickerFormat: PickerFormat.ymd,
              // topMargin: 0,
            ),
            // headerWidget: Container(
            //   height: 60,
            //   margin: const EdgeInsets.all((8)),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     border: Border.all(color: Colors.red, width: 4),
            //     borderRadius: BorderRadius.circular(24),
            //   ),
            //   alignment: Alignment.center,
            //   child: Text(
            //     'Header Widget',
            //     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            //           fontWeight: FontWeight.bold,
            //           color: Colors.red,
            //         ),
            //   ),
            // ),
          );
          if (result != null) {
            start.value = result.start;
            end.value = result.end;
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Material(
                color: pickerType.color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(
                    child: Icon(
                      pickerType.icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pickerType.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder(
                    valueListenable: start,
                    builder: (context, data, _) {
                      return Text(
                        BoardDateFormat(pickerType.format).format(data),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder(
                    valueListenable: end,
                    builder: (context, data, _) {
                      return Text(
                        '~ ${BoardDateFormat(pickerType.format).format(data)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PickerBuilderItemWidget extends StatelessWidget {
  const PickerBuilderItemWidget({
    super.key,
    required this.pickerType,
    required this.date,
    required this.onOpen,
  });

  final DateTimePickerType pickerType;
  final ValueNotifier<DateTime> date;
  final void Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          onOpen.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Material(
                color: pickerType.color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(
                    child: Icon(
                      pickerType.icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pickerType.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: date,
                builder: (context, data, _) {
                  return Text(
                    BoardDateFormat(pickerType.format).format(data),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InputFieldWidget extends StatelessWidget {
  InputFieldWidget({super.key});

  final textController = BoardDateTimeTextController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('InputField'),
          ),
          SizedBox(
            width: 140,
            height: 44,
            child: BoardDateTimeInputField(
              controller: textController,
              pickerType: DateTimePickerType.datetime,
              options: const BoardDateTimeOptions(
                languages: BoardPickerLanguages.en(),
                // The following parameters are only for `time`
                // withSecond: true,
              ),
              initialDate: DateTime.now(),
              maximumDate: DateTime(2040),
              minimumDate: DateTime(1900, 1, 1),
              // showPickerType: BoardDateTimeFieldPickerType.mini,
              textStyle: Theme.of(context).textTheme.bodyMedium,
              onChanged: (date) {
                print('onchanged: $date');
              },
              onFocusChange: (val, date, text) {
                print('on focus changed date: $val, $date, $text');
              },
              onResult: (p0) {},
              decoration: InputDecoration(
                fillColor:
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension DateTimePickerTypeExtension on DateTimePickerType {
  String get title {
    switch (this) {
      case DateTimePickerType.date:
        return 'Date';
      case DateTimePickerType.datetime:
        return 'DateTime';
      case DateTimePickerType.time:
        return 'Time';
    }
  }

  IconData get icon {
    switch (this) {
      case DateTimePickerType.date:
        return Icons.date_range_rounded;
      case DateTimePickerType.datetime:
        return Icons.date_range_rounded;
      case DateTimePickerType.time:
        return Icons.schedule_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DateTimePickerType.date:
        return Colors.blue;
      case DateTimePickerType.datetime:
        return Colors.orange;
      case DateTimePickerType.time:
        return Colors.pink;
    }
  }

  String get format {
    switch (this) {
      case DateTimePickerType.date:
        return 'yyyy/MM/dd';
      case DateTimePickerType.datetime:
        return 'yyyy/MM/dd HH:mm';
      case DateTimePickerType.time:
        return 'HH:mm';
    }
  }

  String formatter({bool withSecond = false}) {
    switch (this) {
      case DateTimePickerType.date:
        return 'yyyy/MM/dd';
      case DateTimePickerType.datetime:
        return 'yyyy/MM/dd HH:mm';
      case DateTimePickerType.time:
        return withSecond ? 'HH:mm:ss' : 'HH:mm';
    }
  }
}
