import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// Golden parity with Next `defaultLoadoutCompleteness.test.ts`.
void main() {
  final completeKit = SubclassKitFields(
    name: 'Sunbreaker',
    superAbility: 'Hammer of Sol',
    melee: 'Hammer Strike',
    grenade: 'Thermite Grenade',
    aspects: const ['Roaring Flames', 'Consecration'],
    fragments: const [
      'Ember of Ashes',
      'Ember of Beams',
      'Ember of Char',
      'Ember of Combustion',
    ],
  );

  Map<EquipmentSlot, SlotClaim> fullEquipment() {
    SlotClaim c(EquipmentSlot s) => SlotClaim(
          slot: s,
          itemHash: s.index + 1,
          itemName: s.wireName,
          source: ClaimSource.set,
        );
    return {
      for (final s in [
        ...EquipmentSlot.weaponSlots,
        ...EquipmentSlot.armorSlots,
      ])
        s: c(s),
    };
  }

  group('collectSubclassKitCompleteGaps', () {
    test('requires super, melee, grenade, and full aspects', () {
      final gaps = collectSubclassKitCompleteGaps(
        const SubclassKitFields(
          name: 'Sunbreaker',
          superAbility: '',
          melee: '',
          grenade: '',
          aspects: [],
          fragments: [],
        ),
        fragmentCapacity: 0,
        capacityResolved: true,
      );
      expect(gaps, containsAll(['super', 'melee', 'grenade', 'aspects']));
    });

    test('requires fragments at capacity when capacity known', () {
      expect(
        collectSubclassKitCompleteGaps(
          completeKit,
          fragmentCapacity: 4,
          capacityResolved: true,
        ),
        isEmpty,
      );

      final short = collectSubclassKitCompleteGaps(
        SubclassKitFields(
          name: completeKit.name,
          superAbility: completeKit.superAbility,
          melee: completeKit.melee,
          grenade: completeKit.grenade,
          aspects: completeKit.aspects,
          fragments: const ['Ember of Ashes'],
        ),
        fragmentCapacity: 4,
        capacityResolved: true,
      );
      expect(short, contains('fragments'));
    });

    test('does not require class ability or movement', () {
      final gaps = collectSubclassKitCompleteGaps(
        SubclassKitFields(
          name: completeKit.name,
          superAbility: completeKit.superAbility,
          melee: completeKit.melee,
          grenade: completeKit.grenade,
          aspects: completeKit.aspects,
          fragments: completeKit.fragments,
          classAbility: '',
          movement: '',
        ),
        fragmentCapacity: 4,
        capacityResolved: true,
      );
      expect(gaps, isEmpty);
    });
  });

  group('collectArtifactCompleteGaps', () {
    test('requires artifact hash and non-empty config', () {
      expect(collectArtifactCompleteGaps(), contains('artifact'));
      expect(
        collectArtifactCompleteGaps(artifactHash: 1, artifactConfig: const []),
        contains('artifactConfig'),
      );
      expect(
        collectArtifactCompleteGaps(
          artifactHash: 1,
          artifactConfig: const [99],
        ),
        isEmpty,
      );
    });
  });

  group('assertFullCombatLoadout kit + artifact', () {
    test('fails when kit/artifact missing even with full gear', () {
      expect(
        () => assertFullCombatLoadout(
          ResolvedVariantEquipment(
            equipment: fullEquipment(),
            conflicts: const [],
          ),
          className: 'Titan',
          subclassName: 'Sunbreaker',
          hasMods: true,
          options: FullCombatLoadoutOptions(
            subclassKit: const SubclassKitFields(
              name: 'Sunbreaker',
              superAbility: '',
              aspects: [],
              fragments: [],
            ),
          ),
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

    test('passes when gear, kit, and artifact are complete', () {
      expect(
        () => assertFullCombatLoadout(
          ResolvedVariantEquipment(
            equipment: fullEquipment(),
            conflicts: const [],
          ),
          className: 'Titan',
          hasMods: true,
          options: FullCombatLoadoutOptions(
            subclassKit: completeKit,
            fragmentCapacity: 4,
            capacityResolved: true,
            artifactHash: 42,
            artifactConfig: const [1, 2],
          ),
        ),
        returnsNormally,
      );
    });

    test('can skip kit/artifact for equipment-only unit checks', () {
      expect(
        () => assertFullCombatLoadout(
          ResolvedVariantEquipment(
            equipment: fullEquipment(),
            conflicts: const [],
          ),
          className: 'Titan',
          subclassName: 'Sunbreaker',
          hasMods: true,
          options: const FullCombatLoadoutOptions(requireKitAndArtifact: false),
        ),
        returnsNormally,
      );
    });
  });
}
