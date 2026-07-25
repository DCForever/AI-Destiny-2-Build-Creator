import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// Golden / separation tests for DART-004 soft coverage + soft stats.
void main() {
  group('tierForMatches', () {
    test('maps all/some/none', () {
      expect(tierForMatches(2, 2), CoverageTier.supported);
      expect(tierForMatches(1, 2), CoverageTier.weak);
      expect(tierForMatches(0, 2), CoverageTier.missing);
      expect(tierForMatches(0, 0), CoverageTier.missing);
    });
  });

  group('matchEvidenceLink', () {
    test('matches weapon by itemHash', () {
      final ok = matchEvidenceLink(
        _link(
          kind: SynergyLinkKind.weapon,
          displayName: 'Gun',
          itemHash: 10,
        ),
        [_claim(slot: EquipmentSlot.primary, itemHash: 10)],
      );
      expect(ok, isTrue);
    });

    test('matches weapon_perk via selectedPerks', () {
      final ok = matchEvidenceLink(
        _link(
          kind: SynergyLinkKind.weaponPerk,
          displayName: 'Perk',
          perkHash: 99,
        ),
        [
          _claim(
            slot: EquipmentSlot.primary,
            itemHash: 1,
            selectedPerks: [99],
          ),
        ],
      );
      expect(ok, isTrue);
    });

    test('matches origin_trait via selectedPerks', () {
      final ok = matchEvidenceLink(
        _link(
          kind: SynergyLinkKind.originTrait,
          displayName: 'Origin',
          originTraitHash: 55,
        ),
        [
          _claim(
            slot: EquipmentSlot.special,
            itemHash: 2,
            selectedPerks: [55],
          ),
        ],
      );
      expect(ok, isTrue);
    });
  });

  group('evaluateCoverage synergies', () {
    test('reports supported / weak / missing', () {
      final links = [
        _link(id: 'a', kind: SynergyLinkKind.weapon, displayName: 'A', itemHash: 1),
        _link(id: 'b', kind: SynergyLinkKind.weapon, displayName: 'B', itemHash: 2),
      ];
      final syn = _synergy('Trace', links);

      final supported = evaluateCoverage(
        CoverageEvalInput(
          claims: [
            _claim(slot: EquipmentSlot.primary, itemHash: 1),
            _claim(slot: EquipmentSlot.special, itemHash: 2),
          ],
          synergies: [syn],
          subclassElement: 'Arc',
        ),
      );
      expect(supported.synergies.single.tier, CoverageTier.supported);
      expect(supported.synergies.single.hint, isNull);

      final weak = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.primary, itemHash: 1)],
          synergies: [syn],
          subclassElement: 'Arc',
        ),
      );
      expect(weak.synergies.single.tier, CoverageTier.weak);
      expect(weak.synergies.single.unmatchedLinks, hasLength(1));
      expect(weak.synergies.single.hint, isNotNull);

      final missing = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.primary, itemHash: 9)],
          synergies: [syn],
          subclassElement: 'Arc',
        ),
      );
      expect(missing.synergies.single.tier, CoverageTier.missing);
    });

    test('does not invent softStats when no targets/estimate', () {
      final result = evaluateCoverage(
        const CoverageEvalInput(claims: [], synergies: []),
      );
      expect(result.softStats, isEmpty);
      expect(result.targets, const SoftStatTargets());
      expect(result.setBonuses, isEmpty);
      expect(result.elementMismatches, isEmpty);
    });
  });

  group('evaluateCoverage set-bonus and element', () {
    test('reports partial set-bonus soft row', () {
      const record = SetBonusRecord(
        hash: 500,
        name: 'Field-Tested',
        perks: [
          SetBonusPerk(requiredCount: 2, name: '2pc'),
          SetBonusPerk(requiredCount: 4, name: '4pc'),
        ],
      );
      final byHash = <int, SetBonusRecord>{
        101: record,
        102: record,
      };
      final result = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.helmet, itemHash: 101)],
          synergies: const [],
          subclassElement: 'Solar',
          setBonusByItemHash: byHash,
        ),
      );
      expect(result.setBonuses, hasLength(1));
      expect(result.setBonuses.single.setName, 'Field-Tested');
      expect(result.setBonuses.single.pieceCount, 1);
      expect(result.setBonuses.single.status, SetBonusSoftStatus.partial);
      expect(result.setBonuses.single.hint, isNotNull);
    });

    test('reports element soft mismatch for off-element special', () {
      final result = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.special, itemHash: 77)],
          synergies: const [],
          subclassElement: 'Void',
          weaponElementByHash: const {77: 'Solar'},
        ),
      );
      expect(result.elementMismatches, hasLength(1));
      expect(result.elementMismatches.single.hint, contains('Solar'));
    });

    test('skips kinetic weapons and Prismatic subclass', () {
      final kinetic = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.primary, itemHash: 1)],
          synergies: const [],
          subclassElement: 'Void',
          weaponElementByHash: const {1: 'Kinetic'},
        ),
      );
      expect(kinetic.elementMismatches, isEmpty);

      final prismatic = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.special, itemHash: 2)],
          synergies: const [],
          subclassElement: 'Prismatic',
          weaponElementByHash: const {2: 'Solar'},
        ),
      );
      expect(prismatic.elementMismatches, isEmpty);
    });
  });

  group('softStatTargets', () {
    test('accepts EoF six in range', () {
      final t = normalizeSoftStatTargets({
        'Health': 100,
        'Weapons': 80,
      });
      expect(t[ArmorStatName.health], 100);
      expect(t[ArmorStatName.weapons], 80);
    });

    test('rejects out of range and unknown keys', () {
      expect(
        () => normalizeSoftStatTargets({'Health': 201}),
        throwsA(isA<SoftStatTargetsException>()),
      );
      expect(
        () => normalizeSoftStatTargets({'Strength': 50}),
        throwsA(
          isA<SoftStatTargetsException>().having(
            (e) => e.code,
            'code',
            'INVALID_ITEM',
          ),
        ),
      );
    });

    test('merge never lowers existing', () {
      final merged = mergeSoftStatTargets(
        const SoftStatTargets({ArmorStatName.health: 120}),
        const SoftStatTargets({
          ArmorStatName.health: 100,
          ArmorStatName.melee: 80,
        }),
      );
      expect(merged[ArmorStatName.health], 120);
      expect(merged[ArmorStatName.melee], 80);
    });
  });

  group('softStatWarnings + estimateLoadoutStats', () {
    test('emits below-target rows only', () {
      final rows = softStatWarnings(
        const SoftStatTargets({
          ArmorStatName.health: 100,
          ArmorStatName.weapons: 50,
        }),
        const StatEstimate(
          values: {
            ArmorStatName.health: 72,
            ArmorStatName.weapons: 60,
            ArmorStatName.melee: 0,
            ArmorStatName.grenade: 0,
            ArmorStatName.superStat: 0,
            ArmorStatName.classStat: 0,
          },
          incomplete: true,
        ),
      );
      expect(rows, hasLength(1));
      expect(rows.single.stat, ArmorStatName.health);
    });

    test('marks incomplete without instance stats', () {
      final estimate = estimateLoadoutStats(
        [_claim(slot: EquipmentSlot.helmet, itemHash: 1)],
        const {},
      );
      expect(estimate.incomplete, isTrue);
    });

    test('sums instance stats when complete armor set', () {
      final claims = [
        for (final slot in EquipmentSlot.armorSlots)
          SlotClaim(
            slot: slot,
            itemHash: slot.index + 1,
            itemName: slot.wireName,
            source: ClaimSource.set,
            instanceId: 'i-${slot.wireName}',
          ),
      ];
      final inventory = {
        for (final slot in EquipmentSlot.armorSlots)
          'i-${slot.wireName}': {ArmorStatName.health: 10},
      };
      final estimate = estimateLoadoutStats(claims, inventory);
      expect(estimate.incomplete, isFalse);
      expect(estimate[ArmorStatName.health], 50);
    });

    test('evaluateCoverage attaches softStats when estimate provided', () {
      final result = evaluateCoverage(
        const CoverageEvalInput(
          claims: [],
          synergies: [],
          softStatTargets: SoftStatTargets({ArmorStatName.melee: 100}),
          statEstimate: StatEstimate(
            values: {ArmorStatName.melee: 40},
            incomplete: true,
          ),
        ),
      );
      expect(result.softStats, hasLength(1));
      expect(result.softStats.single.stat, ArmorStatName.melee);
    });
  });

  group('statNudges', () {
    test('suggests from synergy type and accept merges up', () {
      final nudges = suggestStatNudges([
        const SynergyTypeDesignation(type: SynergyType('melee')),
      ]);
      expect(nudges.single.stat, ArmorStatName.melee);
      expect(
        targetsFromAcceptedNudges(
          const SoftStatTargets({ArmorStatName.melee: 120}),
          nudges,
        )[ArmorStatName.melee],
        120,
      );
      expect(
        targetsFromAcceptedNudges(const SoftStatTargets(), nudges)[
            ArmorStatName.melee],
        100,
      );
    });
  });

  group('hard vs soft separation (DBR-GUID)', () {
    test('CoverageResult has no hard-block semantics', () {
      final result = evaluateCoverage(
        CoverageEvalInput(
          claims: [_claim(slot: EquipmentSlot.special, itemHash: 77)],
          synergies: [
            _synergy('Trace', [
              _link(
                id: 'a',
                kind: SynergyLinkKind.weapon,
                displayName: 'A',
                itemHash: 1,
              ),
              _link(
                id: 'b',
                kind: SynergyLinkKind.weapon,
                displayName: 'B',
                itemHash: 2,
              ),
            ]),
          ],
          subclassElement: 'Void',
          weaponElementByHash: const {77: 'Solar'},
          softStatTargets: const SoftStatTargets({ArmorStatName.health: 100}),
          statEstimate: const StatEstimate(
            values: {ArmorStatName.health: 10},
            incomplete: true,
          ),
          setBonusByItemHash: const {
            101: SetBonusRecord(
              hash: 500,
              name: 'Field-Tested',
              perks: [
                SetBonusPerk(requiredCount: 2, name: '2pc'),
              ],
            ),
          },
        ),
      );

      // Soft-only surface: weak/missing coverage + element mismatch + soft stats.
      expect(result.synergies.single.tier, CoverageTier.missing);
      expect(result.elementMismatches, isNotEmpty);
      expect(result.softStats, isNotEmpty);

      // CoverageResult is not a ConstraintEvaluation and has no hardBlocks.
      expect(result, isA<CoverageResult>());
      expect(result, isNot(isA<ConstraintEvaluation>()));

      // Soft rows must not use pure hard-gate failure codes.
      for (final row in result.synergies) {
        expect(
          DomainFailureCodes.pureHardGateCodes.contains(row.tier.wireName),
          isFalse,
        );
      }
      for (final row in result.softStats) {
        expect(row.hint, isNot(contains('TOO_MANY_EXOTICS')));
        expect(row.hint, isNot(contains('ILLEGAL_SUBCLASS_KIT')));
      }
    });

    test('weak coverage is not a hard block side-by-side with hard evaluator', () {
      final soft = evaluateCoverage(
        CoverageEvalInput(
          claims: const [],
          synergies: [
            _synergy('Empty', [
              _link(
                kind: SynergyLinkKind.weapon,
                displayName: 'Missing',
                itemHash: 1,
              ),
            ]),
          ],
        ),
      );
      expect(soft.synergies.single.tier, CoverageTier.missing);

      // Hard path is independent: legal exotic composition still empty hardBlocks.
      final hard = evaluateExoticLimits(
        const ExoticComposition(
          exoticWeaponHashes: [1],
          exoticArmorHashes: [2],
        ),
      );
      expect(hard.hardBlocks, isEmpty);
      expect(hard.isHardBlocked, isFalse);

      // Soft missing coverage does not become hard-blocked.
      expect(soft, isNot(isA<ConstraintEvaluation>()));
    });

    test('soft evaluators do not mutate input claim lists', () {
      final claims = [
        _claim(slot: EquipmentSlot.primary, itemHash: 1),
      ];
      final beforeLen = claims.length;
      evaluateCoverage(
        CoverageEvalInput(
          claims: claims,
          synergies: [
            _synergy('S', [
              _link(
                kind: SynergyLinkKind.weapon,
                displayName: 'A',
                itemHash: 1,
              ),
            ]),
          ],
        ),
      );
      expect(claims.length, beforeLen);
      expect(claims.single.itemHash, 1);
    });

    test('stat nudges are not auto-applied by coverage', () {
      final designations = [
        const SynergyTypeDesignation(type: SynergyType('grenade')),
      ];
      final nudges = suggestStatNudges(designations);
      expect(nudges, isNotEmpty);

      final coverage = evaluateCoverage(
        const CoverageEvalInput(claims: [], synergies: []),
      );
      // Coverage alone does not invent targets from designations.
      expect(coverage.targets.isEmpty, isTrue);
      expect(coverage.softStats, isEmpty);

      // Only explicit accept merge writes targets.
      final accepted = targetsFromAcceptedNudges(const SoftStatTargets(), nudges);
      expect(accepted[ArmorStatName.grenade], 100);
    });
  });
}

SynergyLink _link({
  String? id,
  required SynergyLinkKind kind,
  required String displayName,
  int? itemHash,
  int? perkHash,
  int? originTraitHash,
  int? armorSetHash,
  String? armorSetName,
  int? bonusPieces,
}) {
  return SynergyLink(
    id: id ?? 'link-${displayName.hashCode}',
    synergyId: 'syn',
    kind: kind,
    displayName: displayName,
    itemHash: itemHash,
    perkHash: perkHash,
    originTraitHash: originTraitHash,
    armorSetHash: armorSetHash,
    armorSetName: armorSetName,
    bonusPieces: bonusPieces,
  );
}

Synergy _synergy(String name, List<SynergyLink> links) {
  return Synergy(
    id: 'syn-1',
    name: name,
    type: const SynergyType('melee'),
    links: links,
  );
}

SlotClaim _claim({
  required EquipmentSlot slot,
  required int itemHash,
  String itemName = 'Item',
  List<int>? selectedPerks,
  String? instanceId,
}) {
  return SlotClaim(
    slot: slot,
    itemHash: itemHash,
    itemName: itemName,
    source: ClaimSource.set,
    selectedPerks: selectedPerks,
    instanceId: instanceId,
  );
}
