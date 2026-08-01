import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

const fixedId = '00000000-0000-4000-8000-000000000001';

SlotClaim claim(
  EquipmentSlot slot,
  int itemHash, {
  String? instanceId,
  String itemName = 'Item',
  ClaimSource source = ClaimSource.set,
  List<int>? selectedPerks,
}) {
  return SlotClaim(
    slot: slot,
    itemHash: itemHash,
    itemName: itemName,
    source: source,
    instanceId: instanceId,
    selectedPerks: selectedPerks,
  );
}

void main() {
  group('buildVariantDimLoadout', () {
    test('maps combat pins to equipped with instance ids (TS golden fixture)', () {
      final loadout = buildVariantDimLoadout(
        VariantDimLoadoutInput(
          buildName: 'Solar Titan',
          className: GuardianClass.titan,
          variantName: 'Default',
          equipment: {
            EquipmentSlot.primary: claim(
              EquipmentSlot.primary,
              111,
              instanceId: 'inst-1',
              itemName: 'Gun',
            ),
            EquipmentSlot.helmet: claim(
              EquipmentSlot.helmet,
              222,
              instanceId: 'inst-2',
              itemName: 'Helm',
            ),
          },
          modHashes: const [9001],
        ),
        id: fixedId,
      );

      expect(loadout.classType, DimClassType.titan);
      expect(loadout.name, contains('Solar Titan'));
      expect(loadout.equipped, [
        const DimLoadoutItem(hash: 111, id: 'inst-1'),
        const DimLoadoutItem(hash: 222, id: 'inst-2'),
      ]);
      expect(loadout.parameters?.mods, [9001]);
      expect(loadout.parameters?.autoStatMods, isTrue);
      expect(loadout.parameters?.includeRuntimeStatBenefits, isTrue);
    });

    test('jsonOnly loadout body matches TS golden for one fixture variant', () {
      // Fixed-id serialization of the primary TS vitest fixture.
      final expectedLoadout = {
        'id': fixedId,
        'name': 'Solar Titan — Default',
        'classType': 0,
        'equipped': [
          {'hash': 111, 'id': 'inst-1'},
          {'hash': 222, 'id': 'inst-2'},
        ],
        'unequipped': <Map<String, Object?>>[],
        'parameters': {
          'mods': [9001],
          'autoStatMods': true,
          'includeRuntimeStatBenefits': true,
        },
      };

      final loadout = buildVariantDimLoadout(
        VariantDimLoadoutInput(
          buildName: 'Solar Titan',
          className: GuardianClass.titan,
          variantName: 'Default',
          equipment: {
            EquipmentSlot.primary: claim(
              EquipmentSlot.primary,
              111,
              instanceId: 'inst-1',
              itemName: 'Gun',
            ),
            EquipmentSlot.helmet: claim(
              EquipmentSlot.helmet,
              222,
              instanceId: 'inst-2',
              itemName: 'Helm',
            ),
          },
          modHashes: const [9001],
        ),
        id: fixedId,
      );

      expect(loadout.toJson(), expectedLoadout);

      final inventory = buildInventoryPinIndex(const [
        InventoryPinItem(instanceId: 'inst-1', itemHash: 111),
        InventoryPinItem(instanceId: 'inst-2', itemHash: 222),
      ]);
      final readiness = computeEquipReady(
        ResolvedVariantEquipment(
          equipment: {
            EquipmentSlot.primary: claim(
              EquipmentSlot.primary,
              111,
              instanceId: 'inst-1',
              itemName: 'Gun',
            ),
            EquipmentSlot.helmet: claim(
              EquipmentSlot.helmet,
              222,
              instanceId: 'inst-2',
              itemName: 'Helm',
            ),
          },
        ),
        inventory,
      );

      final payload = buildJsonOnlyDimExport(
        readiness: readiness,
        input: VariantDimLoadoutInput(
          buildName: 'Solar Titan',
          className: GuardianClass.titan,
          variantName: 'Default',
          equipment: {
            EquipmentSlot.primary: claim(
              EquipmentSlot.primary,
              111,
              instanceId: 'inst-1',
              itemName: 'Gun',
            ),
            EquipmentSlot.helmet: claim(
              EquipmentSlot.helmet,
              222,
              instanceId: 'inst-2',
              itemName: 'Helm',
            ),
          },
          modHashes: const [9001],
        ),
        loadoutId: fixedId,
      );

      expect(payload, {'loadout': expectedLoadout});
    });

    test('puts fashion in unequipped and omits empty fashion', () {
      final withFashion = buildVariantDimLoadout(
        const VariantDimLoadoutInput(
          buildName: 'B',
          className: GuardianClass.hunter,
          fashion: DimFashion(
            setId: 'f1',
            pieces: [
              DimFashionPiece(itemHash: 55, itemName: 'Ghost'),
            ],
          ),
        ),
        id: fixedId,
      );
      expect(withFashion.unequipped, [const DimLoadoutItem(hash: 55)]);

      final empty = buildVariantDimLoadout(
        const VariantDimLoadoutInput(
          buildName: 'B',
          className: GuardianClass.hunter,
          fashion: DimFashion(setId: 'f1'),
        ),
        id: fixedId,
      );
      expect(empty.unequipped, isEmpty);
    });

    test('encodes artifact and subclass in notes', () {
      final loadout = buildVariantDimLoadout(
        const VariantDimLoadoutInput(
          buildName: 'B',
          className: GuardianClass.warlock,
          subclass: DimSubclassNote(
            name: 'Dawnblade',
            superName: 'Well of Radiance',
          ),
          artifact: DimArtifact(
            hash: 99,
            name: 'Seasonal',
            config: [1, 2],
          ),
        ),
        id: fixedId,
      );
      expect(loadout.notes, contains('Subclass: Dawnblade'));
      expect(loadout.notes, contains('Artifact: Seasonal (99)'));
      expect(loadout.notes, contains('unlocks=[1,2]'));
    });

    test('maps soft stat targets to DIM constraints', () {
      final loadout = buildVariantDimLoadout(
        const VariantDimLoadoutInput(
          buildName: 'B',
          className: GuardianClass.titan,
          softStatTargets: SoftStatTargets({
            ArmorStatName.weapons: 100,
            ArmorStatName.health: 70,
          }),
        ),
        id: fixedId,
      );
      expect(loadout.parameters?.statConstraints, [
        const DimStatConstraint(
          statHash: DimStatHashes.weapons,
          minStat: 100,
        ),
        const DimStatConstraint(
          statHash: DimStatHashes.health,
          minStat: 70,
        ),
      ]);
    });

    test('maps classType for all three classes', () {
      expect(
        buildVariantDimLoadout(
          const VariantDimLoadoutInput(
            buildName: 'B',
            className: GuardianClass.titan,
          ),
          id: fixedId,
        ).classType,
        0,
      );
      expect(
        buildVariantDimLoadout(
          const VariantDimLoadoutInput(
            buildName: 'B',
            className: GuardianClass.hunter,
          ),
          id: fixedId,
        ).classType,
        1,
      );
      expect(
        buildVariantDimLoadout(
          const VariantDimLoadoutInput(
            buildName: 'B',
            className: GuardianClass.warlock,
          ),
          id: fixedId,
        ).classType,
        2,
      );
    });

    test('includes socketOverrides from selectedPerks', () {
      final loadout = buildVariantDimLoadout(
        VariantDimLoadoutInput(
          buildName: 'B',
          className: GuardianClass.titan,
          equipment: {
            EquipmentSlot.primary: claim(
              EquipmentSlot.primary,
              111,
              instanceId: 'i1',
              selectedPerks: const [10, 20],
            ),
          },
        ),
        id: fixedId,
      );
      expect(loadout.equipped.single.socketOverrides, {0: 10, 1: 20});
      expect(
        loadout.equipped.single.toJson()['socketOverrides'],
        {'0': 10, '1': 20},
      );
    });

    test('sets exoticArmorHash from build_exotic_armor claim', () {
      final loadout = buildVariantDimLoadout(
        VariantDimLoadoutInput(
          buildName: 'B',
          className: GuardianClass.warlock,
          equipment: {
            EquipmentSlot.arms: claim(
              EquipmentSlot.arms,
              7001,
              instanceId: 'exo',
              source: ClaimSource.buildExoticArmor,
              itemName: 'Sunbracers',
            ),
          },
        ),
        id: fixedId,
      );
      expect(loadout.parameters?.exoticArmorHash, 7001);
    });

    test('truncates name to 120 chars', () {
      final loadout = buildVariantDimLoadout(
        VariantDimLoadoutInput(
          buildName: 'A' * 200,
          className: GuardianClass.titan,
        ),
        id: fixedId,
      );
      expect(loadout.name.length, 120);
    });
  });

  group('buildJsonOnlyDimExport gate', () {
    test('throws NOT_EQUIP_READY for wishlist pins', () {
      final readiness = computeEquipReady(
        ResolvedVariantEquipment(
          equipment: {
            EquipmentSlot.primary: claim(EquipmentSlot.primary, 1),
          },
        ),
        buildInventoryPinIndex(const []),
      );
      expect(readiness.equipReady, isFalse);

      expect(
        () => buildJsonOnlyDimExport(
          readiness: readiness,
          input: VariantDimLoadoutInput(
            buildName: 'B',
            className: GuardianClass.titan,
            equipment: {
              EquipmentSlot.primary: claim(EquipmentSlot.primary, 1),
            },
          ),
          loadoutId: fixedId,
        ),
        throwsA(
          isA<EquipReadyException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.notEquipReady,
          ),
        ),
      );
    });

    test('returns loadout envelope when equip-ready', () {
      final equipment = {
        EquipmentSlot.primary: claim(
          EquipmentSlot.primary,
          1,
          instanceId: 'a',
        ),
      };
      final readiness = computeEquipReady(
        ResolvedVariantEquipment(equipment: equipment),
        buildInventoryPinIndex(const [
          InventoryPinItem(instanceId: 'a', itemHash: 1),
        ]),
      );
      final payload = buildJsonOnlyDimExport(
        readiness: readiness,
        input: VariantDimLoadoutInput(
          buildName: 'Ready',
          className: GuardianClass.hunter,
          equipment: equipment,
        ),
        loadoutId: fixedId,
      );
      expect(payload.containsKey('loadout'), isTrue);
      final loadout = payload['loadout'] as Map<String, Object?>;
      expect(loadout['id'], fixedId);
      expect(loadout['classType'], 1);
      expect(loadout['equipped'], [
        {'hash': 1, 'id': 'a'},
      ]);
    });
  });
}
