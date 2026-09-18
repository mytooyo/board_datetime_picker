import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final steps15 = BoardPickerCustomOptions(minutes: const [0, 15, 30, 45]);

  group('normalizeMinimumForCustomOptions', () {
    test('rolls forward to the next hour when no step reaches the minute',
        () {
      final result = DateTimeUtil.normalizeMinimumForCustomOptions(
        DateTime(2026, 9, 18, 9, 46),
        steps15,
      );
      expect(result, DateTime(2026, 9, 18, 10, 0));
    });

    test('keeps the minimum untouched when it already sits on a step', () {
      final result = DateTimeUtil.normalizeMinimumForCustomOptions(
        DateTime(2026, 9, 18, 9, 30),
        steps15,
      );
      expect(result, DateTime(2026, 9, 18, 9, 30));
    });

    test('ceils to the next available step within the same hour', () {
      final result = DateTimeUtil.normalizeMinimumForCustomOptions(
        DateTime(2026, 9, 18, 9, 10),
        steps15,
      );
      expect(result, DateTime(2026, 9, 18, 9, 15));
    });

    test('rolling forward can cross into the next day', () {
      final result = DateTimeUtil.normalizeMinimumForCustomOptions(
        DateTime(2026, 9, 18, 23, 50),
        steps15,
      );
      expect(result, DateTime(2026, 9, 19, 0, 0));
    });

    test('is a no-op without custom options', () {
      final original = DateTime(2026, 9, 18, 9, 46);
      final result =
          DateTimeUtil.normalizeMinimumForCustomOptions(original, null);
      expect(result, original);
    });
  });

  group('normalizeMaximumForCustomOptions', () {
    test('floors to the previous step when the exact minute is unreachable',
        () {
      final result = DateTimeUtil.normalizeMaximumForCustomOptions(
        DateTime(2026, 9, 18, 8, 59),
        steps15,
      );
      expect(result, DateTime(2026, 9, 18, 8, 45));
    });

    test('rolls back to the previous hour when no step is low enough', () {
      final result = DateTimeUtil.normalizeMaximumForCustomOptions(
        DateTime(2026, 9, 18, 9, 0),
        BoardPickerCustomOptions(minutes: const [30, 45]),
      );
      expect(result, DateTime(2026, 9, 18, 8, 45));
    });
  });
}
