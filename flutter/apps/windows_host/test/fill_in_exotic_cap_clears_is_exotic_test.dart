import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_dialog.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'enforceAtMostOneExoticWeapon clears isExotic on demoted substitute',
    () {
      // Held exotic Kinetic keeps the exotic slot; Energy exotic substitute
      // must be cleared AND lose isExotic so copy/save stay "Energy".
      const heldKinetic = FillInSlotDiff(
        slot: EquipmentSlot.primary,
        currentLabel: 'Qua Nilus II',
        isHeld: true,
        isExotic: true,
        heldInstanceId: 'held-kin',
        heldItemHash: 501,
      );
      const energyExoticSub = FillInSlotDiff(
        slot: EquipmentSlot.special,
        currentLabel: '',
        isHeld: false,
        isExotic: true,
        substituteLabel: 'Riskrunner',
        substituteInstanceId: 'sub-ene',
        substituteItemHash: 502,
      );
      const inventory = <FillInInventoryItem>[
        FillInInventoryItem(
          instanceId: 'held-kin',
          itemHash: 501,
          name: 'Qua Nilus II',
          slot: EquipmentSlot.primary,
          isExotic: true,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
        FillInInventoryItem(
          instanceId: 'sub-ene',
          itemHash: 502,
          name: 'Riskrunner',
          slot: EquipmentSlot.special,
          isExotic: true,
          weaponType: 'Submachine Gun',
          damageType: 'Arc',
        ),
      ];

      final out = enforceAtMostOneExoticWeapon(
        diffs: const [heldKinetic, energyExoticSub],
        inventory: inventory,
      );

      final energy = out.singleWhere((d) => d.slot == EquipmentSlot.special);
      expect(energy.wouldSubstitute, isFalse);
      expect(energy.isExotic, isFalse);
      expect(
        fillInMissingSlotLabel(slot: energy.slot, isExotic: energy.isExotic),
        'Energy',
      );
      expect(
        fillInMissingSlotLabel(slot: energy.slot, isExotic: energy.isExotic),
        isNot(contains('Exotic')),
      );

      final kinetic = out.singleWhere((d) => d.slot == EquipmentSlot.primary);
      expect(kinetic.isHeld, isTrue);
      expect(kinetic.isExotic, isTrue);
    },
  );

  test(
    'when preferring one of two exotic substitutes, the other clears isExotic',
    () {
      const kineticSub = FillInSlotDiff(
        slot: EquipmentSlot.primary,
        currentLabel: '',
        isHeld: false,
        isExotic: true,
        substituteLabel: 'Qua Nilus II',
        substituteInstanceId: 'k',
        substituteItemHash: 501,
      );
      const energySub = FillInSlotDiff(
        slot: EquipmentSlot.special,
        currentLabel: '',
        isHeld: false,
        isExotic: true,
        substituteLabel: 'Riskrunner',
        substituteInstanceId: 'e',
        substituteItemHash: 502,
      );
      const inventory = <FillInInventoryItem>[
        FillInInventoryItem(
          instanceId: 'k',
          itemHash: 501,
          name: 'Qua Nilus II',
          slot: EquipmentSlot.primary,
          isExotic: true,
        ),
        FillInInventoryItem(
          instanceId: 'e',
          itemHash: 502,
          name: 'Riskrunner',
          slot: EquipmentSlot.special,
          isExotic: true,
        ),
      ];

      final out = enforceAtMostOneExoticWeapon(
        diffs: const [kineticSub, energySub],
        inventory: inventory,
        preferLabels: {'riskrunner'},
      );

      final kept = out.singleWhere((d) => d.slot == EquipmentSlot.special);
      final cleared = out.singleWhere((d) => d.slot == EquipmentSlot.primary);
      expect(kept.wouldSubstitute, isTrue);
      expect(kept.isExotic, isTrue);
      expect(cleared.wouldSubstitute, isFalse);
      expect(cleared.isExotic, isFalse);
      expect(
        fillInSlotLabel(cleared.slot, isExotic: cleared.isExotic),
        'Kinetic',
      );
    },
  );
}
