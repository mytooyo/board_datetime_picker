import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProviderData extends ChangeNotifier {
  DateTime date = DateTime.now();

  final textController = BoardDateTimeTextController();

  void setDate(DateTime d) {
    date = d;
    notifyListeners();
  }
}

class ProviderParentWidget extends StatelessWidget {
  const ProviderParentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var providerData = Provider.of<ProviderData>(context, listen: true);
    return Scaffold(
      appBar: AppBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: BoardDateTimeInputField(
          controller: providerData.textController,
          pickerType: DateTimePickerType.datetime,
          options: const BoardDateTimeOptions(
            languages: BoardPickerLanguages.en(),
          ),
          initialDate: providerData.date,
          maximumDate: DateTime(2040),
          minimumDate: DateTime(1900, 1, 1),
          textStyle: Theme.of(context).textTheme.bodyMedium,
          onChanged: (date) {},
          onFocusChange: (val, date, text) {
            if (date != null) {
              providerData.setDate(date);
            }
            // print('onFocus Changed, $val, $date, $text');
          },
          showPicker: false,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          providerData.textController.setDate(DateTime.now());
        },
      ),
    );
  }
}
