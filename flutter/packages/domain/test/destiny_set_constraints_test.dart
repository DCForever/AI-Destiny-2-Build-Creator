import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// Golden parity with TypeScript `destinySetConstraints.test.ts`.
void main() {
  group('assertSetItemAllowed', () {
    test('rejects invalid slots for set type', () {
      final r = assertSetItemAllowed(
        SetType.weapon,
        'helmet',
        const SetItemMeta(kind: SetItemKind.weapon, equipmentSlot: 'Kinetic'),
      );
      expect(r.ok, isFalse);
      expect(r.reasons.first, matches(RegExp('not valid', caseSensitive: false)));
    });

    test('rejects armor in a weapon set', () {
      final r = assertSetItemAllowed(
        SetType.weapon,
        'primary',
        const SetItemMeta(kind: SetItemKind.armor, equipmentSlot: 'Helmet'),
      );
      expect(r.ok, isFalse);
      expect(r.reasons.join(' '), matches(RegExp('weapons', caseSensitive: false)));
    });

    test('allows unknown kind on armor set (legendary armor store miss)', () {
      expect(
        assertSetItemAllowed(
          SetType.armor,
          'helmet',
          const SetItemMeta(kind: SetItemKind.unknown),
        ).ok,
        isTrue,
      );
    });

    test('rejects Kinetic weapon in special (Energy) slot', () {
      final r = assertSetItemAllowed(
        SetType.weapon,
        'special',
        const SetItemMeta(kind: SetItemKind.weapon, equipmentSlot: 'Kinetic'),
      );
      expect(r.ok, isFalse);
      expect(r.reasons.join(' '), matches(RegExp('Energy', caseSensitive: false)));
    });

    test('allows matching Kinetic weapon in primary', () {
      final r = assertSetItemAllowed(
        SetType.weapon,
        'primary',
        const SetItemMeta(
          kind: SetItemKind.weapon,
          equipmentSlot: 'Kinetic',
          isExotic: false,
        ),
      );
      expect(r.ok, isTrue);
    });

    test('allows exotic weapon in primary', () {
      final r = assertSetItemAllowed(
        SetType.weapon,
        'primary',
        const SetItemMeta(
          kind: SetItemKind.exoticWeapon,
          equipmentSlot: 'Kinetic',
          isExotic: true,
        ),
      );
      expect(r.ok, isTrue);
    });

    test('rejects wrong armor piece', () {
      final r = assertSetItemAllowed(
        SetType.armor,
        'helmet',
        const SetItemMeta(kind: SetItemKind.armor, equipmentSlot: 'Legs'),
      );
      expect(r.ok, isFalse);
    });

    test('allows matching helmet', () {
      expect(
        assertSetItemAllowed(
          SetType.armor,
          'helmet',
          const SetItemMeta(kind: SetItemKind.armor, equipmentSlot: 'Helmet'),
        ).ok,
        isTrue,
      );
    });

    test('rejects legendary weapon in pair exotic_weapon', () {
      final r = assertSetItemAllowed(
        SetType.pair,
        'exotic_weapon',
        const SetItemMeta(
          kind: SetItemKind.weapon,
          isExotic: false,
          equipmentSlot: 'Kinetic',
        ),
      );
      expect(r.ok, isFalse);
      expect(
        r.reasons.join(' '),
        matches(RegExp('exotic weapon', caseSensitive: false)),
      );
    });

    test('allows exotic weapon in pair exotic_weapon', () {
      expect(
        assertSetItemAllowed(
          SetType.pair,
          'exotic_weapon',
          const SetItemMeta(
            kind: SetItemKind.exoticWeapon,
            isExotic: true,
          ),
        ).ok,
        isTrue,
      );
    });

    test('rejects non-exotic armor in pair exotic_armor', () {
      final r = assertSetItemAllowed(
        SetType.pair,
        'exotic_armor',
        const SetItemMeta(
          kind: SetItemKind.armor,
          isExotic: false,
          equipmentSlot: 'Helmet',
        ),
      );
      expect(r.ok, isFalse);
    });

    test('rejects weapon hash meta in mod set', () {
      final r = assertSetItemAllowed(
        SetType.mod,
        'mod:1',
        const SetItemMeta(
          kind: SetItemKind.weapon,
          equipmentSlot: 'Kinetic',
        ),
      );
      expect(r.ok, isFalse);
    });

    test('allows mods in mod set', () {
      expect(
        assertSetItemAllowed(
          SetType.mod,
          'mod:42',
          const SetItemMeta(kind: SetItemKind.mod),
        ).ok,
        isTrue,
      );
    });

    test('allows fashion freely when slot valid', () {
      expect(
        assertSetItemAllowed(
          SetType.fashion,
          'ghost',
          const SetItemMeta(kind: SetItemKind.unknown),
        ).ok,
        isTrue,
      );
    });

    test('skips bucket check when equipmentSlot unknown', () {
      expect(
        assertSetItemAllowed(
          SetType.weapon,
          'primary',
          const SetItemMeta(kind: SetItemKind.weapon, equipmentSlot: null),
        ).ok,
        isTrue,
      );
    });
  });

  group('assertSetExoticExclusivity', () {
    test('blocks a second exotic weapon in a weapon set', () {
      final r = assertSetExoticExclusivity(
        setType: SetType.weapon,
        otherItems: const [
          SetOccupant(
            slot: 'primary',
            meta: SetItemMeta(
              kind: SetItemKind.exoticWeapon,
              isExotic: true,
              name: 'Witherhoard',
              equipmentSlot: 'Kinetic',
            ),
          ),
        ],
        candidate: const SetOccupant(
          slot: 'heavy',
          meta: SetItemMeta(
            kind: SetItemKind.exoticWeapon,
            isExotic: true,
            name: 'Gjallarhorn',
            equipmentSlot: 'Power',
          ),
        ),
      );
      expect(r.ok, isFalse);
      expect(
        r.reasons.first,
        matches(RegExp('Witherhoard|exotic', caseSensitive: false)),
      );
    });

    test('allows legendary after one exotic weapon', () {
      expect(
        assertSetExoticExclusivity(
          setType: SetType.weapon,
          otherItems: const [
            SetOccupant(
              slot: 'primary',
              meta: SetItemMeta(
                kind: SetItemKind.exoticWeapon,
                isExotic: true,
                name: 'X',
              ),
            ),
          ],
          candidate: const SetOccupant(
            slot: 'special',
            meta: SetItemMeta(
              kind: SetItemKind.weapon,
              isExotic: false,
              equipmentSlot: 'Energy',
            ),
          ),
        ).ok,
        isTrue,
      );
    });

    test('allows replacing the slot that already holds the exotic', () {
      // otherItems excludes the slot being replaced
      expect(
        assertSetExoticExclusivity(
          setType: SetType.weapon,
          otherItems: const [
            SetOccupant(
              slot: 'special',
              meta: SetItemMeta(kind: SetItemKind.weapon, isExotic: false),
            ),
          ],
          candidate: const SetOccupant(
            slot: 'primary',
            meta: SetItemMeta(
              kind: SetItemKind.exoticWeapon,
              isExotic: true,
            ),
          ),
        ).ok,
        isTrue,
      );
    });

    test('blocks a second exotic armor piece', () {
      final r = assertSetExoticExclusivity(
        setType: SetType.armor,
        otherItems: const [
          SetOccupant(
            slot: 'helmet',
            meta: SetItemMeta(
              kind: SetItemKind.exoticArmor,
              isExotic: true,
              name: 'Synthoceps',
            ),
          ),
        ],
        candidate: const SetOccupant(
          slot: 'legs',
          meta: SetItemMeta(
            kind: SetItemKind.exoticArmor,
            isExotic: true,
            name: 'Dunemarchers',
          ),
        ),
      );
      expect(r.ok, isFalse);
    });

    test('pair allows exotic weapon + exotic armor', () {
      expect(
        assertSetExoticExclusivity(
          setType: SetType.pair,
          otherItems: const [
            SetOccupant(
              slot: 'exotic_weapon',
              meta: SetItemMeta(
                kind: SetItemKind.exoticWeapon,
                isExotic: true,
              ),
            ),
          ],
          candidate: const SetOccupant(
            slot: 'exotic_armor',
            meta: SetItemMeta(
              kind: SetItemKind.exoticArmor,
              isExotic: true,
            ),
          ),
        ).ok,
        isTrue,
      );
    });

    test('assertSetCompositionAllowed combines fit + exclusivity', () {
      final r = assertSetCompositionAllowed(
        SetType.weapon,
        'heavy',
        const SetItemMeta(
          kind: SetItemKind.exoticWeapon,
          isExotic: true,
          equipmentSlot: 'Power',
        ),
        const [
          SetOccupant(
            slot: 'primary',
            meta: SetItemMeta(
              kind: SetItemKind.exoticWeapon,
              isExotic: true,
              equipmentSlot: 'Kinetic',
              name: 'First',
            ),
          ),
        ],
      );
      expect(r.ok, isFalse);
    });

    test('setAlreadyHasExotic detects weapon exotic', () {
      final hit = setAlreadyHasExotic(
        SetType.weapon,
        const [
          SetOccupant(
            slot: 'heavy',
            meta: SetItemMeta(
              kind: SetItemKind.exoticWeapon,
              isExotic: true,
              name: 'Ghorn',
            ),
          ),
        ],
        'weapon',
      );
      expect(hit?.meta.name, 'Ghorn');
    });
  });

  group('helpers', () {
    test('kindFromEntityStore maps stores', () {
      expect(kindFromEntityStore('exotic-weapons'), SetItemKind.exoticWeapon);
      expect(kindFromEntityStore('weapons'), SetItemKind.weapon);
      expect(kindFromEntityStore('mods'), SetItemKind.mod);
    });

    test('setItemMetaFromCatalog tags exotic weapons', () {
      final m = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Power',
        isExotic: true,
      );
      expect(m.kind, SetItemKind.exoticWeapon);
      expect(m.equipmentSlot, 'Power');
      expect(m.isExotic, isTrue);
    });

    test('setItemMetaFromManifestCategory', () {
      expect(
        setItemMetaFromManifestCategory('mods').kind,
        SetItemKind.mod,
      );
      final armor = setItemMetaFromManifestCategory('exotic-armor');
      expect(armor.kind, SetItemKind.exoticArmor);
      expect(armor.isExotic, isTrue);
    });

    test('shouldExcludeExoticFromSetCatalog hides second exotic', () {
      expect(
        shouldExcludeExoticFromSetCatalog(
          setType: SetType.weapon,
          targetSlot: 'heavy',
          otherItemsIncludingTarget: const [
            SetOccupant(
              slot: 'primary',
              meta: SetItemMeta(
                kind: SetItemKind.exoticWeapon,
                isExotic: true,
              ),
            ),
          ],
        ),
        isTrue,
      );
    });

    test('shouldExcludeExoticFromSetCatalog allows replace of exotic slot', () {
      expect(
        shouldExcludeExoticFromSetCatalog(
          setType: SetType.weapon,
          targetSlot: 'primary',
          otherItemsIncludingTarget: const [
            SetOccupant(
              slot: 'primary',
              meta: SetItemMeta(
                kind: SetItemKind.exoticWeapon,
                isExotic: true,
              ),
            ),
            SetOccupant(
              slot: 'special',
              meta: SetItemMeta(kind: SetItemKind.weapon, isExotic: false),
            ),
          ],
        ),
        isFalse,
      );
    });
  });
}
