import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';

class CustomLanguageSampleApp extends StatefulWidget {
  const CustomLanguageSampleApp({super.key});

  @override
  State<CustomLanguageSampleApp> createState() => _CustomLanguageSampleApp();
}

class _CustomLanguageSampleApp extends State<CustomLanguageSampleApp> {
  final controller = BoardDateTimeController();

  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    const languages = BoardPickerLanguages(
      today: 'Oggi',
      tomorrow: 'Domani',
      now: 'il corrente',
    );

    const options = BoardDateTimeOptions(
      languages: languages,
    );

    return BoardDateTimeBuilder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              child: Text(
                BoardDateFormat('yyyy/MM/dd').format(date),
              ),
              onPressed: () {
                controller.openPicker();
              },
            ),
          ),
        );
      },
      options: options,
      controller: controller,
      onChange: (val) {
        setState(() => date = val);
      },
    );
  }
}
