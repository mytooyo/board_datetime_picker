import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';

void main() {
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
      ),
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

  @override
  Widget build(BuildContext context) {
    return BoardDateTimeBuilder(
      controller: controller,
      resizeBottom: true,
      options: BoardDateTimeOptions(
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
        languages: const BoardPickerLanguages.en(),
      ),
      minimumDate: DateTime(2023, 12, 15),
      maximumDate: DateTime(2024, 12, 31),
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
                ],
              ),
            ),
          ),
        );
      },
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
          widget.controller.open(widget.type, d);
          // Open without date specification
          // widget.controller.openPicker();
          widget.onOpen(widget.type);
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
