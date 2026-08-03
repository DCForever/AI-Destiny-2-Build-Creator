import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  SlotClaim claim(
    EquipmentSlot slot,
    int hash, {
    String? instanceId,
  }) {
    return SlotClaim(
      slot: slot,
      itemHash: hash,
      itemName: slot.wireName,
      source: ClaimSource.set,
      instanceId: instanceId,
    );
  }

  Map<EquipmentSlot, SlotClaim> fullGear({bool withPins = false}) {
    var i = 1;
    return {
      for (final s in [
        ...EquipmentSlot.weaponSlots,
        ...EquipmentSlot.armorSlots,
      ])
        s: claim(s, i++, instanceId: withPins ? 'p-$i' : null),
    };
  }

  const kit = SubclassKit(
    name: 'Sunbreaker',
    superAbility: 'Hammer of Sol',
    melee: 'Hammer Strike',
    grenade: 'Thermite Grenade',
    aspects: ['Roaring Flames', 'Consecration'],
    fragments: [
      'Ember of Ashes',
      'Ember of Beams',
      'Ember of Char',
      'Ember of Combustion',
    ],
  );

  group('assertVariantSaveHardGates required links', () {
    test('default fails REQUIRED_LINK_UNSATISFIED on wishlist-only match',
        () async {
      final syn = Synergy(
        id: 'S1',
        name: 'Melee',
        type: const SynergyType('melee'),
        links: [
          const SynergyLink(
            id: 'L1',
            synergyId: 'S1',
            kind: SynergyLinkKind.weapon,
            displayName: 'Primary gun',
            itemHash: 1,
            required: true,
          ),
        ],
      );
      await expectLater(
        () => assertVariantSaveHardGates(
          VariantSaveGateInput(
            resolved: ResolvedVariantEquipment(
              equipment: fullGear(),
              conflicts: const [],
            ),
            isDefault: true,
            attachments: const [],
            className: 'Titan',
            subclassName: kit.name,
            hasMods: true,
            subclassKit: kit,
            fragmentCapacity: 4,
            capacityResolved: true,
            artifactHash: 9,
            artifactConfig: const [1],
            designatedSynergies: [syn],
            inventory: const {},
          ),
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.requiredLinkUnsatisfied,
          ),
        ),
      );
    });

    test('default succeeds with equip-ready pin', () async {
      final gear = fullGear(withPins: true);
      final inv = <String, int>{};
      for (final e in gear.entries) {
        final id = e.value.instanceId!;
        inv[id] = e.value.itemHash;
      }
      final syn = Synergy(
        id: 'S1',
        name: 'Melee',
        type: const SynergyType('melee'),
        links: [
          SynergyLink(
            id: 'L1',
            synergyId: 'S1',
            kind: SynergyLinkKind.weapon,
            displayName: 'Primary gun',
            itemHash: gear[EquipmentSlot.primary]!.itemHash,
            required: true,
          ),
        ],
      );
      await expectLater(
        () => assertVariantSaveHardGates(
          VariantSaveGateInput(
            resolved: ResolvedVariantEquipment(
              equipment: gear,
              conflicts: const [],
            ),
            isDefault: true,
            attachments: const [],
            className: 'Titan',
            subclassName: kit.name,
            hasMods: true,
            subclassKit: kit,
            fragmentCapacity: 4,
            capacityResolved: true,
            artifactHash: 9,
            artifactConfig: const [1],
            designatedSynergies: [syn],
            inventory: inv,
          ),
        ),
        returnsNormally,
      );
    });

    test('non-default skips hard required gate', () async {
      final syn = Synergy(
        id: 'S1',
        name: 'Melee',
        type: const SynergyType('melee'),
        links: [
          const SynergyLink(
            id: 'L1',
            synergyId: 'S1',
            kind: SynergyLinkKind.weapon,
            displayName: 'Missing',
            itemHash: 999,
            required: true,
          ),
        ],
      );
      await expectLater(
        () => assertVariantSaveHardGates(
          VariantSaveGateInput(
            resolved: ResolvedVariantEquipment(
              equipment: {
                EquipmentSlot.primary: claim(EquipmentSlot.primary, 1),
              },
              conflicts: const [],
            ),
            isDefault: false,
            attachments: const [],
            designatedSynergies: [syn],
          ),
        ),
        returnsNormally,
      );
    });

    test('default incomplete kit → DEFAULT_VARIANT_INCOMPLETE', () async {
      await expectLater(
        () => assertVariantSaveHardGates(
          VariantSaveGateInput(
            resolved: ResolvedVariantEquipment(
              equipment: fullGear(),
              conflicts: const [],
            ),
            isDefault: true,
            attachments: const [],
            className: 'Titan',
            subclassName: 'Sunbreaker',
            hasMods: true,
            subclassKit: const SubclassKit(name: 'Sunbreaker'),
            artifactHash: null,
          ),
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.defaultVariantIncomplete,
          ),
        ),
      );
    });
  });
}
