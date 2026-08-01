import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('formatLastSyncLabel', () {
    test('Never when null', () {
      expect(formatLastSyncLabel(), 'Never');
      expect(inventoryHasSynced(), isFalse);
    });

    test('same day shows time only', () {
      final now = DateTime(2026, 7, 25, 18, 0);
      final label = formatLastSyncLabel(
        lastFullSyncAt: '2026-07-25T10:05:00.000Z',
        now: now,
      );
      // Local conversion may shift hour; still contains minutes + AM/PM.
      expect(label, isNot(equals('Never')));
      expect(label.contains(':'), isTrue);
      expect(inventoryHasSynced(lastFullSyncAt: '2026-07-25T10:05:00.000Z'), isTrue);
    });

    test('other day includes month', () {
      final now = DateTime(2026, 7, 25, 12, 0);
      final label = formatLastSyncLabel(
        lastFullSyncAt: DateTime(2026, 6, 1, 9, 30).toIso8601String(),
        now: now,
      );
      expect(label, contains('Jun'));
      expect(label, contains('1'));
    });

    test('unparseable → Never', () {
      expect(formatLastSyncLabel(lastFullSyncAt: 'not-a-date'), 'Never');
    });

    test('prefers lastFullSyncAt over lastSyncAt', () {
      final now = DateTime(2026, 7, 25, 12, 0);
      final label = formatLastSyncLabel(
        lastFullSyncAt: DateTime(2026, 7, 25, 8, 0).toIso8601String(),
        lastSyncAt: DateTime(2026, 1, 1, 8, 0).toIso8601String(),
        now: now,
      );
      expect(label, isNot(contains('Jan')));
    });
  });
}
