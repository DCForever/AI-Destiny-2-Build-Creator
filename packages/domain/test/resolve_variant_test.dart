import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('detectSlotConflicts & buildEquipmentMap', () {
    test('detects slot conflicts between set items', () {
      final claims = itemsToSlotClaims(const [
        ExpandedSetItem(
          slot: EquipmentSlot.primary,
          itemHash: 1,
          itemName: 'A',
          setId: 's1',
          setType: SetType.weapon,
        ),
        ExpandedSetItem(
          slot: EquipmentSlot.primary,
          itemHash: 2,
          itemName: 'B',
          setId: 's2',
          setType: SetType.weapon,
        ),
      ]);

      final conflicts = detectSlotConflicts(claims);
      expect(conflicts, hasLength(1));
      expect(conflicts.single.slot, EquipmentSlot.primary);
      expect(conflicts.single.claimants, hasLength(2));

      final equipment = buildEquipmentMap(claims);
      expect(equipment[EquipmentSlot.primary]?.itemHash, 1);

      final resolved = ResolvedVariantEquipment(
        equipment: equipment,
        conflicts: conflicts,
      );
      expect(
        () => assertNoSlotConflicts(resolved),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.slotConflict,
          ),
        ),
      );
    });

    test('no conflicts when slots are unique', () {
      final claims = itemsToSlotClaims(const [
        ExpandedSetItem(
          slot: EquipmentSlot.primary,
          itemHash: 1,
          itemName: 'A',
          setId: 's1',
          setType: SetType.weapon,
        ),
        ExpandedSetItem(
          slot: EquipmentSlot.helmet,
          itemHash: 2,
          itemName: 'H',
          setId: 's2',
          setType: SetType.armor,
        ),
      ]);
      expect(detectSlotConflicts(claims), isEmpty);
      final map = buildEquipmentMap(claims);
      expect(map.keys, containsAll([EquipmentSlot.primary, EquipmentSlot.helmet]));
      expect(
        () => assertNoSlotConflicts(
          ResolvedVariantEquipment(equipment: map, conflicts: const []),
        ),
        returnsNormally,
      );
    });

    test('itemsToSlotClaims maps pair source', () {
      final claims = itemsToSlotClaims(const [
        ExpandedSetItem(
          slot: EquipmentSlot.exoticArmor,
          itemHash: 9,
          itemName: 'Cuirass',
          setId: 'p1',
          setType: SetType.pair,
        ),
      ]);
      expect(claims.single.source, ClaimSource.pairSet);
    });
  });

  group('exotic inject & effective weapon', () {
    test('adds exotic weapon and armor claims', () {
      var claims = addExoticWeaponClaim(
        const [],
        exoticWeaponHash: 10,
        exoticWeaponName: 'Vex',
        weaponSlot: EquipmentSlot.primary,
      );
      claims = addExoticArmorClaim(
        claims,
        exoticArmorHash: 20,
        exoticArmorName: 'Crown',
        armorSlot: EquipmentSlot.helmet,
      );
      expect(claims, hasLength(2));
      expect(claims[0].source, ClaimSource.variantExoticWeapon);
      expect(claims[1].source, ClaimSource.buildExoticArmor);
    });

    test('skips exotic armor claim when hash is null', () {
      final claims = addExoticArmorClaim(
        const [],
        exoticArmorHash: null,
        exoticArmorName: null,
        armorSlot: EquipmentSlot.helmet,
      );
      expect(claims, isEmpty);
    });

    test('skips exotic weapon when hash or slot missing', () {
      expect(
        addExoticWeaponClaim(
          const [],
          exoticWeaponHash: 10,
          weaponSlot: null,
        ),
        isEmpty,
      );
      expect(
        addExoticWeaponClaim(
          const [],
          exoticWeaponHash: null,
          weaponSlot: EquipmentSlot.primary,
        ),
        isEmpty,
      );
    });

    test('prefers build-shared exotic weapon over variant', () {
      final weapon = effectiveExoticWeapon(
        buildExoticWeaponHash: 111,
        buildExoticWeaponName: 'Shared',
        variantExoticWeaponHash: 222,
        variantExoticWeaponName: 'Variant',
      );
      expect(weapon.exoticWeaponHash, 111);
      expect(weapon.fromBuild, isTrue);
    });

    test('falls back to variant exotic weapon', () {
      final weapon = effectiveExoticWeapon(
        buildExoticWeaponHash: null,
        variantExoticWeaponHash: 222,
        variantExoticWeaponName: 'Variant',
      );
      expect(weapon.exoticWeaponHash, 222);
      expect(weapon.fromBuild, isFalse);
    });

    test('skips build exotic injection when class_item already claimed in intent mode', () {
      const existing = [
        SlotClaim(
          slot: EquipmentSlot.classItem,
          itemHash: 50,
          itemName: 'Variant CI',
          source: ClaimSource.set,
          selectedPerks: [1, 2],
        ),
      ];
      final next = addExoticArmorClaim(
        existing,
        exoticArmorHash: 100,
        exoticArmorName: 'Build CI',
        armorSlot: EquipmentSlot.classItem,
        skipIfClassItemClaimed: true,
      );
      expect(next, hasLength(1));
      expect(next[0].itemHash, 50);
      expect(next[0].selectedPerks, [1, 2]);
    });
  });

  group('pair armor match', () {
    const pairItems = [
      ExpandedSetItem(
        slot: EquipmentSlot.exoticArmor,
        itemHash: 999,
        itemName: 'Wrong',
        setId: 'p1',
        setType: SetType.pair,
      ),
    ];

    test('rejects pair armor mismatch', () {
      expect(
        () => validatePairArmorMatch(
          buildExoticArmorHash: 100,
          pairItems: pairItems,
        ),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.pairArmorMismatch,
          ),
        ),
      );
    });

    test('allows pair armor when build has no exotic armor', () {
      expect(
        () => validatePairArmorMatch(
          buildExoticArmorHash: null,
          pairItems: pairItems,
        ),
        returnsNormally,
      );
    });

    test('allows pair armor mismatch in class-item intent mode', () {
      expect(
        () => validatePairArmorMatch(
          buildExoticArmorHash: 100,
          pairItems: pairItems,
          intentMode: true,
        ),
        returnsNormally,
      );
    });

    test('allows matching pair armor', () {
      expect(
        () => validatePairArmorMatch(
          buildExoticArmorHash: 999,
          pairItems: pairItems,
        ),
        returnsNormally,
      );
    });
  });

  group('completeness default vs non-default', () {
    SlotClaim claim(EquipmentSlot slot, int hash) => SlotClaim(
          slot: slot,
          itemHash: hash,
          itemName: slot.wireName,
          source: ClaimSource.set,
          setId: 's',
        );

    Map<EquipmentSlot, SlotClaim> fullCombatEquipment() {
      final map = <EquipmentSlot, SlotClaim>{};
      var i = 1;
      for (final slot in [
        ...EquipmentSlot.weaponSlots,
        ...EquipmentSlot.armorSlots,
      ]) {
        map[slot] = claim(slot, i++);
      }
      return map;
    }

    test('assertVariantNotEmpty on empty equipment', () {
      expect(
        () => assertVariantNotEmpty(
          const ResolvedVariantEquipment(equipment: {}, conflicts: []),
        ),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.variantEmpty,
          ),
        ),
      );
    });

    test('assertFullCombatLoadout reports missing slots and identity', () {
      final resolved = ResolvedVariantEquipment(
        equipment: {EquipmentSlot.primary: claim(EquipmentSlot.primary, 1)},
        conflicts: const [],
      );
      try {
        assertFullCombatLoadout(
          resolved,
          className: 'Titan',
          subclassName: 'Sunbreaker',
          hasMods: false,
        );
        fail('expected throw');
      } on ResolveVariantException catch (e) {
        expect(e.code, DomainFailureCodes.defaultVariantIncomplete);
        final missing = e.details?['missing'] as List<Object?>?;
        expect(missing, isNotNull);
        expect(missing, contains('special'));
        expect(missing, contains('heavy'));
        expect(missing, contains('helmet'));
        expect(missing, contains('mods'));
        expect(missing, isNot(contains('primary')));
        expect(missing, isNot(contains('className')));
        expect(missing, isNot(contains('subclass')));
      }
    });

    test('assertFullCombatLoadout passes full combat + mods', () {
      final resolved = ResolvedVariantEquipment(
        equipment: fullCombatEquipment(),
        conflicts: const [],
      );
      expect(
        () => assertFullCombatLoadout(
          resolved,
          className: 'Titan',
          subclassName: 'Sunbreaker',
          hasMods: true,
        ),
        returnsNormally,
      );
    });

    test('non-default completeness allows partial combat loadout', () {
      final partial = ResolvedVariantEquipment(
        equipment: {EquipmentSlot.primary: claim(EquipmentSlot.primary, 1)},
        conflicts: const [],
      );
      expect(
        () => assertVariantCompleteness(
          partial,
          isDefault: false,
          className: null,
          subclassName: null,
          hasMods: false,
        ),
        returnsNormally,
      );
    });

    test('default completeness requires full combat loadout', () {
      final partial = ResolvedVariantEquipment(
        equipment: {EquipmentSlot.primary: claim(EquipmentSlot.primary, 1)},
        conflicts: const [],
      );
      expect(
        () => assertVariantCompleteness(
          partial,
          isDefault: true,
          className: 'Hunter',
          subclassName: 'Nightstalker',
          hasMods: true,
        ),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.defaultVariantIncomplete,
          ),
        ),
      );
    });

    test('default completeness still requires non-empty', () {
      expect(
        () => assertVariantCompleteness(
          const ResolvedVariantEquipment(),
          isDefault: true,
          className: 'Warlock',
          subclassName: 'Dawnblade',
          hasMods: true,
        ),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.variantEmpty,
          ),
        ),
      );
    });
  });

  group('resolveVariantClaims orchestration', () {
    test('merges set claims and exotic pins without conflicts', () {
      final resolved = resolveVariantClaims(
        expandedItems: const [
          ExpandedSetItem(
            slot: EquipmentSlot.special,
            itemHash: 5,
            itemName: 'Special',
            setId: 'w1',
            setType: SetType.weapon,
          ),
        ],
        buildExoticArmorHash: 20,
        buildExoticArmorName: 'Crown',
        buildExoticWeaponHash: 10,
        buildExoticWeaponName: 'Vex',
        variantExoticWeaponHash: 99,
        exoticWeaponSlot: EquipmentSlot.primary,
        exoticArmorSlot: EquipmentSlot.helmet,
      );
      expect(resolved.conflicts, isEmpty);
      expect(resolved.equipment[EquipmentSlot.special]?.itemHash, 5);
      expect(resolved.equipment[EquipmentSlot.primary]?.itemHash, 10);
      expect(resolved.equipment[EquipmentSlot.helmet]?.itemHash, 20);
      expect(
        resolved.equipment[EquipmentSlot.primary]?.source,
        ClaimSource.variantExoticWeapon,
      );
    });

    test('class-item intent skips pair mismatch and armor inject', () {
      final resolved = resolveVariantClaims(
        expandedItems: const [
          ExpandedSetItem(
            slot: EquipmentSlot.classItem,
            itemHash: 50,
            itemName: 'Variant CI',
            setId: 'a1',
            setType: SetType.armor,
            selectedPerks: [1, 2],
          ),
          ExpandedSetItem(
            slot: EquipmentSlot.exoticArmor,
            itemHash: 999,
            itemName: 'Other CI',
            setId: 'p1',
            setType: SetType.pair,
          ),
        ],
        buildExoticArmorHash: 100,
        buildExoticArmorName: 'Build CI',
        exoticArmorSlot: EquipmentSlot.classItem,
      );
      expect(resolved.conflicts, isEmpty);
      expect(resolved.equipment[EquipmentSlot.classItem]?.itemHash, 50);
      // Pair exotic_armor is a different slot key in claims — may appear as
      // exotic_armor claim without conflicting class_item.
      expect(resolved.equipment[EquipmentSlot.exoticArmor]?.itemHash, 999);
    });

    test('pair armor mismatch throws during resolve', () {
      expect(
        () => resolveVariantClaims(
          expandedItems: const [
            ExpandedSetItem(
              slot: EquipmentSlot.exoticArmor,
              itemHash: 999,
              itemName: 'Wrong',
              setId: 'p1',
              setType: SetType.pair,
            ),
          ],
          buildExoticArmorHash: 100,
          exoticArmorSlot: EquipmentSlot.helmet,
        ),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.pairArmorMismatch,
          ),
        ),
      );
    });

    test('fromRecords convenience uses Build/Variant fields', () {
      const build = Build(
        id: 'b1',
        name: 'Build',
        className: GuardianClass.titan,
        exoticWeaponHash: 111,
        exoticWeaponName: 'Shared',
        exoticArmorHash: 20,
        exoticArmorName: 'Crown',
      );
      const variant = Variant(
        id: 'v1',
        buildId: 'b1',
        name: 'Default',
        isDefault: true,
        exoticWeaponHash: 222,
        exoticWeaponName: 'Variant',
      );
      final resolved = resolveVariantClaimsFromRecords(
        expandedItems: const [],
        build: build,
        variant: variant,
        exoticWeaponSlot: EquipmentSlot.primary,
        exoticArmorSlot: EquipmentSlot.helmet,
      );
      expect(resolved.equipment[EquipmentSlot.primary]?.itemHash, 111);
      expect(resolved.equipment[EquipmentSlot.helmet]?.itemHash, 20);
    });
  });
}
