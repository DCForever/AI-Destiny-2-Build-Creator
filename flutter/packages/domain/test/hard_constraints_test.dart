import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// Golden parity with TypeScript `destinyBuildConstraints.test.ts`.
void main() {
  group('evaluateExoticLimits', () {
    test('allows one exotic weapon and one exotic armor', () {
      final r = evaluateExoticLimits(
        const ExoticComposition(
          exoticWeaponHashes: [100],
          exoticArmorHashes: [200],
        ),
      );
      expect(r.hardBlocks, isEmpty);
    });

    test('blocks two exotic weapons', () {
      final r = evaluateExoticLimits(
        const ExoticComposition(
          exoticWeaponHashes: [1, 2],
          exoticArmorHashes: [],
        ),
      );
      expect(r.hardBlocks, hasLength(1));
      expect(r.hardBlocks.first.code, DomainFailureCodes.tooManyExotics);
      expect(r.hardBlocks.first.message, matches(RegExp('exotic weapon', caseSensitive: false)));
    });

    test('blocks two exotic armor pieces', () {
      final r = evaluateExoticLimits(
        const ExoticComposition(
          exoticWeaponHashes: [],
          exoticArmorHashes: [10, 20],
        ),
      );
      expect(r.hardBlocks.first.message, matches(RegExp('exotic armor', caseSensitive: false)));
    });

    test('dedupes the same exotic hash', () {
      final r = evaluateExoticLimits(
        const ExoticComposition(
          exoticWeaponHashes: [5, 5],
          exoticArmorHashes: [9, 9, 9],
        ),
      );
      expect(r.hardBlocks, isEmpty);
    });

    test('ignores zero/invalid hashes', () {
      final r = evaluateExoticLimits(
        const ExoticComposition(
          exoticWeaponHashes: [0, -1, 3],
          exoticArmorHashes: [4],
        ),
      );
      expect(r.hardBlocks, isEmpty);
    });
  });

  group('evaluateSynergyRequirement', () {
    test('blocks empty synergy list', () {
      expect(
        evaluateSynergyRequirement([]).hardBlocks.first.code,
        DomainFailureCodes.noSynergy,
      );
    });

    test('allows non-empty', () {
      expect(
        evaluateSynergyRequirement([
          {'type': 'verb'},
        ]).hardBlocks,
        isEmpty,
      );
    });
  });

  group('mergeConstraintEvaluations', () {
    test('concatenates blocks', () {
      final r = mergeConstraintEvaluations([
        evaluateSynergyRequirement([]),
        evaluateExoticLimits(
          const ExoticComposition(
            exoticWeaponHashes: [1, 2],
            exoticArmorHashes: [],
          ),
        ),
      ]);
      expect(r.hardBlocks, hasLength(2));
    });
  });

  group('evaluateSubclassKit', () {
    test('blocks more than 2 aspects', () {
      final r = evaluateSubclassKit(
        const SubclassKitEvalInput(
          aspectCount: 3,
          fragmentCount: 0,
          fragmentCapacity: 0,
        ),
      );
      expect(r.hardBlocks.first.code, DomainFailureCodes.illegalSubclassKit);
      expect(r.hardBlocks.first.message, matches(RegExp('aspects', caseSensitive: false)));
    });

    test('blocks fragments over capacity', () {
      final r = evaluateSubclassKit(
        const SubclassKitEvalInput(
          aspectCount: 2,
          fragmentCount: 5,
          fragmentCapacity: 4,
        ),
      );
      expect(
        r.hardBlocks.any((b) => b.message.contains('fragments')),
        isTrue,
      );
    });

    test('allows fragments at capacity', () {
      final r = evaluateSubclassKit(
        const SubclassKitEvalInput(
          aspectCount: 2,
          fragmentCount: 4,
          fragmentCapacity: 4,
        ),
      );
      expect(r.hardBlocks, isEmpty);
    });

    test('skips fragment check when capacity not resolved', () {
      final r = evaluateSubclassKit(
        const SubclassKitEvalInput(
          aspectCount: 2,
          fragmentCount: 99,
          fragmentCapacity: 0,
          capacityResolved: false,
        ),
      );
      expect(r.hardBlocks, isEmpty);
    });

    test('capacityResolved false still blocks too many aspects', () {
      final r = evaluateSubclassKit(
        const SubclassKitEvalInput(
          aspectCount: 3,
          fragmentCount: 99,
          fragmentCapacity: 0,
          capacityResolved: false,
        ),
      );
      expect(r.hardBlocks, hasLength(1));
      expect(r.hardBlocks.first.message, matches(RegExp('aspects', caseSensitive: false)));
    });

    test('default capacityResolved true enforces fragments', () {
      final r = evaluateSubclassKitFields(
        aspectCount: 2,
        fragmentCount: 5,
        fragmentCapacity: 4,
      );
      expect(r.hardBlocks, isNotEmpty);
    });
  });

  group('evaluateModEnergy', () {
    test('blocks over-capacity pieces', () {
      final r = evaluateModEnergy([
        const ModEnergyPiece(
          slot: 'Helmet',
          energyUsed: 12,
          energyCapacity: 10,
        ),
      ]);
      expect(r.hardBlocks.first.code, DomainFailureCodes.modEnergyExceeded);
    });

    test('allows under capacity', () {
      expect(
        evaluateModEnergy([
          const ModEnergyPiece(
            slot: 'Arms',
            energyUsed: 10,
            energyCapacity: 10,
          ),
        ]).hardBlocks,
        isEmpty,
      );
    });
  });

  group('evaluateExoticAbilityMatch', () {
    test('blocks mismatched super', () {
      final r = evaluateExoticAbilityMatch(
        required: const AbilityKit(superAbility: 'Thundercrash'),
        kit: const AbilityKit(superAbility: 'Hammer of Sol'),
        pinnedSuper: null,
      );
      expect(r.hardBlocks.first.code, DomainFailureCodes.exoticAbilityMismatch);
      expect(
        r.softWarnings.single.code,
        DomainFailureCodes.exoticAbilityPinProposed,
      );
    });

    test('accepts pinned super over kit super', () {
      final r = evaluateExoticAbilityMatch(
        required: const AbilityKit(superAbility: 'Thundercrash'),
        kit: const AbilityKit(superAbility: 'Hammer of Sol'),
        pinnedSuper: 'Thundercrash',
      );
      expect(r.hardBlocks, isEmpty);
      expect(r.softWarnings, isEmpty);
    });

    test('no-ops when no requirements', () {
      expect(
        evaluateExoticAbilityMatch(
          required: const AbilityKit(),
          kit: const AbilityKit(superAbility: 'X'),
        ).hardBlocks,
        isEmpty,
      );
    });

    test('case-insensitive ability name match', () {
      final r = evaluateExoticAbilityMatch(
        required: const AbilityKit(superAbility: 'thundercrash'),
        kit: const AbilityKit(superAbility: 'Thundercrash'),
      );
      expect(r.hardBlocks, isEmpty);
    });
  });

  group('hard-block codes stable', () {
    test('codes match DomainFailureCodes and TS strings', () {
      expect(
        evaluateExoticLimits(
          const ExoticComposition(
            exoticWeaponHashes: [1, 2],
            exoticArmorHashes: [],
          ),
        ).hardBlocks.first.code,
        'TOO_MANY_EXOTICS',
      );
      expect(
        evaluateSubclassKit(
          const SubclassKitEvalInput(
            aspectCount: 3,
            fragmentCount: 0,
            fragmentCapacity: 0,
          ),
        ).hardBlocks.first.code,
        'ILLEGAL_SUBCLASS_KIT',
      );
      expect(
        evaluateModEnergy([
          const ModEnergyPiece(
            slot: 'Helmet',
            energyUsed: 12,
            energyCapacity: 10,
          ),
        ]).hardBlocks.first.code,
        'MOD_ENERGY_EXCEEDED',
      );
      expect(
        evaluateExoticAbilityMatch(
          required: const AbilityKit(melee: 'A'),
          kit: const AbilityKit(melee: 'B'),
        ).hardBlocks.first.code,
        'EXOTIC_ABILITY_MISMATCH',
      );
      expect(
        evaluateSynergyRequirement([]).hardBlocks.first.code,
        'NO_SYNERGY',
      );
    });
  });
}
