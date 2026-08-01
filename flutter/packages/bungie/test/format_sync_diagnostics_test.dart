import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('formatSyncDiagnostics', () {
    InventoryParseDiagnostics base({
      InventoryResolutionCounts? resolution,
      Map<String, int>? unknownBuckets,
    }) {
      return InventoryParseDiagnostics(
        membership: const DestinyMembership(
          membershipType: 3,
          membershipId: 'm1',
          displayName: 'Test',
        ),
        raw: InventoryRawCounts(total: 1200, vault: 400),
        parsed: InventoryParsedCounts(
          total: 1100,
          equipmentTotal: 1000,
          subclassTotal: 3,
        ),
        dropped: InventoryDroppedCounts(
          total: 100,
          unknownBucket: 40,
          missingInstanceId: 10,
          invalidShape: 50,
          unknownBuckets: unknownBuckets ?? {},
        ),
        resolution: resolution,
      );
    }

    test('includes raw, parsed, and dropped lines', () {
      final text = formatSyncDiagnostics(base());
      expect(text, contains('Bungie raw items: 1,200'));
      expect(text, contains('Parsed from Bungie: 1,100'));
      expect(text, contains('1,000 weapons/armor'));
      expect(text, contains('3 subclasses'));
      expect(text, contains('Dropped: 100'));
      expect(text, contains('unknown bucket: 40'));
      expect(text, contains('missing instance id: 10'));
      expect(text, isNot(contains('Stored after resolution')));
    });

    test('includes resolution line when present', () {
      final text = formatSyncDiagnostics(
        base(
          resolution: const InventoryResolutionCounts(
            resolvedFromTransfer: 42,
            droppedNonEquipment: 7,
            storedTotal: 1050,
            storedEquipment: 1040,
          ),
        ),
      );
      expect(text, contains('Stored after resolution: 1,050'));
      expect(text, contains('42 from vault/postmaster'));
      expect(text, contains('7 non-equipment dropped'));
    });

    test('lists top unknown buckets sorted by count', () {
      final text = formatSyncDiagnostics(
        base(
          unknownBuckets: {
            '111': 2,
            '222': 9,
            '333': 5,
          },
        ),
      );
      expect(text, contains('Top unknown buckets:'));
      final i222 = text.indexOf('bucket 222: 9');
      final i333 = text.indexOf('bucket 333: 5');
      final i111 = text.indexOf('bucket 111: 2');
      expect(i222, greaterThan(-1));
      expect(i333, greaterThan(i222));
      expect(i111, greaterThan(i333));
    });

    test('zero counts format without commas', () {
      final d = InventoryParseDiagnostics(
        membership: const DestinyMembership(
          membershipType: 1,
          membershipId: 'x',
          displayName: 'x',
        ),
        raw: InventoryRawCounts(),
        parsed: InventoryParsedCounts(),
        dropped: InventoryDroppedCounts(),
        resolution: const InventoryResolutionCounts(
          resolvedFromTransfer: 0,
          droppedNonEquipment: 0,
          storedTotal: 0,
          storedEquipment: 0,
        ),
      );
      final text = formatSyncDiagnostics(d);
      expect(text, contains('Bungie raw items: 0'));
      expect(text, contains('Stored after resolution: 0'));
    });
  });
}
