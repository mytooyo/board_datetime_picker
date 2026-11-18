import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/options/board_item_option.dart';
import 'package:board_datetime_picker/src/ui/parts/item.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

BoardPickerItemOption _minuteOption() {
  return initItemOption(
    ItemOptionArgs(
      pickerType: DateTimePickerType.time,
      type: DateType.minute,
      date: DateTime(2026, 1, 1, 10, 30),
      minimum: null,
      maximum: null,
      subTitle: null,
      useAmpm: false,
      monthFormat: PickerMonthFormat.number,
      locale: 'en',
      wide: () => false,
      multiSelection: false,
    ),
  );
}

Future<void> _pumpItem(
  WidgetTester tester, {
  required BoardPickerItemOption option,
  required bool inputable,
  required void Function(int) onChange,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 120,
            height: 300,
            child: ItemWidget(
              key: option.stateKey,
              option: option,
              onChange: onChange,
              foregroundColor: Colors.blue,
              textColor: Colors.black,
              showedKeyboard: () => false,
              wide: false,
              subTitle: null,
              inputable: inputable,
              embeddedOptions: const EmbeddedOptions(),
              withSubtitle: false,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // https://github.com/mytooyo/board_datetime_picker/issues/104
  testWidgets(
    'dragging from the selected row scrolls the wheel when not inputable',
    (tester) async {
      final option = _minuteOption();
      final initialIndex = option.selectedIndex;
      int? changedIndex;

      await _pumpItem(
        tester,
        option: option,
        inputable: false,
        onChange: (index) => changedIndex = index,
      );

      // Start the drag on the center (selected) row.
      await tester.dragFrom(
        tester.getCenter(find.byType(ItemWidget)),
        const Offset(0, -88),
      );
      await tester.pumpAndSettle();

      expect(changedIndex, isNotNull);
      expect(changedIndex, greaterThan(initialIndex));
    },
  );

  testWidgets(
    'tapping the selected row starts text editing when inputable',
    (tester) async {
      final option = _minuteOption();

      await _pumpItem(
        tester,
        option: option,
        inputable: true,
        onChange: (_) {},
      );

      expect(find.byType(TextField), findsNothing);

      await tester.tapAt(tester.getCenter(find.byType(ItemWidget)));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
