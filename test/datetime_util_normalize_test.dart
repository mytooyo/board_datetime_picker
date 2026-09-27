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
      // Minute had to move down (59 -> 45), so the uncustomized second
      // field is free and takes its largest reachable value (59) to give
      // the tightest (most permissive) bound <= the original maximum.
      expect(result, DateTime(2026, 9, 18, 8, 45, 59));
    });

    test('rolls back to the previous hour when no step is low enough', () {
      final result = DateTimeUtil.normalizeMaximumForCustomOptions(
        DateTime(2026, 9, 18, 9, 0),
        BoardPickerCustomOptions(minutes: const [30, 45]),
      );
      expect(result, DateTime(2026, 9, 18, 8, 45, 59));
    });
  });

  group('regression: hour carry must reset finer fields (PR #102 review)',
      () {
    final customHoursAndMinutes = BoardPickerCustomOptions(
      hours: const [9, 10, 11, 12, 13, 14, 15, 16, 17],
      minutes: const [0, 15, 30, 45],
    );

    test('minimum 8:30 becomes 9:00, not 9:30', () {
      final result = DateTimeUtil.normalizeMinimumForCustomOptions(
        DateTime(2026, 9, 20, 8, 30),
        customHoursAndMinutes,
      );
      expect(result, DateTime(2026, 9, 20, 9, 0));
    });

    test('maximum 18:10 becomes 17:45, not 17:00', () {
      final result = DateTimeUtil.normalizeMaximumForCustomOptions(
        DateTime(2026, 9, 20, 18, 10),
        customHoursAndMinutes,
      );
      expect(result, DateTime(2026, 9, 20, 17, 45, 59));
    });
  });
}
