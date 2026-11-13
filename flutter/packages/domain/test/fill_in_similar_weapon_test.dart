import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('suggestSimilarWeapon', () {
    FillInInventoryItem gun({
      required String id,
      required int hash,
      required String name,
      required EquipmentSlot slot,
      required String type,
      required String element,
      bool exotic = false,
    }) {
      return FillInInventoryItem(
        instanceId: id,
        itemHash: hash,
        name: name,
        slot: slot,
        isExotic: exotic,
        weaponType: type,
        damageType: element,
      );
    }

    const needSunshot = FillInWeaponNeed(
      name: 'Sunshot',
      slot: EquipmentSlot.special,
      damageType: 'Solar',
      weaponType: 'Hand Cannon',
    );

    test('prefers same slot + damage + type over slot + damage only', () {
      final held = [
        gun(
          id: 'smg',
          hash: 2,
          name: 'Riskrunner',
          slot: EquipmentSlot.special,
          type: 'Submachine Gun',
          element: 'Arc',
          exotic: true,
        ),
        gun(
          id: 'solar-smg',
          hash: 3,
          name: 'Calus Mini-Tool',
          slot: EquipmentSlot.special,
          type: 'Submachine Gun',
          element: 'Solar',
        ),
        gun(
          id: 'solar-hc',
          hash: 4,
          name: 'Zaouli\'s Bane',
          slot: EquipmentSlot.special,
          type: 'Hand Cannon',
          element: 'Solar',
        ),
      ];

      final suggestion = suggestSimilarWeapon(
        need: needSunshot,
        heldWeapons: held,
      );
      expect(suggestion, isNotNull);
      expect(suggestion!.tier, FillInSimilarWeaponTier.slotDamageType);
      expect(suggestion.item.name, "Zaouli's Bane");
    });

    test('falls back to same slot + damage when type differs', () {
      final held = [
        gun(
          id: 'kinetic-hc',
          hash: 10,
          name: 'Austringer',
          slot: EquipmentSlot.primary,
          type: 'Hand Cannon',
          element: 'Kinetic',
        ),
        gun(
          id: 'solar-pulse',
          hash: 11,
          name: 'BxR-55',
          slot: EquipmentSlot.special,
          type: 'Pulse Rifle',
          element: 'Solar',
        ),
      ];

      final suggestion = suggestSimilarWeapon(
        need: needSunshot,
        heldWeapons: held,
      );
      expect(suggestion, isNotNull);
      expect(suggestion!.tier, FillInSimilarWeaponTier.slotDamage);
      expect(suggestion.item.name, 'BxR-55');
    });

    test('ignores wrong slot even when type and damage match', () {
      final held = [
        gun(
          id: 'kinetic-hc',
          hash: 20,
          name: 'Igneous Hammer',
          slot: EquipmentSlot.primary,
          type: 'Hand Cannon',
          element: 'Solar',
        ),
      ];
      expect(
        suggestSimilarWeapon(need: needSunshot, heldWeapons: held),
        isNull,
      );
    });

    test('tie-break within tier is lower hash then instance id', () {
      final held = [
        gun(
          id: 'b',
          hash: 200,
          name: 'Later',
          slot: EquipmentSlot.special,
          type: 'Hand Cannon',
          element: 'Solar',
        ),
        gun(
          id: 'a',
          hash: 100,
          name: 'Earlier',
          slot: EquipmentSlot.special,
          type: 'Hand Cannon',
          element: 'Solar',
        ),
      ];
      final suggestion = suggestSimilarWeapon(
        need: needSunshot,
        heldWeapons: held,
      );
      expect(suggestion!.item.name, 'Earlier');
      expect(suggestion.item.itemHash, 100);
    });

    test('returns null when need type or damage is blank', () {
      expect(
        suggestSimilarWeapon(
          need: const FillInWeaponNeed(
            slot: EquipmentSlot.special,
            damageType: '',
            weaponType: 'Hand Cannon',
          ),
          heldWeapons: const [],
        ),
        isNull,
      );
    });

    test('comparison is case-insensitive for type and damage', () {
      final held = [
        gun(
          id: '1',
          hash: 1,
          name: 'Match',
          slot: EquipmentSlot.special,
          type: 'hand cannon',
          element: 'SOLAR',
        ),
      ];
      final suggestion = suggestSimilarWeapon(
        need: const FillInWeaponNeed(
          slot: EquipmentSlot.special,
          damageType: 'solar',
          weaponType: 'HAND CANNON',
        ),
        heldWeapons: held,
      );
      expect(suggestion!.item.name, 'Match');
      expect(suggestion.tier, FillInSimilarWeaponTier.slotDamageType);
    });
  });
}
