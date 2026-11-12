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

    FillInInventoryItem exotic({
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

    FillInBuildRequirement build({
      required String id,
      required GuardianClass cls,
      required List<FillInSlotRequirement> slots,
      String subclass = 'prismatic',
      String? exoticName,
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

    test('exotics match by item hash only', () {
      final report = matchFillIn(
        inventory: [
          exotic(
            id: 'exo-1',
            hash: solipsismHash,
            cls: GuardianClass.warlock,
            slot: EquipmentSlot.classItem,
          ),
        ],
        builds: [
          build(
            id: 'b',
            cls: GuardianClass.hunter,
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
          exotic(
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
  });
}
