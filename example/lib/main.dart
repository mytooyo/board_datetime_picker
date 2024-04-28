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
      home: const MyHomePage(title: 'Board DateTime Picker Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = BoardDateTimeController();

  DateTimePickerType? opened;

  final List<GlobalKey<_ItemWidgetState>> keys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey()
  ];

  final textController = BoardDateTimeTextController();

  @override
  Widget build(BuildContext context) {
    return BoardDateTimeBuilder<BoardDateTimeCommonResult>(
      controller: controller,
      resizeBottom: true,
      options: const BoardDateTimeOptions(
        boardTitle: 'Board Picker',
        languages: BoardPickerLanguages.en(),
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
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          backgroundColor: const Color.fromARGB(255, 245, 245, 250),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'BoardDateTimeInputField: ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 160,
                        child: BoardDateTimeInputField(
                          controller: textController,
                          pickerType: DateTimePickerType.datetime,
                          options: const BoardDateTimeOptions(
                            languages: BoardPickerLanguages.en(),
                          ),
                          initialDate: DateTime.now(),
                          maximumDate: DateTime(2040),
                          minimumDate: DateTime(1900, 1, 1),
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                          onChanged: (date) {
                            print('onchanged: $date');
                          },
                          onFocusChange: (val, date, text) {
                            print('on focus changed date: $val, $date, $text');
                          },
                          onResult: (p0) {
                            // print('on result: ${p0.hour}, ${p0.minute}');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  ItemWidget(
                    key: keys[0],
                    type: DateTimePickerType.datetime,
                    controller: controller,
                    onOpen: (type) => opened = type,
                  ),
                  const SizedBox(height: 24),
                  ItemWidget(
                    key: keys[1],
                    type: DateTimePickerType.date,
                    controller: controller,
                    onOpen: (type) => opened = type,
                  ),
                  const SizedBox(height: 24),
                  ItemWidget(
                    key: keys[2],
                    type: DateTimePickerType.time,
                    controller: controller,
                    onOpen: (type) => opened = type,
                  ),
                  const SizedBox(height: 24),
                  const ModalItem(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      onResult: (val) {},
      onChange: (val) {
        int index = -1;
        if (opened == DateTimePickerType.datetime) {
          index = 0;
        } else if (opened == DateTimePickerType.date) {
          index = 1;
        } else if (opened == DateTimePickerType.time) {
          index = 2;
        }
        if (index >= 0) keys[index].currentState?.update(val);
      },
    );
  }
}

class ItemWidget extends StatefulWidget {
  const ItemWidget({
    super.key,
    required this.type,
    required this.controller,
    required this.onOpen,
  });

  final DateTimePickerType type;
  final BoardDateTimeController controller;
  final void Function(DateTimePickerType type) onOpen;

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  DateTime d = DateTime.now();

  void update(DateTime date) {
    setState(() {
      d = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Open without date specification
          // widget.controller.openPicker();
          widget.onOpen(widget.type);
          widget.controller.open(widget.type, d);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Material(
                color: color,
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  BoardDateFormat(format).format(d),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get title {
    switch (widget.type) {
      case DateTimePickerType.date:
        return 'Date';
      case DateTimePickerType.datetime:
        return 'DateTime';
      case DateTimePickerType.time:
        return 'Time';
    }
  }

  IconData get icon {
    switch (widget.type) {
      case DateTimePickerType.date:
        return Icons.date_range_rounded;
      case DateTimePickerType.datetime:
        return Icons.date_range_rounded;
      case DateTimePickerType.time:
        return Icons.schedule_rounded;
    }
  }

  Color get color {
    switch (widget.type) {
      case DateTimePickerType.date:
        return Colors.blue;
      case DateTimePickerType.datetime:
        return Colors.orange;
      case DateTimePickerType.time:
        return Colors.pink;
    }
  }

  String get format {
    switch (widget.type) {
      case DateTimePickerType.date:
        return 'yyyy/MM/dd';
      case DateTimePickerType.datetime:
        return 'yyyy/MM/dd HH:mm';
      case DateTimePickerType.time:
        return 'HH:mm';
    }
  }
}

class ModalItem extends StatefulWidget {
  const ModalItem({super.key});

  @override
  State<ModalItem> createState() => _ModalItemState();
}

class _ModalItemState extends State<ModalItem> {
  DateTime d = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await showBoardDateTimePicker(
            context: context,
            pickerType: DateTimePickerType.datetime,
            options: const BoardDateTimeOptions(
              languages: BoardPickerLanguages.en(),
              startDayOfWeek: DateTime.sunday,
              pickerFormat: PickerFormat.ymd,
              boardTitle: 'Board Picker',
              pickerSubTitles: BoardDateTimeItemTitles(year: 'year'),
            ),
            onResult: (val) {},
          );
          if (result != null) {
            setState(() => d = result);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(4),
                child: const SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: Icon(
                      Icons.open_in_browser_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  BoardDateFormat('yyyy/MM/dd HH:mm').format(d),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                'Show Dialog',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
