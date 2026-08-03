import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// Golden parity with Next `assertRequiredLinks.test.ts` (current six kinds).
void main() {
  SynergyLink link({
    required SynergyLinkKind kind,
    required String displayName,
    String id = 'L1',
    String synergyId = 'S1',
    int? itemHash,
    int? perkHash,
    bool required = false,
  }) {
    return SynergyLink(
      id: id,
      synergyId: synergyId,
      kind: kind,
      displayName: displayName,
      itemHash: itemHash,
      perkHash: perkHash,
      required: required,
    );
  }

  Synergy synergy(List<SynergyLink> links) {
    return Synergy(
      id: 'S1',
      name: 'Melee: Base',
      type: const SynergyType('melee'),
      subType: 'Base',
      links: links,
    );
  }

  SlotClaim claim({
    required EquipmentSlot slot,
    required int itemHash,
    String? instanceId,
    List<int>? selectedPerks,
  }) {
    return SlotClaim(
      slot: slot,
      itemHash: itemHash,
      itemName: 'Item',
      source: ClaimSource.set,
      instanceId: instanceId,
      selectedPerks: selectedPerks,
    );
  }

  ResolvedVariantEquipment resolved(List<SlotClaim> claims) {
    return ResolvedVariantEquipment(
      equipment: {for (final c in claims) c.slot: c},
      conflicts: const [],
    );
  }

  group('isRequiredLinkSatisfied', () {
    test('rejects wishlist match without pin', () {
      final l = link(
        kind: SynergyLinkKind.weapon,
        displayName: 'Fatebringer',
        itemHash: 10,
        required: true,
      );
      final all = [claim(slot: EquipmentSlot.primary, itemHash: 10)];
      final result = isRequiredLinkSatisfied(
        l,
        readyClaims: const [],
        allClaims: all,
      );
      expect(result.ok, isFalse);
      expect(result.reason, 'wishlist_or_stale');
    });

    test('accepts equip-ready pin match', () {
      final l = link(
        kind: SynergyLinkKind.weapon,
        displayName: 'Fatebringer',
        itemHash: 10,
        required: true,
      );
      final pinned = claim(
        slot: EquipmentSlot.primary,
        itemHash: 10,
        instanceId: 'inst-1',
      );
      final inv = buildInventoryPinIndex([
        const InventoryPinItem(instanceId: 'inst-1', itemHash: 10),
      ]);
      final ready = equipReadyClaims(resolved([pinned]), inv);
      final result = isRequiredLinkSatisfied(
        l,
        readyClaims: ready,
        allClaims: [pinned],
      );
      expect(result.ok, isTrue);
    });

    test('matches artifact_perk from applied config', () {
      final l = link(
        kind: SynergyLinkKind.artifactPerk,
        displayName: 'Anti-Barrier',
        perkHash: 55,
        required: true,
      );
      expect(
        isRequiredLinkSatisfied(
          l,
          readyClaims: const [],
          allClaims: const [],
          ctx: const MatchEvidenceContext(artifactConfig: [55]),
        ).ok,
        isTrue,
      );
      expect(
        isRequiredLinkSatisfied(
          l,
          readyClaims: const [],
          allClaims: const [],
          ctx: const MatchEvidenceContext(artifactConfig: []),
        ).ok,
        isFalse,
      );
    });
  });

  group('collectRequiredLinkFailures / assert', () {
    test('ignores non-required links', () {
      final failures = collectRequiredLinkFailures(
        synergies: [
          synergy([
            link(
              kind: SynergyLinkKind.weapon,
              displayName: 'Soft',
              itemHash: 99,
              required: false,
            ),
          ]),
        ],
        resolved: resolved(const []),
        inventory: buildInventoryPinIndex(const []),
      );
      expect(failures, isEmpty);
    });

    test('throws REQUIRED_LINK_UNSATISFIED when required link missing pin', () {
      final syn = synergy([
        link(
          kind: SynergyLinkKind.weapon,
          displayName: 'Required Gun',
          itemHash: 10,
          required: true,
        ),
      ]);
      expect(
        () => assertRequiredLinksSatisfied(
          synergies: [syn],
          resolved: resolved([
            claim(slot: EquipmentSlot.primary, itemHash: 10),
          ]),
          inventory: buildInventoryPinIndex(const []),
        ),
        throwsA(
          isA<ResolveVariantException>().having(
            (e) => e.code,
            'code',
            DomainFailureCodes.requiredLinkUnsatisfied,
          ),
        ),
      );
    });

    test('passes when required link is pin-satisfied', () {
      final syn = synergy([
        link(
          kind: SynergyLinkKind.weapon,
          displayName: 'Required Gun',
          itemHash: 10,
          required: true,
        ),
      ]);
      expect(
        () => assertRequiredLinksSatisfied(
          synergies: [syn],
          resolved: resolved([
            claim(
              slot: EquipmentSlot.primary,
              itemHash: 10,
              instanceId: 'i1',
            ),
          ]),
          inventory: buildInventoryPinIndex([
            const InventoryPinItem(instanceId: 'i1', itemHash: 10),
          ]),
        ),
        returnsNormally,
      );
    });

    test('satisfies required weapon_perk via enhanced family sibling', () {
      final family = <int, Set<int>>{
        100: {100, 101},
        101: {100, 101},
      };
      final syn = synergy([
        link(
          kind: SynergyLinkKind.weaponPerk,
          displayName: 'Zen Moment',
          perkHash: 100,
          required: true,
        ),
      ]);
      expect(
        () => assertRequiredLinksSatisfied(
          synergies: [syn],
          resolved: resolved([
            claim(
              slot: EquipmentSlot.primary,
              itemHash: 10,
              instanceId: 'i1',
              selectedPerks: const [101],
            ),
          ]),
          inventory: buildInventoryPinIndex([
            const InventoryPinItem(instanceId: 'i1', itemHash: 10),
          ]),
          ctx: MatchEvidenceContext(perkFamilyByHash: family),
        ),
        returnsNormally,
      );
    });

    test('satisfies required class-item exotic_armor via perk config', () {
      final classItems = {77};
      final syn = synergy([
        link(
          kind: SynergyLinkKind.exoticArmor,
          displayName: 'Spirit',
          itemHash: 77,
          perkHash: 900,
          required: true,
        ),
      ]);
      expect(
        () => assertRequiredLinksSatisfied(
          synergies: [syn],
          resolved: resolved([
            claim(
              slot: EquipmentSlot.classItem,
              itemHash: 77,
              instanceId: 'ci1',
              selectedPerks: const [900, 901],
            ),
          ]),
          inventory: buildInventoryPinIndex([
            const InventoryPinItem(instanceId: 'ci1', itemHash: 77),
          ]),
          ctx: MatchEvidenceContext(exoticClassItemHashes: classItems),
        ),
        returnsNormally,
      );
    });
  });
}
