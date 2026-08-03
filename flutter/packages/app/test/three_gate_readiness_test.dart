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

  Map<EquipmentSlot, SlotClaim> fullGear({bool pinned = false}) {
    var i = 1;
    return {
      for (final s in [
        ...EquipmentSlot.weaponSlots,
        ...EquipmentSlot.armorSlots,
      ])
        s: claim(s, i++, instanceId: pinned ? 'inst-$i' : null),
    };
  }

  const completeKit = SubclassKit(
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

  group('evaluateThreeGateReadiness', () {
    test('default incomplete hard-blocks save', () {
      final status = evaluateThreeGateReadiness(
        resolved: ResolvedVariantEquipment(
          equipment: {EquipmentSlot.primary: claim(EquipmentSlot.primary, 1)},
          conflicts: const [],
        ),
        isDefault: true,
        className: 'Titan',
        subclassKit: completeKit,
        hasMods: true,
        artifactHash: 1,
        artifactConfig: const [2],
        fragmentCapacity: 4,
        capacityResolved: true,
      );
      expect(status.composeComplete, isFalse);
      expect(status.hardBlocksSave, isTrue);
      expect(status.chipLabels.first, contains('incomplete'));
    });

    test('non-default required miss is soft only', () {
      final syn = Synergy(
        id: 'S1',
        name: 'Melee',
        type: const SynergyType('melee'),
        links: [
          const SynergyLink(
            id: 'L1',
            synergyId: 'S1',
            kind: SynergyLinkKind.weapon,
            displayName: 'Gun',
            itemHash: 99,
            required: true,
          ),
        ],
      );
      final status = evaluateThreeGateReadiness(
        resolved: ResolvedVariantEquipment(
          equipment: {EquipmentSlot.primary: claim(EquipmentSlot.primary, 1)},
          conflicts: const [],
        ),
        isDefault: false,
        designatedSynergies: [syn],
      );
      expect(status.requiredLinksSatisfied, isFalse);
      expect(status.softRequiredWarn, isTrue);
      expect(status.hardBlocksSave, isFalse);
      expect(status.chipLabels[1], contains('soft'));
    });

    test('compose complete + required pin + equip ready', () {
      final invItems = <InventoryPinItem>[];
      final gear = <EquipmentSlot, SlotClaim>{};
      var i = 1;
      for (final s in [
        ...EquipmentSlot.weaponSlots,
        ...EquipmentSlot.armorSlots,
      ]) {
        final id = 'inst-$i';
        gear[s] = claim(s, i, instanceId: id);
        invItems.add(InventoryPinItem(instanceId: id, itemHash: i));
        i++;
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
            displayName: 'Primary',
            itemHash: gear[EquipmentSlot.primary]!.itemHash,
            required: true,
          ),
        ],
      );
      final status = evaluateThreeGateReadiness(
        resolved: ResolvedVariantEquipment(
          equipment: gear,
          conflicts: const [],
        ),
        isDefault: true,
        className: 'Titan',
        subclassKit: completeKit,
        hasMods: true,
        fragmentCapacity: 4,
        capacityResolved: true,
        artifactHash: 42,
        artifactConfig: const [1],
        designatedSynergies: [syn],
        inventory: buildInventoryPinIndex(invItems),
      );
      expect(status.composeComplete, isTrue);
      expect(status.requiredLinksSatisfied, isTrue);
      expect(status.equipReady, isTrue);
      expect(status.hardBlocksSave, isFalse);
    });
  });

  group('evaluateComposeHardBlocks required/compose', () {
    test('default surfaces incomplete + required hard blocks', () {
      final blocks = evaluateComposeHardBlocks(
        ComposeHardBlockInput(
          synergyTypeCount: 1,
          isDefault: true,
          composeMissing: const ['super', 'artifact'],
          requiredFailures: [
            const RequiredLinkFailure(
              synergyId: 'S1',
              synergyName: 'Melee',
              linkId: 'L1',
              kind: 'weapon',
              displayName: 'Gun',
              reason: 'wishlist_or_stale',
            ),
          ],
        ),
      );
      expect(
        blocks.map((b) => b.code),
        containsAll([
          DomainFailureCodes.defaultVariantIncomplete,
          DomainFailureCodes.requiredLinkUnsatisfied,
        ]),
      );
      expect(composeSaveHardBlocked(blocks), isTrue);
    });

    test('non-default required failures do not hard-block', () {
      final blocks = evaluateComposeHardBlocks(
        ComposeHardBlockInput(
          synergyTypeCount: 1,
          isDefault: false,
          requiredFailures: [
            const RequiredLinkFailure(
              synergyId: 'S1',
              synergyName: 'Melee',
              linkId: 'L1',
              kind: 'weapon',
              displayName: 'Gun',
              reason: 'unmatched',
            ),
          ],
        ),
      );
      expect(
        blocks.any(
          (b) => b.code == DomainFailureCodes.requiredLinkUnsatisfied,
        ),
        isFalse,
      );
    });
  });
}
