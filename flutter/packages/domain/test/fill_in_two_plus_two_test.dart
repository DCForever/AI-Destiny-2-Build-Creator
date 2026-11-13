import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('assignFillInTwoPlusTwoSlots', () {
    const setA = 1001;
    const setB = 2002;

    FillInInventoryItem piece({
      required String id,
      required EquipmentSlot slot,
      required int setHash,
      GuardianClass cls = GuardianClass.warlock,
    }) {
      return FillInInventoryItem(
        instanceId: id,
        itemHash: setHash + slot.index,
        slot: slot,
        isExotic: false,
        guardianClass: cls,
        armorSetHash: setHash,
        name: 'piece-$id',
      );
    }

    test('first set takes first two held slots; second takes next two', () {
      // Hold A in helmet+chest+legs, B in arms+chest+legs.
      // Walk: helmet→A, arms→A? arms has B not A → skip for A; chest→A (A done).
      // Then remaining arms→B, legs→B.
      final inventory = [
        piece(id: 'a-h', slot: EquipmentSlot.helmet, setHash: setA),
        piece(id: 'b-a', slot: EquipmentSlot.arms, setHash: setB),
        piece(id: 'a-c', slot: EquipmentSlot.chest, setHash: setA),
        piece(id: 'b-c', slot: EquipmentSlot.chest, setHash: setB),
        piece(id: 'a-l', slot: EquipmentSlot.legs, setHash: setA),
        piece(id: 'b-l', slot: EquipmentSlot.legs, setHash: setB),
      ];

      final slots = assignFillInTwoPlusTwoSlots(
        firstSetHash: setA,
        secondSetHash: setB,
        guardianClass: GuardianClass.warlock,
        inventory: inventory,
      );

      expect(slots, hasLength(4));
      expect(slots[0].slot, EquipmentSlot.helmet);
      expect(slots[0].armorSetHash, setA);
      expect(slots[1].slot, EquipmentSlot.arms);
      expect(slots[1].armorSetHash, setB);
      expect(slots[2].slot, EquipmentSlot.chest);
      expect(slots[2].armorSetHash, setA);
      expect(slots[3].slot, EquipmentSlot.legs);
      expect(slots[3].armorSetHash, setB);

      final report = matchFillIn(
        inventory: inventory,
        builds: [
          FillInBuildRequirement(
            buildId: 'b',
            guardianClass: GuardianClass.warlock,
            subclassKey: 'prismatic',
            exoticArmorName: 'Aeon Soul',
            slots: slots,
          ),
        ],
      );
      expect(report.builds.single.slots.every((s) => s.isHeld), isTrue);
    });

    test('class item is never assigned by the 2+2 walk', () {
      final inventory = [
        piece(id: 'a-h', slot: EquipmentSlot.helmet, setHash: setA),
        piece(id: 'a-a', slot: EquipmentSlot.arms, setHash: setA),
        piece(id: 'b-c', slot: EquipmentSlot.chest, setHash: setB),
        piece(id: 'b-l', slot: EquipmentSlot.legs, setHash: setB),
        piece(id: 'a-ci', slot: EquipmentSlot.classItem, setHash: setA),
      ];

      final slots = assignFillInTwoPlusTwoSlots(
        firstSetHash: setA,
        secondSetHash: setB,
        guardianClass: GuardianClass.warlock,
        inventory: inventory,
      );

      expect(slots.map((s) => s.slot), kFillInTwoPlusTwoSlotOrder);
      expect(slots.any((s) => s.slot == EquipmentSlot.classItem), isFalse);
    });

    test('shortfall slots stay missing for the set that still needs pieces', () {
      // Only helmet held for A; only arms held for B.
      final inventory = [
        piece(id: 'a-h', slot: EquipmentSlot.helmet, setHash: setA),
        piece(id: 'b-a', slot: EquipmentSlot.arms, setHash: setB),
      ];

      final slots = assignFillInTwoPlusTwoSlots(
        firstSetHash: setA,
        secondSetHash: setB,
        guardianClass: GuardianClass.warlock,
        inventory: inventory,
      );

      final report = matchFillIn(
        inventory: inventory,
        builds: [
          FillInBuildRequirement(
            buildId: 'b',
            guardianClass: GuardianClass.warlock,
            subclassKey: 'solar',
            exoticArmorName: 'Starfire Protocol',
            slots: slots,
          ),
        ],
      );
      final bySlot = {
        for (final s in report.builds.single.slots) s.slot: s,
      };
      expect(bySlot[EquipmentSlot.helmet]!.isHeld, isTrue);
      expect(bySlot[EquipmentSlot.arms]!.isHeld, isTrue);
      expect(bySlot[EquipmentSlot.chest]!.isHeld, isFalse);
      expect(bySlot[EquipmentSlot.legs]!.isHeld, isFalse);
      // Leftover needs: A still wants one, B still wants one → chest then legs.
      expect(
        slots.firstWhere((s) => s.slot == EquipmentSlot.chest).armorSetHash,
        setA,
      );
      expect(
        slots.firstWhere((s) => s.slot == EquipmentSlot.legs).armorSetHash,
        setB,
      );
    });

    test('wrong-class pieces do not count toward assignment', () {
      final inventory = [
        piece(
          id: 'titan-a',
          slot: EquipmentSlot.helmet,
          setHash: setA,
          cls: GuardianClass.titan,
        ),
        piece(id: 'a-a', slot: EquipmentSlot.arms, setHash: setA),
        piece(id: 'a-c', slot: EquipmentSlot.chest, setHash: setA),
        piece(id: 'b-l', slot: EquipmentSlot.legs, setHash: setB),
        piece(id: 'b-h', slot: EquipmentSlot.helmet, setHash: setB),
      ];

      final slots = assignFillInTwoPlusTwoSlots(
        firstSetHash: setA,
        secondSetHash: setB,
        guardianClass: GuardianClass.warlock,
        inventory: inventory,
      );

      // Helmet has no Warlock setA — first A slots are arms+chest.
      expect(slots[0].armorSetHash, setB); // helmet held for B among leftovers…
      // Actually: A walk: arms→A, chest→A. B walk: helmet→B, legs→B.
      expect(
        slots.map((s) => s.armorSetHash).toList(),
        <int>[setB, setA, setA, setB],
      );
    });
  });
}
