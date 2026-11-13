import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('resolveFillInInventoryCap', () {
    test('keeps values in 1–4 and falls invalid back to 2', () {
      expect(resolveFillInInventoryCap(1), 1);
      expect(resolveFillInInventoryCap(2), 2);
      expect(resolveFillInInventoryCap(3), 3);
      expect(resolveFillInInventoryCap(4), 4);
      expect(resolveFillInInventoryCap(null), 2);
      expect(resolveFillInInventoryCap(0), 2);
      expect(resolveFillInInventoryCap(5), 2);
      expect(resolveFillInInventoryCap(-1), 2);
      expect(resolveFillInInventoryCap(99), 2);
    });
  });

  group('moreThanHeldLabel', () {
    test('is a label only — string with no action payload', () {
      expect(moreThanHeldLabel(2), 'More than 2 held');
      expect(moreThanHeldLabel(4), 'More than 4 held');
    });
  });

  group('matchFillIn', () {
    const techsec = 1001;
    const solipsismHash = 9001;
    const sunshotHash = 3118677280;

    FillInInventoryItem legendary({
      required String id,
      required GuardianClass cls,
      required EquipmentSlot slot,
      int setHash = techsec,
      int itemHash = 10,
    }) {
      return FillInInventoryItem(
        instanceId: id,
        itemHash: itemHash,
        guardianClass: cls,
        slot: slot,
        isExotic: false,
        armorSetHash: setHash,
      );
    }

    FillInInventoryItem exoticArmor({
      required String id,
      required int hash,
      required GuardianClass cls,
      EquipmentSlot slot = EquipmentSlot.classItem,
    }) {
      return FillInInventoryItem(
        instanceId: id,
        itemHash: hash,
        guardianClass: cls,
        slot: slot,
        isExotic: true,
      );
    }

    FillInInventoryItem exoticWeapon({
      required String id,
      required int hash,
      EquipmentSlot slot = EquipmentSlot.special,
    }) {
      return FillInInventoryItem(
        instanceId: id,
        itemHash: hash,
        guardianClass: null,
        slot: slot,
        isExotic: true,
      );
    }

    FillInBuildRequirement build({
      required String id,
      required GuardianClass cls,
      required List<FillInSlotRequirement> slots,
      String subclass = 'prismatic',
      String? exoticName = 'Aeon Soul',
    }) {
      return FillInBuildRequirement(
        buildId: id,
        guardianClass: cls,
        subclassKey: subclass,
        exoticArmorName: exoticName,
        slots: slots,
      );
    }

    test('two builds share one physical legendary copy', () {
      final inventory = [
        legendary(
          id: 'copy-a',
          cls: GuardianClass.warlock,
          slot: EquipmentSlot.helmet,
        ),
      ];
      const need = FillInSlotRequirement(
        slot: EquipmentSlot.helmet,
        isExotic: false,
        armorSetHash: techsec,
      );
      final report = matchFillIn(
        inventory: inventory,
        builds: [
          build(id: 'b1', cls: GuardianClass.warlock, slots: [need]),
          build(id: 'b2', cls: GuardianClass.warlock, slots: [need]),
        ],
        inventoryCap: 2,
      );

      expect(report.builds, hasLength(2));
      for (final result in report.builds) {
        final slot = result.slots.single;
        expect(slot.isHeld, isTrue);
        expect(slot.poolHeldCount, 1);
        expect(slot.exceedsCap, isFalse);
        expect(slot.overCapLabel, isNull);
        expect(result.solipsismNotPrismatic, isFalse);
      }
    });

    test('wrong-class same-set piece does not fill the need', () {
      final report = matchFillIn(
        inventory: [
          legendary(
            id: 'titan-helm',
            cls: GuardianClass.titan,
            slot: EquipmentSlot.helmet,
          ),
        ],
        builds: [
          build(
            id: 'warlock',
            cls: GuardianClass.warlock,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.helmet,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
        ],
      );

      final slot = report.builds.single.slots.single;
      expect(slot.isHeld, isFalse);
      expect(slot.poolHeldCount, 0);
    });

    test('exotic armor held on another class does not count', () {
      final report = matchFillIn(
        inventory: [
          exoticArmor(
            id: 'exo-titan',
            hash: solipsismHash,
            cls: GuardianClass.titan,
            slot: EquipmentSlot.classItem,
          ),
        ],
        builds: [
          build(
            id: 'warlock',
            cls: GuardianClass.warlock,
            exoticName: 'Solipsism',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: solipsismHash,
              ),
            ],
          ),
        ],
      );

      final slot = report.builds.single.slots.single;
      expect(slot.isHeld, isFalse);
      expect(slot.poolHeldCount, 0);
    });

    test('exotic armor same class + hash counts', () {
      final report = matchFillIn(
        inventory: [
          exoticArmor(
            id: 'exo-1',
            hash: solipsismHash,
            cls: GuardianClass.warlock,
            slot: EquipmentSlot.classItem,
          ),
        ],
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.warlock,
            exoticName: 'Solipsism',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: solipsismHash,
              ),
            ],
          ),
        ],
      );

      final slot = report.builds.single.slots.single;
      expect(slot.isHeld, isTrue);
      expect(slot.poolHeldCount, 1);
    });

    test('exotic weapon matches by hash with no class', () {
      final report = matchFillIn(
        inventory: [
          exoticWeapon(id: 'gun-1', hash: sunshotHash),
        ],
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.hunter,
            exoticName: 'Lucky Pants',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.special,
                isExotic: true,
                exoticItemHash: sunshotHash,
              ),
            ],
          ),
        ],
      );

      final slot = report.builds.single.slots.single;
      expect(slot.isHeld, isTrue);
      expect(slot.poolHeldCount, 1);
    });

    test('one physical item is never counted in two slots', () {
      final report = matchFillIn(
        inventory: [
          // Same instance id appearing twice with conflicting slots — first wins.
          legendary(
            id: 'dup',
            cls: GuardianClass.warlock,
            slot: EquipmentSlot.helmet,
          ),
          legendary(
            id: 'dup',
            cls: GuardianClass.warlock,
            slot: EquipmentSlot.arms,
            itemHash: 11,
          ),
        ],
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.warlock,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.helmet,
                isExotic: false,
                armorSetHash: techsec,
              ),
              FillInSlotRequirement(
                slot: EquipmentSlot.arms,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
        ],
      );

      final slots = report.builds.single.slots;
      expect(slots[0].poolHeldCount, 1);
      expect(slots[1].poolHeldCount, 0);
      expect(slots[0].isHeld, isTrue);
      expect(slots[1].isHeld, isFalse);
    });

    test('over-cap yields label only (no action field)', () {
      final inventory = [
        for (var i = 0; i < 3; i++)
          legendary(
            id: 'h-$i',
            cls: GuardianClass.warlock,
            slot: EquipmentSlot.helmet,
            itemHash: 20 + i,
          ),
      ];
      final report = matchFillIn(
        inventory: inventory,
        inventoryCap: 2,
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.warlock,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.helmet,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
        ],
      );

      final slot = report.builds.single.slots.single;
      expect(slot.poolHeldCount, 3);
      expect(slot.exceedsCap, isTrue);
      expect(slot.overCapLabel, 'More than 2 held');
      expect(slot.isHeld, isTrue);
    });

    test('invalid cap falls back to 2 for over-cap label', () {
      final inventory = [
        for (var i = 0; i < 3; i++)
          legendary(
            id: 'x-$i',
            cls: GuardianClass.warlock,
            slot: EquipmentSlot.legs,
            itemHash: 30 + i,
          ),
      ];
      final report = matchFillIn(
        inventory: inventory,
        inventoryCap: 9,
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.warlock,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.legs,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
        ],
      );

      expect(report.cap, 2);
      expect(report.builds.single.slots.single.overCapLabel, 'More than 2 held');
    });

    test('Solipsism outside Prismatic is flagged, never silent OK', () {
      final report = matchFillIn(
        inventory: [
          exoticArmor(
            id: 'sol',
            hash: solipsismHash,
            cls: GuardianClass.warlock,
          ),
        ],
        builds: [
          build(
            id: 'bad',
            cls: GuardianClass.warlock,
            subclass: 'solar',
            exoticName: 'Solipsism',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: solipsismHash,
              ),
            ],
          ),
          build(
            id: 'ok',
            cls: GuardianClass.warlock,
            subclass: 'prismatic',
            exoticName: 'Solipsism',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: solipsismHash,
              ),
            ],
          ),
        ],
      );

      final bad = report.builds.firstWhere((b) => b.buildId == 'bad');
      final ok = report.builds.firstWhere((b) => b.buildId == 'ok');
      expect(bad.solipsismNotPrismatic, isTrue);
      expect(ok.solipsismNotPrismatic, isFalse);
      expect(bad.slots.single.isHeld, isTrue);
      expect(ok.slots.single.isHeld, isTrue);
    });

    test('null exotic Warlock is exoticArmorUnknown, not Prismatic text flag',
        () {
      final report = matchFillIn(
        inventory: const [],
        builds: [
          build(
            id: 'null-exo',
            cls: GuardianClass.warlock,
            subclass: 'prismatic',
            exoticName: null,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.helmet,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
        ],
      );
      final result = report.builds.single;
      expect(result.solipsismFlag, FillInSolipsismFlag.exoticArmorUnknown);
      expect(result.solipsismNotPrismatic, isFalse);
      expect(result.exoticArmorUnknown, isTrue);
      expect(result.hasSolipsismWarning, isTrue);
    });

    test('Swarmers + Strand is not flagged', () {
      final report = matchFillIn(
        inventory: const [],
        builds: [
          build(
            id: 'swarmers-strand',
            cls: GuardianClass.warlock,
            subclass: 'strand',
            exoticName: 'Swarmers',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.legs,
                isExotic: true,
                exoticItemHash: 42,
              ),
            ],
          ),
        ],
      );
      final result = report.builds.single;
      expect(result.solipsismFlag, FillInSolipsismFlag.none);
      expect(result.solipsismNotPrismatic, isFalse);
      expect(result.exoticArmorUnknown, isFalse);
    });

    test('Solipsism + Strand is flagged notPrismatic', () {
      final report = matchFillIn(
        inventory: const [],
        builds: [
          build(
            id: 'sol-strand',
            cls: GuardianClass.warlock,
            subclass: 'strand',
            exoticName: 'Solipsism',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: solipsismHash,
              ),
            ],
          ),
        ],
      );
      final result = report.builds.single;
      expect(result.solipsismFlag, FillInSolipsismFlag.notPrismatic);
      expect(result.solipsismNotPrismatic, isTrue);
    });

    test('unknown subclass Warlock is exoticArmorUnknown, not Prismatic flag',
        () {
      final report = matchFillIn(
        inventory: [
          exoticArmor(
            id: 'sol',
            hash: solipsismHash,
            cls: GuardianClass.warlock,
          ),
        ],
        builds: [
          build(
            id: 'unknown-sub',
            cls: GuardianClass.warlock,
            subclass: 'not-a-subclass',
            exoticName: 'Solipsism',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: solipsismHash,
              ),
            ],
          ),
        ],
      );
      final result = report.builds.single;
      expect(result.solipsismFlag, FillInSolipsismFlag.exoticArmorUnknown);
      expect(result.solipsismNotPrismatic, isFalse);
      expect(result.exoticArmorUnknown, isTrue);
    });

    test('Titan null exotic / unknown subclass is not fail-closed flagged', () {
      final report = matchFillIn(
        inventory: const [],
        builds: [
          build(
            id: 'titan-null',
            cls: GuardianClass.titan,
            subclass: 'prismatic',
            exoticName: null,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.helmet,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
          build(
            id: 'titan-unknown-sub',
            cls: GuardianClass.titan,
            subclass: 'not-a-subclass',
            exoticName: 'Synthoceps',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.arms,
                isExotic: true,
                exoticItemHash: 42,
              ),
            ],
          ),
        ],
      );
      expect(report.builds[0].solipsismFlag, FillInSolipsismFlag.none);
      expect(report.builds[1].solipsismFlag, FillInSolipsismFlag.none);
      expect(report.builds[0].solipsismNotPrismatic, isFalse);
      expect(report.builds[1].solipsismNotPrismatic, isFalse);
    });

    test('Hunter null exotic / unknown subclass is not fail-closed flagged', () {
      final report = matchFillIn(
        inventory: const [],
        builds: [
          build(
            id: 'hunter-null',
            cls: GuardianClass.hunter,
            subclass: 'solar',
            exoticName: null,
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.legs,
                isExotic: false,
                armorSetHash: techsec,
              ),
            ],
          ),
          build(
            id: 'hunter-unknown-sub',
            cls: GuardianClass.hunter,
            subclass: '',
            exoticName: 'Lucky Pants',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.legs,
                isExotic: true,
                exoticItemHash: 99,
              ),
            ],
          ),
        ],
      );
      expect(report.builds[0].solipsismFlag, FillInSolipsismFlag.none);
      expect(report.builds[1].solipsismFlag, FillInSolipsismFlag.none);
      expect(report.builds[0].solipsismNotPrismatic, isFalse);
      expect(report.builds[1].solipsismNotPrismatic, isFalse);
    });

    test('exotic weapons never get an over-cap label', () {
      final inventory = [
        for (var i = 0; i < 3; i++)
          exoticWeapon(id: 'gun-$i', hash: sunshotHash),
      ];
      final report = matchFillIn(
        inventory: inventory,
        inventoryCap: 2,
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.warlock,
            exoticName: 'Aeon Soul',
            slots: const [
              FillInSlotRequirement(
                slot: EquipmentSlot.special,
                isExotic: true,
                exoticItemHash: sunshotHash,
              ),
            ],
          ),
        ],
      );

      final slot = report.builds.single.slots.single;
      expect(slot.poolHeldCount, 3);
      expect(slot.isHeld, isTrue);
      expect(slot.exceedsCap, isFalse);
      expect(slot.overCapLabel, isNull);
    });
  });
}
