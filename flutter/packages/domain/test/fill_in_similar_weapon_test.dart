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

    test('returns null when need blank and inventory empty', () {
      expect(
        suggestSimilarWeapon(
          need: const FillInWeaponNeed(
            slot: EquipmentSlot.special,
            damageType: '',
            weaponType: '',
          ),
          heldWeapons: const [],
        ),
        isNull,
      );
    });

    test('slot-only pick when need has no damage/type profile', () {
      final held = [
        gun(
          id: 'any',
          hash: 5,
          name: 'Funnelweb',
          slot: EquipmentSlot.special,
          type: 'Submachine Gun',
          element: 'Void',
        ),
      ];
      final suggestion = suggestSimilarWeapon(
        need: const FillInWeaponNeed(
          slot: EquipmentSlot.special,
          damageType: '',
          weaponType: '',
        ),
        heldWeapons: held,
      );
      expect(suggestion, isNotNull);
      expect(suggestion!.tier, FillInSimilarWeaponTier.slotOnly);
      expect(suggestion.item.name, 'Funnelweb');
    });

    test('excludeExotic skips exotic candidates', () {
      final held = [
        gun(
          id: 'ex',
          hash: 1,
          name: 'Riskrunner',
          slot: EquipmentSlot.special,
          type: 'Submachine Gun',
          element: 'Arc',
          exotic: true,
        ),
        gun(
          id: 'leg',
          hash: 2,
          name: 'Funnelweb',
          slot: EquipmentSlot.special,
          type: 'Submachine Gun',
          element: 'Void',
        ),
      ];
      final suggestion = suggestSimilarWeapon(
        need: const FillInWeaponNeed(
          slot: EquipmentSlot.special,
          damageType: '',
          weaponType: '',
        ),
        heldWeapons: held,
        excludeExotic: true,
      );
      expect(suggestion!.item.name, 'Funnelweb');
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

  group('fillInWeaponRangeClass', () {
    test('maps short and long DIM types via the explicit table', () {
      expect(fillInWeaponRangeClass('Shotgun'), FillInWeaponRangeClass.short);
      expect(
        fillInWeaponRangeClass('Submachine Gun'),
        FillInWeaponRangeClass.short,
      );
      expect(fillInWeaponRangeClass('Sidearm'), FillInWeaponRangeClass.short);
      expect(
        fillInWeaponRangeClass('Fusion Rifle'),
        FillInWeaponRangeClass.short,
      );
      expect(fillInWeaponRangeClass('Sword'), FillInWeaponRangeClass.short);
      expect(fillInWeaponRangeClass('Glaive'), FillInWeaponRangeClass.short);
      expect(
        fillInWeaponRangeClass('Trace Rifle'),
        FillInWeaponRangeClass.short,
      );
      expect(
        fillInWeaponRangeClass('Grenade Launcher'),
        FillInWeaponRangeClass.short,
      );
      expect(
        fillInWeaponRangeClass('Scout Rifle'),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInWeaponRangeClass('Pulse Rifle'),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInWeaponRangeClass('Hand Cannon'),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInWeaponRangeClass('Auto Rifle'),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInWeaponRangeClass('Sniper Rifle'),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInWeaponRangeClass('Linear Fusion Rifle'),
        FillInWeaponRangeClass.long,
      );
      expect(fillInWeaponRangeClass('Bow'), FillInWeaponRangeClass.long);
      expect(
        fillInWeaponRangeClass('Rocket Launcher'),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInWeaponRangeClass('Machine Gun'),
        FillInWeaponRangeClass.long,
      );
      expect(fillInWeaponRangeClass('Mystery'), FillInWeaponRangeClass.unknown);
      expect(fillInWeaponRangeClass(null), FillInWeaponRangeClass.unknown);
    });

    test('opposite range flips short↔long and leaves unknown null', () {
      expect(
        fillInOppositeWeaponRange(FillInWeaponRangeClass.short),
        FillInWeaponRangeClass.long,
      );
      expect(
        fillInOppositeWeaponRange(FillInWeaponRangeClass.long),
        FillInWeaponRangeClass.short,
      );
      expect(
        fillInOppositeWeaponRange(FillInWeaponRangeClass.unknown),
        isNull,
      );
    });

    test('subclass damage map: elements vs Prismatic/unknown', () {
      expect(fillInDamageTypeForSubclass('solar'), 'Solar');
      expect(fillInDamageTypeForSubclass('Arc'), 'Arc');
      expect(fillInDamageTypeForSubclass('void'), 'Void');
      expect(fillInDamageTypeForSubclass('stasis'), 'Stasis');
      expect(fillInDamageTypeForSubclass('strand'), 'Strand');
      expect(fillInDamageTypeForSubclass('prismatic'), isNull);
      expect(fillInDamageTypeForSubclass(''), isNull);
      expect(fillInDamageTypeForSubclass('unknown'), isNull);
    });
  });
}
