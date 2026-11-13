import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('planFillInSubstitutes', () {
    test('held slot pins instance without substitute change', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'h1',
          itemHash: 10,
          name: 'Helmet A',
          slot: EquipmentSlot.helmet,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 100,
        ),
      ];
      final requirement = FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'prismatic',
        slots: const [
          FillInSlotRequirement(
            slot: EquipmentSlot.helmet,
            isExotic: false,
            armorSetHash: 100,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.helmet: 'Helmet A'},
      );

      expect(diffs, hasLength(1));
      expect(diffs.single.isHeld, isTrue);
      expect(diffs.single.wouldSubstitute, isFalse);
      expect(diffs.single.heldInstanceId, 'h1');
      expect(diffs.single.applyInstanceId, 'h1');
    });

    test('missing weapon proposes similar substitute', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'w1',
          itemHash: 99,
          name: "Zaouli's Bane",
          slot: EquipmentSlot.special,
          isExotic: true,
          guardianClass: null,
          weaponType: 'Hand Cannon',
          damageType: 'Solar',
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'solar',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.special,
            isExotic: true,
            exoticItemHash: 1,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;
      expect(match.slots.single.isHeld, isFalse);

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.special: 'Sunshot'},
        weaponNeed: const FillInWeaponNeed(
          name: 'Sunshot',
          slot: EquipmentSlot.special,
          weaponType: 'Hand Cannon',
          damageType: 'Solar',
        ),
      );

      expect(diffs.single.wouldSubstitute, isTrue);
      expect(diffs.single.substituteLabel, "Zaouli's Bane");
      expect(diffs.single.substituteInstanceId, 'w1');
      expect(diffs.single.isExotic, isTrue);
    });

    test('empty weapon current label is No weapon in DIM link not wire name', () {
      final inventory = <FillInInventoryItem>[];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.primary,
            isExotic: true,
            exoticItemHash: 1,
          ),
          FillInSlotRequirement(
            slot: EquipmentSlot.heavy,
            isExotic: false,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {},
      );

      expect(diffs, hasLength(2));
      expect(
        diffs.map((d) => d.currentLabel).toSet(),
        {kFillInNoWeaponInDimLink},
      );
      expect(
        diffs.every((d) => !const {'primary', 'special', 'heavy'}
            .contains(d.currentLabel.toLowerCase())),
        isTrue,
      );
    });

    test('no held weapon in energy bucket stays missing (not wrong-bucket)', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'w1',
          itemHash: 99,
          name: 'Qua Nilus II',
          slot: EquipmentSlot.primary,
          isExotic: false,
          guardianClass: null,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.primary,
            isExotic: true,
            exoticItemHash: 8001,
          ),
          FillInSlotRequirement(
            slot: EquipmentSlot.special,
            isExotic: false,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {
          EquipmentSlot.primary: 'Barrow-Dyad',
        },
        weaponNeed: const FillInWeaponNeed(
          name: 'Barrow-Dyad',
          slot: EquipmentSlot.primary,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
      );

      final primary = diffs.singleWhere((d) => d.slot == EquipmentSlot.primary);
      final energy = diffs.singleWhere((d) => d.slot == EquipmentSlot.special);
      expect(primary.substituteLabel, 'Qua Nilus II');
      // Kinetic-only inventory must never fill Energy from the wrong bucket.
      expect(energy.substituteLabel, isNull);
      expect(energy.currentLabel, kFillInNoWeaponInDimLink);
    });

    test(
      'held kinetic exotic + empty energy/power get same-bucket substitutes',
      () {
        final inventory = [
          const FillInInventoryItem(
            instanceId: 'kin-held',
            itemHash: 8001,
            name: 'Barrow-Dyad',
            slot: EquipmentSlot.primary,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Sidearm',
            damageType: 'Strand',
          ),
          const FillInInventoryItem(
            instanceId: 'ene-1',
            itemHash: 9001,
            name: 'Funnelweb',
            slot: EquipmentSlot.special,
            isExotic: false,
            guardianClass: null,
            weaponType: 'Submachine Gun',
            damageType: 'Void',
          ),
          const FillInInventoryItem(
            instanceId: 'pow-1',
            itemHash: 9002,
            name: 'Cataclysmic',
            slot: EquipmentSlot.heavy,
            isExotic: false,
            guardianClass: null,
            weaponType: 'Linear Fusion Rifle',
            damageType: 'Solar',
          ),
          // Exotic energy — must NOT be picked while Kinetic already has exotic.
          const FillInInventoryItem(
            instanceId: 'ene-ex',
            itemHash: 9003,
            name: 'Riskrunner',
            slot: EquipmentSlot.special,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Submachine Gun',
            damageType: 'Arc',
          ),
        ];
        final requirement = const FillInBuildRequirement(
          buildId: 'b1',
          guardianClass: GuardianClass.warlock,
          subclassKey: 'strand',
          slots: [
            FillInSlotRequirement(
              slot: EquipmentSlot.primary,
              isExotic: true,
              exoticItemHash: 8001,
            ),
            FillInSlotRequirement(
              slot: EquipmentSlot.special,
              isExotic: false,
            ),
            FillInSlotRequirement(
              slot: EquipmentSlot.heavy,
              isExotic: false,
            ),
          ],
        );
        final match = matchFillIn(
          inventory: inventory,
          builds: [requirement],
        ).builds.single;

        final diffs = planFillInSubstitutes(
          match: match,
          requirement: requirement,
          inventory: inventory,
          currentLabels: const {
            EquipmentSlot.primary: 'Barrow-Dyad',
          },
        );

        final kinetic =
            diffs.singleWhere((d) => d.slot == EquipmentSlot.primary);
        final energy =
            diffs.singleWhere((d) => d.slot == EquipmentSlot.special);
        final power = diffs.singleWhere((d) => d.slot == EquipmentSlot.heavy);

        expect(kinetic.isHeld, isTrue);
        expect(kinetic.wouldSubstitute, isFalse);
        expect(energy.wouldSubstitute, isTrue);
        expect(energy.substituteLabel, 'Funnelweb');
        expect(energy.substituteLabel, isNot('Riskrunner'));
        expect(power.wouldSubstitute, isTrue);
        expect(power.substituteLabel, 'Cataclysmic');
        // Labels are for their own slot — never re-attribute kinetic exotic.
        expect(energy.currentLabel, kFillInNoWeaponInDimLink);
        expect(power.currentLabel, kFillInNoWeaponInDimLink);
      },
    );

    test('empty armor current label is blank not helmet wire name', () {
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.helmet,
            isExotic: false,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: const [],
        builds: [requirement],
      ).builds.single;
      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: const [],
        currentLabels: const {},
      );
      expect(diffs.single.currentLabel, isEmpty);
      expect(diffs.single.currentLabel.toLowerCase(), isNot('helmet'));
    });

    test(
      'no exotic on build: at most one exotic weapon substitute across slots',
      () {
        // Skeptic: empty exoticWeaponSlots used to leave excludeExotic=false
        // for every bucket, so held exotics could fill Kinetic+Energy+Power.
        final inventory = [
          const FillInInventoryItem(
            instanceId: 'ex-kin',
            itemHash: 501,
            name: 'Qua Nilus II',
            slot: EquipmentSlot.primary,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Sidearm',
            damageType: 'Strand',
          ),
          const FillInInventoryItem(
            instanceId: 'ex-ene',
            itemHash: 502,
            name: 'Riskrunner',
            slot: EquipmentSlot.special,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Submachine Gun',
            damageType: 'Arc',
          ),
          const FillInInventoryItem(
            instanceId: 'leg-pow',
            itemHash: 503,
            name: 'Cataclysmic',
            slot: EquipmentSlot.heavy,
            isExotic: false,
            guardianClass: null,
            weaponType: 'Linear Fusion Rifle',
            damageType: 'Solar',
          ),
          const FillInInventoryItem(
            instanceId: 'ex-pow',
            itemHash: 504,
            name: 'Parasite',
            slot: EquipmentSlot.heavy,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Grenade Launcher',
            damageType: 'Solar',
          ),
        ];
        final requirement = const FillInBuildRequirement(
          buildId: 'b1',
          guardianClass: GuardianClass.warlock,
          subclassKey: 'strand',
          slots: [
            // No isExotic weapon need — build has no exotic weapon.
            FillInSlotRequirement(
              slot: EquipmentSlot.primary,
              isExotic: false,
            ),
            FillInSlotRequirement(
              slot: EquipmentSlot.special,
              isExotic: false,
            ),
            FillInSlotRequirement(
              slot: EquipmentSlot.heavy,
              isExotic: false,
            ),
          ],
        );
        final match = matchFillIn(
          inventory: inventory,
          builds: [requirement],
        ).builds.single;

        final diffs = planFillInSubstitutes(
          match: match,
          requirement: requirement,
          inventory: inventory,
          currentLabels: const {},
        );

        final exoticSubs = [
          for (final d in diffs)
            if (d.wouldSubstitute &&
                (d.substituteLabel == 'Qua Nilus II' ||
                    d.substituteLabel == 'Riskrunner' ||
                    d.substituteLabel == 'Parasite'))
              d.substituteLabel,
        ];
        expect(
          exoticSubs,
          hasLength(1),
          reason: 'at most one exotic weapon pick when build has none',
        );
        final power = diffs.singleWhere((d) => d.slot == EquipmentSlot.heavy);
        expect(power.substituteLabel, 'Cataclysmic');
        expect(power.substituteLabel, isNot('Parasite'));
      },
    );

    test(
      'pre-scan treats held inventory exotic as used even when need is not',
      () {
        // Skeptic: a legendary weapon need can still resolve a held exotic
        // via exoticItemHash (name→hash stamp). need.isExotic alone misses
        // that — a second exotic must not slip into Energy.
        final inventory = [
          const FillInInventoryItem(
            instanceId: 'kin-ex',
            itemHash: 501,
            name: 'Riskrunner',
            slot: EquipmentSlot.primary,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Submachine Gun',
            damageType: 'Arc',
          ),
          const FillInInventoryItem(
            instanceId: 'ene-ex',
            itemHash: 502,
            name: 'Qua Nilus II',
            slot: EquipmentSlot.special,
            isExotic: true,
            guardianClass: null,
            weaponType: 'Sidearm',
            damageType: 'Strand',
          ),
          const FillInInventoryItem(
            instanceId: 'ene-leg',
            itemHash: 503,
            name: 'Funnelweb',
            slot: EquipmentSlot.special,
            isExotic: false,
            guardianClass: null,
            weaponType: 'Submachine Gun',
            damageType: 'Void',
          ),
        ];
        final requirement = const FillInBuildRequirement(
          buildId: 'b1',
          guardianClass: GuardianClass.warlock,
          subclassKey: 'arc',
          slots: [
            FillInSlotRequirement(
              slot: EquipmentSlot.primary,
              isExotic: false,
              exoticItemHash: 501,
            ),
            FillInSlotRequirement(
              slot: EquipmentSlot.special,
              isExotic: false,
            ),
          ],
        );
        final match = matchFillIn(
          inventory: inventory,
          builds: [requirement],
        ).builds.single;

        final diffs = planFillInSubstitutes(
          match: match,
          requirement: requirement,
          inventory: inventory,
          currentLabels: const {
            EquipmentSlot.primary: 'Riskrunner',
          },
        );

        final kinetic =
            diffs.singleWhere((d) => d.slot == EquipmentSlot.primary);
        final energy =
            diffs.singleWhere((d) => d.slot == EquipmentSlot.special);
        expect(kinetic.isHeld, isTrue);
        expect(energy.wouldSubstitute, isTrue);
        expect(energy.substituteLabel, 'Funnelweb');
        expect(energy.substituteLabel, isNot('Qua Nilus II'));
      },
    );

    test('exotic armor never substitutes a legendary cover', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'legs-leg',
          itemHash: 9999,
          name: 'Per Audacia Boots',
          slot: EquipmentSlot.legs,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 1,
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        exoticArmorName: 'Swarmers',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.legs,
            isExotic: true,
            exoticItemHash: 7001,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;
      expect(match.slots.single.isHeld, isFalse);

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.legs: 'Swarmers'},
      );
      expect(diffs.single.substituteLabel, isNull);
      expect(diffs.single.wouldSubstitute, isFalse);
    });

    test('missing armor proposes same-slot held substitute', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'a1',
          itemHash: 5,
          name: 'Spare Arms',
          slot: EquipmentSlot.arms,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 200,
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'void',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.arms,
            isExotic: false,
            armorSetHash: 100,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.arms: 'Needed Arms'},
      );

      expect(diffs.single.wouldSubstitute, isTrue);
      expect(diffs.single.substituteLabel, 'Spare Arms');
      expect(diffs.single.substituteInstanceId, 'a1');
    });
  });
}
