import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  group('isArmorBoardSlot', () {
    test('armor slots true', () {
      expect(isArmorBoardSlot('helmet'), isTrue);
      expect(isArmorBoardSlot('arms'), isTrue);
      expect(isArmorBoardSlot('class_item'), isTrue);
      expect(isArmorBoardSlot('helmet:123'), isTrue);
    });

    test('weapon slots false', () {
      expect(isArmorBoardSlot('primary'), isFalse);
      expect(isArmorBoardSlot('energy'), isFalse);
    });
  });

  group('slotNeedsReplaceConfirm', () {
    test('occupied requires confirm', () {
      expect(slotNeedsReplaceConfirm(slotOccupied: true), isTrue);
    });
    test('empty does not', () {
      expect(slotNeedsReplaceConfirm(slotOccupied: false), isFalse);
    });
  });

  group('selectedPerksFromInstance', () {
    test('prefers trait socket plugs', () {
      final inst = CatalogInstanceProjection(
        instanceId: 'i1',
        itemHash: 1,
        bucket: 'Kinetic',
        location: 'vault',
        power: 1800,
        plugHashes: [10, 20, 30],
        socketPlugs: const [
          {
            'equippedPlugHash': 10,
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
          },
          {
            'equippedPlugHash': 20,
            'columnKind': 'trait',
            'columnLabel': 'Trait',
          },
          {
            'equippedPlugHash': 30,
            'columnKind': 'trait',
            'columnLabel': 'Trait',
          },
        ],
        syncedAt: 't',
      );
      expect(selectedPerksFromInstance(inst), [20, 30]);
    });

    test('falls back to trait plug cards', () {
      final inst = CatalogInstanceProjection(
        instanceId: 'i1',
        itemHash: 1,
        bucket: 'Kinetic',
        location: 'vault',
        power: 1800,
        plugHashes: [1, 2],
        plugCards: const [
          ResolvedPlugCard(
            hash: 1,
            displayName: 'Fluted',
            columnKind: 'barrel',
            isTrait: false,
          ),
          ResolvedPlugCard(
            hash: 2,
            displayName: 'Kill Clip',
            columnKind: 'trait',
            isTrait: true,
          ),
        ],
        syncedAt: 't',
      );
      expect(selectedPerksFromInstance(inst), [2]);
    });

    test('null instance empty', () {
      expect(selectedPerksFromInstance(null), isEmpty);
    });

    test('unenriched plugHashes stored as roll residual', () {
      final inst = CatalogInstanceProjection(
        instanceId: 'i1',
        itemHash: 1,
        bucket: 'Kinetic',
        location: 'vault',
        power: 1800,
        plugHashes: [5, 6],
        syncedAt: 't',
      );
      expect(selectedPerksFromInstance(inst), [5, 6]);
    });
  });

  group('traitPerksForDisplay', () {
    test('uses trait cards first', () {
      final perks = traitPerksForDisplay(
        selectedPerks: [1, 2],
        plugCards: const [
          ResolvedPlugCard(
            hash: 2,
            displayName: 'Frenzy',
            isTrait: true,
          ),
        ],
      );
      expect(perks.single.name, 'Frenzy');
    });

    test('falls back to selectedPerks names', () {
      final perks = traitPerksForDisplay(
        selectedPerks: [99],
        plugNameByHash: const {99: 'Kill Clip'},
      );
      expect(perks.single, const SetItemPerkDisplay(hash: 99, name: 'Kill Clip'));
    });

    test('skips non-trait classified hashes', () {
      final perks = traitPerksForDisplay(
        selectedPerks: [10, 20],
        plugCards: const [
          ResolvedPlugCard(
            hash: 10,
            displayName: 'Barrel',
            columnKind: 'barrel',
            isTrait: false,
          ),
        ],
        plugNameByHash: const {20: 'Trait'},
      );
      expect(perks.map((p) => p.hash).toList(), [20]);
    });
  });

  group('buildSetItemMetaChips', () {
    test('includes Instance vs Wishlist', () {
      expect(
        buildSetItemMetaChips(hasInstance: true, element: 'Solar'),
        containsAll(['Solar', 'Instance']),
      );
      expect(
        buildSetItemMetaChips(hasInstance: false),
        contains('Wishlist'),
      );
    });

    test('exotic and tier', () {
      final chips = buildSetItemMetaChips(
        hasInstance: true,
        isExotic: true,
        tier: 3,
        itemTypeName: 'Hand Cannon',
      );
      expect(chips, containsAll(['Exotic', 'Hand Cannon', 'Tier 3', 'Instance']));
    });
  });
}
