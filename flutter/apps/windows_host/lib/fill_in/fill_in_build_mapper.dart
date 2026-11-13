import 'package:destiny2_domain/destiny2_domain.dart';

import '../builds_mock/builds_mock_models.dart';

/// Maps a [MockBuild] + held inventory into a [FillInBuildRequirement] and an
/// inventory list stamped with synthetic set hashes so [matchFillIn] can score
/// legendary pieces by name when Settings did not supply a set-hash map.
class FillInMappedBuild {
  const FillInMappedBuild({
    required this.requirement,
    required this.inventory,
  });

  final FillInBuildRequirement requirement;
  final List<FillInInventoryItem> inventory;
}

/// Build-data (+ optional inventory) profile for similar-weapon suggestion.
FillInWeaponNeed? fillInWeaponNeedForBuild({
  required MockBuild build,
  required List<FillInInventoryItem> inventory,
}) {
  final name = build.exoticWeapon.trim();
  if (name.isEmpty) return null;

  // Prefer attributes from a held CSV row with the same name (exact).
  for (final item in inventory) {
    if (!item.isExotic) continue;
    if (!_isWeaponSlot(item.slot)) continue;
    if ((item.name ?? '').trim().toLowerCase() != name.toLowerCase()) continue;
    final type = item.weaponType?.trim() ?? '';
    final damage = item.damageType?.trim() ?? '';
    if (type.isEmpty || damage.isEmpty) break;
    return FillInWeaponNeed(
      name: name,
      slot: item.slot,
      weaponType: type,
      damageType: damage,
    );
  }

  final type = build.exoticWeaponType?.trim() ?? '';
  final damage = build.exoticWeaponDamageType?.trim() ?? '';
  final slotWire = build.exoticWeaponSlot?.trim() ?? '';
  if (type.isEmpty || damage.isEmpty || slotWire.isEmpty) return null;
  final slot = EquipmentSlot.tryParse(slotWire);
  if (slot == null || !_isWeaponSlot(slot)) return null;
  return FillInWeaponNeed(
    name: name,
    slot: slot,
    weaponType: type,
    damageType: damage,
  );
}

/// Resolve exotic armor/weapons by display name and stamp legendary set hashes
/// from the mock build's slot assignments.
FillInMappedBuild mapMockBuildForFillIn({
  required MockBuild build,
  required List<FillInInventoryItem> inventory,
  GuardianClass guardianClass = GuardianClass.warlock,
}) {
  final subclassKey = build.subclass.trim().toLowerCase();
  final exoticArmorName = build.exoticArmor.trim().isEmpty
      ? null
      : build.exoticArmor.trim();

  final setHashBySetId = <String, int>{};
  final stampedById = <String, FillInInventoryItem>{
    for (final item in inventory) item.instanceId: item,
  };

  final slots = <FillInSlotRequirement>[];

  if (build.slots.isEmpty) {
    _addExoticArmorNeed(
      slots: slots,
      inventory: inventory,
      guardianClass: guardianClass,
      exoticName: exoticArmorName,
    );
    _addExoticWeaponNeed(
      slots: slots,
      inventory: inventory,
      exoticWeaponName: build.exoticWeapon,
    );
  } else {
    final twoPlusTwo = _twoPlusTwoSetIds(build.slots);
    if (twoPlusTwo != null) {
      final firstHash = setHashBySetId.putIfAbsent(
        twoPlusTwo.$1,
        () => _stableSetHash(twoPlusTwo.$1),
      );
      final secondHash = setHashBySetId.putIfAbsent(
        twoPlusTwo.$2,
        () => _stableSetHash(twoPlusTwo.$2),
      );
      _stampLegendarySetsForTwoPlusTwo(
        build: build,
        stampedById: stampedById,
        guardianClass: guardianClass,
        setHashBySetId: <String, int>{
          twoPlusTwo.$1: firstHash,
          twoPlusTwo.$2: secondHash,
        },
      );
      slots.addAll(
        assignFillInTwoPlusTwoSlots(
          firstSetHash: firstHash,
          secondSetHash: secondHash,
          guardianClass: guardianClass,
          inventory: stampedById.values,
        ),
      );
      for (final assignment in build.slots) {
        if (!assignment.isExoticSlot) continue;
        final slot = _slotFromWire(assignment.slot);
        if (slot == null) continue;
        final hash = _exoticArmorHash(
          inventory: inventory,
          guardianClass: guardianClass,
          name: assignment.pieceName,
        );
        slots.add(
          FillInSlotRequirement(
            slot: slot,
            isExotic: true,
            exoticItemHash: hash,
          ),
        );
      }
    } else {
      for (final assignment in build.slots) {
        final slot = _slotFromWire(assignment.slot);
        if (slot == null) continue;
        if (assignment.isExoticSlot) {
          final hash = _exoticArmorHash(
            inventory: inventory,
            guardianClass: guardianClass,
            name: assignment.pieceName,
          );
          slots.add(
            FillInSlotRequirement(
              slot: slot,
              isExotic: true,
              exoticItemHash: hash,
            ),
          );
        } else {
          final setHash = setHashBySetId.putIfAbsent(
            assignment.setId,
            () => _stableSetHash(assignment.setId),
          );
          _stampLegendaryByName(
            stampedById: stampedById,
            guardianClass: guardianClass,
            slot: slot,
            pieceName: assignment.pieceName,
            setHash: setHash,
          );
          slots.add(
            FillInSlotRequirement(
              slot: slot,
              isExotic: false,
              armorSetHash: setHash,
            ),
          );
        }
      }
    }
    _addExoticWeaponNeed(
      slots: slots,
      inventory: inventory,
      exoticWeaponName: build.exoticWeapon,
    );
  }

  return FillInMappedBuild(
    requirement: FillInBuildRequirement(
      buildId: build.id,
      guardianClass: guardianClass,
      subclassKey: subclassKey,
      exoticArmorName: exoticArmorName,
      slots: slots,
    ),
    inventory: List<FillInInventoryItem>.unmodifiable(stampedById.values),
  );
}

void _addExoticArmorNeed({
  required List<FillInSlotRequirement> slots,
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required String? exoticName,
}) {
  if (exoticName == null || exoticName.isEmpty) return;
  final match = _findExoticArmor(
    inventory: inventory,
    guardianClass: guardianClass,
    name: exoticName,
  );
  slots.add(
    FillInSlotRequirement(
      slot: match?.slot ?? EquipmentSlot.classItem,
      isExotic: true,
      exoticItemHash: match?.itemHash,
    ),
  );
}

void _addExoticWeaponNeed({
  required List<FillInSlotRequirement> slots,
  required List<FillInInventoryItem> inventory,
  required String exoticWeaponName,
}) {
  final name = exoticWeaponName.trim();
  if (name.isEmpty) return;
  final match = _findExoticWeapon(inventory: inventory, name: name);
  slots.add(
    FillInSlotRequirement(
      slot: match?.slot ?? EquipmentSlot.special,
      isExotic: true,
      exoticItemHash: match?.itemHash,
    ),
  );
}

void _stampLegendaryByName({
  required Map<String, FillInInventoryItem> stampedById,
  required GuardianClass guardianClass,
  required EquipmentSlot slot,
  required String pieceName,
  required int setHash,
}) {
  final want = pieceName.trim().toLowerCase();
  if (want.isEmpty) return;
  for (final entry in stampedById.entries.toList()) {
    final item = entry.value;
    if (item.isExotic) continue;
    if (item.guardianClass != guardianClass) continue;
    if (item.slot != slot) continue;
    final itemName = item.name?.trim().toLowerCase() ?? '';
    if (itemName != want) continue;
    stampedById[entry.key] = item.copyWith(armorSetHash: setHash);
  }
}

/// Detect ordered (firstSetId, secondSetId) for a 2+2 legendary layout.
(String, String)? _twoPlusTwoSetIds(List<MockSlotAssignment> slots) {
  final legendary = [
    for (final s in slots)
      if (!s.isExoticSlot) s,
  ];
  final order = <String>[];
  final counts = <String, int>{};
  for (final s in legendary) {
    counts[s.setId] = (counts[s.setId] ?? 0) + 1;
    if (!order.contains(s.setId)) order.add(s.setId);
  }
  if (order.length != 2) return null;
  if (counts[order[0]] != 2 || counts[order[1]] != 2) return null;
  return (order[0], order[1]);
}

/// Stamp legendary inventory for both 2+2 sets across helmet/arms/chest/legs
/// so the walk can see holds in slots the build had assigned to the other set.
void _stampLegendarySetsForTwoPlusTwo({
  required MockBuild build,
  required Map<String, FillInInventoryItem> stampedById,
  required GuardianClass guardianClass,
  required Map<String, int> setHashBySetId,
}) {
  final prefixes = <String, String>{};
  for (final assignment in build.slots) {
    if (assignment.isExoticSlot) continue;
    final setHash = setHashBySetId[assignment.setId];
    if (setHash == null) continue;
    final prefix = prefixes.putIfAbsent(
      assignment.setId,
      () => _pieceNamePrefix(assignment.pieceName),
    );
    if (prefix.isEmpty) {
      _stampLegendaryByName(
        stampedById: stampedById,
        guardianClass: guardianClass,
        slot: _slotFromWire(assignment.slot) ?? EquipmentSlot.helmet,
        pieceName: assignment.pieceName,
        setHash: setHash,
      );
      continue;
    }
    for (final entry in stampedById.entries.toList()) {
      final item = entry.value;
      if (item.isExotic) continue;
      if (item.guardianClass != guardianClass) continue;
      if (!kFillInTwoPlusTwoSlotOrder.contains(item.slot)) continue;
      final itemName = item.name?.trim().toLowerCase() ?? '';
      if (!itemName.startsWith(prefix)) continue;
      stampedById[entry.key] = item.copyWith(armorSetHash: setHash);
    }
  }
}

String _pieceNamePrefix(String pieceName) {
  final trimmed = pieceName.trim().toLowerCase();
  if (trimmed.isEmpty) return '';
  final space = trimmed.indexOf(' ');
  if (space <= 0) return trimmed;
  return trimmed.substring(0, space);
}

FillInInventoryItem? _findExoticArmor({
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required String name,
}) {
  final want = name.trim().toLowerCase();
  for (final item in inventory) {
    if (!item.isExotic) continue;
    if (item.guardianClass != guardianClass) continue;
    if (!EquipmentSlot.armorSlots.contains(item.slot)) continue;
    if ((item.name ?? '').trim().toLowerCase() == want) return item;
  }
  return null;
}

int? _exoticArmorHash({
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required String name,
}) {
  return _findExoticArmor(
    inventory: inventory,
    guardianClass: guardianClass,
    name: name,
  )?.itemHash;
}

FillInInventoryItem? _findExoticWeapon({
  required List<FillInInventoryItem> inventory,
  required String name,
}) {
  final want = name.trim().toLowerCase();
  for (final item in inventory) {
    if (!item.isExotic) continue;
    if (!_isWeaponSlot(item.slot)) continue;
    if ((item.name ?? '').trim().toLowerCase() == want) return item;
  }
  return null;
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

EquipmentSlot? _slotFromWire(String wire) {
  switch (wire) {
    case 'helmet':
      return EquipmentSlot.helmet;
    case 'arms':
      return EquipmentSlot.arms;
    case 'chest':
      return EquipmentSlot.chest;
    case 'legs':
      return EquipmentSlot.legs;
    case 'class_item':
      return EquipmentSlot.classItem;
    default:
      return EquipmentSlot.tryParse(wire);
  }
}

int _stableSetHash(String setId) {
  // Positive 31-bit hash so it stays a valid synthetic set key.
  return setId.hashCode & 0x7fffffff;
}
