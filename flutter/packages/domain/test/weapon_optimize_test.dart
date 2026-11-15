import 'dart:math';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('optimizeWeapons hard filters', () {
    test('same slot bucket only', () {
      final inv = [
        _w('k1', 1, EquipmentSlot.primary, 'Scout Rifle', 'Solar'),
        _w('e1', 2, EquipmentSlot.special, 'Fusion Rifle', 'Solar'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: inv,
          subclassKey: 'Solar',
        ),
      );
      expect(res.combinations, isNotEmpty);
      final pick = res.combinations.first.picks.single;
      expect(pick.item.instanceId, 'k1');
      expect(pick.slot, EquipmentSlot.primary);
    });

    test('never the exotic weapon type', () {
      final inv = [
        _w('hc1', 10, EquipmentSlot.primary, 'Hand Cannon', 'Kinetic'),
        _w('scout1', 11, EquipmentSlot.primary, 'Scout Rifle', 'Kinetic'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: inv,
          subclassKey: 'prismatic',
          exoticWeaponType: 'Hand Cannon',
        ),
      );
      expect(res.combinations.single.picks.single.item.instanceId, 'scout1');
    });

    test('opposite range scores higher than same range', () {
      // Exotic is short (Shotgun) → prefer long (Scout) over short (Sidearm).
      final inv = [
        _w('side', 20, EquipmentSlot.special, 'Sidearm', 'Arc'),
        _w('scout', 21, EquipmentSlot.special, 'Scout Rifle', 'Arc'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.special],
          inventory: inv,
          subclassKey: 'Arc',
          exoticWeaponType: 'Shotgun',
        ),
      );
      expect(res.combinations.first.picks.single.item.instanceId, 'scout');
      expect(
        res.combinations.first.picks.single.score,
        greaterThanOrEqualTo(kWeaponOptimizeOppositeRangePoints),
      );
    });

    test('one-exotic cap applied after ranking with build exotic count', () {
      final inv = [
        _w(
          'ex1',
          30,
          EquipmentSlot.primary,
          'Scout Rifle',
          'Solar',
          exotic: true,
        ),
        _w('leg1', 31, EquipmentSlot.primary, 'Auto Rifle', 'Solar'),
        _w(
          'ex2',
          32,
          EquipmentSlot.special,
          'Fusion Rifle',
          'Solar',
          exotic: true,
        ),
        _w('leg2', 33, EquipmentSlot.special, 'Sidearm', 'Solar'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary, EquipmentSlot.special],
          inventory: inv,
          subclassKey: 'Solar',
          exoticsAlreadyOnBuild: 1,
        ),
      );
      final picks = res.combinations.first.picks;
      expect(picks.every((p) => !p.item.isExotic), isTrue);
    });
  });

  group('optimizeWeapons element + perk', () {
    test('element match applies to all three slots; Prismatic matches any', () {
      final inv = [
        _w('k-solar', 1, EquipmentSlot.primary, 'Scout Rifle', 'Solar'),
        _w('k-arc', 2, EquipmentSlot.primary, 'Auto Rifle', 'Arc'),
        _w('e-solar', 3, EquipmentSlot.special, 'Fusion Rifle', 'Solar'),
        _w('p-solar', 4, EquipmentSlot.heavy, 'Rocket Launcher', 'Solar'),
      ];
      final solar = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: EquipmentSlot.weaponSlots,
          inventory: inv,
          subclassKey: 'Solar',
        ),
      );
      for (final p in solar.combinations.first.picks) {
        expect(p.item.damageType, 'Solar');
        expect(p.elementMismatch, isFalse);
      }

      final prism = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: [
            _w('k-arc', 2, EquipmentSlot.primary, 'Auto Rifle', 'Arc'),
          ],
          subclassKey: 'Prismatic',
        ),
      );
      expect(prism.combinations.first.picks.single.elementMismatch, isFalse);
    });

    test('element mismatch fallback never leaves slot blank', () {
      final inv = [
        _w('only-arc', 5, EquipmentSlot.primary, 'Scout Rifle', 'Arc'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: inv,
          subclassKey: 'Solar',
        ),
      );
      final pick = res.combinations.single.picks.single;
      expect(pick.item.instanceId, 'only-arc');
      expect(pick.elementMismatch, isTrue);
      expect(pick.note, kWeaponOptimizeElementMismatchNote);
    });

    test('perk synergy tags boost score from offline CSV tags', () {
      final inv = [
        _w(
          'plain',
          40,
          EquipmentSlot.primary,
          'Scout Rifle',
          'Void',
        ),
        _w(
          'syn',
          41,
          EquipmentSlot.primary,
          'Scout Rifle',
          'Void',
          perks: const ['Volatile Rounds', 'Repulsor Brace'],
        ),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: inv,
          subclassKey: 'Void',
          buildKeywords: const ['volatile', 'repulsor'],
        ),
      );
      expect(res.combinations.first.picks.single.item.instanceId, 'syn');
      expect(
        res.combinations.first.picks.single.score,
        greaterThanOrEqualTo(2 * kWeaponOptimizePerkSynergyPoints),
      );
    });
  });

  group('optimizeWeapons substitute fallback', () {
    test('no CSV → substitute label, reason, never optimized', () {
      final inv = [
        _w('k1', 1, EquipmentSlot.primary, 'Scout Rifle', 'Kinetic'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: inv,
          subclassKey: 'prismatic',
          hasWeaponsCsv: false,
          random: Random(7),
        ),
      );
      expect(res.combinations, hasLength(1));
      final combo = res.combinations.single;
      expect(combo.isSubstitute, isTrue);
      expect(combo.isOptimized, isFalse);
      expect(combo.source, WeaponOptimizeSource.substitute);
      expect(combo.reason, kWeaponOptimizeNoCsvReason);
      expect(combo.picks.single.sourceLabel, kWeaponOptimizeSubstituteLabel);
      expect(combo.picks.single.sourceLabel, isNot(kWeaponOptimizeOptimizedLabel));
    });
  });

  group('optimizeWeapons pin / stale', () {
    test('pinned instance ids are never re-picked', () {
      final inv = [
        _w('pinned', 1, EquipmentSlot.primary, 'Scout Rifle', 'Kinetic'),
        _w('free', 2, EquipmentSlot.primary, 'Auto Rifle', 'Kinetic'),
      ];
      final res = optimizeWeapons(
        WeaponOptimizeRequest(
          emptySlots: const [EquipmentSlot.primary],
          inventory: inv,
          subclassKey: 'prismatic',
          pinnedInstanceIds: const {'pinned'},
        ),
      );
      expect(res.combinations.single.picks.single.item.instanceId, 'free');
    });
  });
}

FillInInventoryItem _w(
  String id,
  int hash,
  EquipmentSlot slot,
  String type,
  String element, {
  bool exotic = false,
  List<String> perks = const [],
}) {
  return FillInInventoryItem(
    instanceId: id,
    itemHash: hash,
    name: 'Weapon $id',
    slot: slot,
    isExotic: exotic,
    weaponType: type,
    damageType: element,
    perkTags: perks,
  );
}
