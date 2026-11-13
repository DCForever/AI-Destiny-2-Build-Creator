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

/// Combat slots Fill In always covers (5 armor + 3 weapons).
const List<EquipmentSlot> kFillInTotalArmorSlots = EquipmentSlot.armorSlots;
const List<EquipmentSlot> kFillInTotalWeaponSlots = EquipmentSlot.weaponSlots;

/// Overlay compiled DIM loadout exotic + items onto a matrix/mock build.
///
/// Matrix rows that only name an exotic **weapon** leave [MockBuild.exoticArmor]
/// empty even when the matched DIM link lists exotic armor (e.g. Swarmers).
/// This keeps display + Fill In aligned with the details panel EXOTIC line.
MockBuild enrichMockBuildFromDimLoadout(
  MockBuild build, {
  CachedDimLoadout? loadout,
}) {
  if (loadout == null) return build;

  final pieces = extractFillInPiecesFromDimLoadout(loadout);
  var exoticArmor = build.exoticArmor.trim();
  if (exoticArmor.isEmpty && pieces.exoticArmorName != null) {
    exoticArmor = pieces.exoticArmorName!;
  }

  var exoticWeapon = build.exoticWeapon.trim();
  var exoticWeaponSlot = build.exoticWeaponSlot;
  final slots = <MockSlotAssignment>[...build.slots];

  if (slots.isEmpty) {
    for (final entry in pieces.armorBySlot.entries) {
      final piece = entry.value;
      slots.add(
        MockSlotAssignment(
          slot: piece.slot.wireName,
          setId: piece.isExotic ? 'exotic' : 'dim_${piece.hash}',
          pieceName: piece.name,
          isExoticSlot: piece.isExotic,
        ),
      );
    }
    for (final entry in pieces.weaponsBySlot.entries) {
      final piece = entry.value;
      slots.add(
        MockSlotAssignment(
          slot: piece.slot.wireName,
          setId: piece.isExotic ? 'exotic_weapon' : 'dim_weapon_${piece.hash}',
          pieceName: piece.name,
          isExoticSlot: piece.isExotic,
        ),
      );
      if (piece.isExotic) {
        if (exoticWeapon.isEmpty) exoticWeapon = piece.name;
        final slotWire = exoticWeaponSlot?.trim() ?? '';
        if (slotWire.isEmpty &&
            exoticWeapon.toLowerCase() == piece.name.toLowerCase()) {
          exoticWeaponSlot = piece.slot.wireName;
        }
      }
    }
  } else {
    // Fill gaps only — never overwrite an existing assignment.
    for (final entry in pieces.armorBySlot.entries) {
      final wire = entry.value.slot.wireName;
      if (slots.any((s) => s.slot == wire)) continue;
      slots.add(
        MockSlotAssignment(
          slot: wire,
          setId: entry.value.isExotic ? 'exotic' : 'dim_${entry.value.hash}',
          pieceName: entry.value.name,
          isExoticSlot: entry.value.isExotic,
        ),
      );
    }
    for (final entry in pieces.weaponsBySlot.entries) {
      final piece = entry.value;
      final wire = piece.slot.wireName;
      if (slots.any((s) => s.slot == wire)) continue;
      slots.add(
        MockSlotAssignment(
          slot: wire,
          setId: piece.isExotic
              ? 'exotic_weapon'
              : 'dim_weapon_${piece.hash}',
          pieceName: piece.name,
          isExoticSlot: piece.isExotic,
        ),
      );
      if (piece.isExotic) {
        if (exoticWeapon.isEmpty) exoticWeapon = piece.name;
        final slotWire = exoticWeaponSlot?.trim() ?? '';
        if (slotWire.isEmpty &&
            exoticWeapon.toLowerCase() == piece.name.toLowerCase()) {
          exoticWeaponSlot = piece.slot.wireName;
        }
      }
    }
  }

  return build.copyWith(
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    exoticWeaponSlot: exoticWeaponSlot,
    slots: List<MockSlotAssignment>.unmodifiable(slots),
  );
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
///
/// Always emits needs for all 5 armor + 3 weapon combat slots (total fill).
FillInMappedBuild mapMockBuildForFillIn({
  required MockBuild build,
  required List<FillInInventoryItem> inventory,
  GuardianClass guardianClass = GuardianClass.warlock,
  CachedDimLoadout? dimLoadout,
}) {
  final enriched = enrichMockBuildFromDimLoadout(build, loadout: dimLoadout);
  final subclassKey = enriched.subclass.trim().toLowerCase();
  final exoticArmorName = enriched.exoticArmor.trim().isEmpty
      ? null
      : enriched.exoticArmor.trim();
  final dimPieces =
      dimLoadout == null ? null : extractFillInPiecesFromDimLoadout(dimLoadout);
  final preferredExoticArmorSlot = dimPieces?.exoticArmorSlot;
  final preferredExoticArmorHash = dimPieces?.exoticArmorHash;

  final setHashBySetId = <String, int>{};
  final stampedById = <String, FillInInventoryItem>{
    for (final item in inventory) item.instanceId: item,
  };

  final slots = <FillInSlotRequirement>[];
  final covered = <EquipmentSlot>{};

  if (enriched.slots.isEmpty) {
    _ensureNamedExoticArmorNeed(
      slots: slots,
      covered: covered,
      inventory: inventory,
      guardianClass: guardianClass,
      exoticName: exoticArmorName,
      preferredSlot: preferredExoticArmorSlot,
      preferredHash: preferredExoticArmorHash,
    );
    _addExoticWeaponNeed(
      slots: slots,
      inventory: inventory,
      exoticWeaponName: enriched.exoticWeapon,
      preferredSlot: enriched.exoticWeaponSlot,
      covered: covered,
    );
  } else {
    final twoPlusTwo = _twoPlusTwoSetIds(enriched.slots);
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
        build: enriched,
        stampedById: stampedById,
        guardianClass: guardianClass,
        setHashBySetId: <String, int>{
          twoPlusTwo.$1: firstHash,
          twoPlusTwo.$2: secondHash,
        },
      );
      for (final need in assignFillInTwoPlusTwoSlots(
        firstSetHash: firstHash,
        secondSetHash: secondHash,
        guardianClass: guardianClass,
        inventory: stampedById.values,
      )) {
        slots.add(need);
        covered.add(need.slot);
      }
      for (final assignment in enriched.slots) {
        final slot = _slotFromWire(assignment.slot);
        if (slot == null) continue;
        if (_isWeaponSlot(slot)) {
          if (covered.contains(slot)) continue;
          final hash = _weaponHash(
            inventory: inventory,
            name: assignment.pieceName,
          );
          slots.add(
            FillInSlotRequirement(
              slot: slot,
              isExotic: assignment.isExoticSlot,
              exoticItemHash: hash,
            ),
          );
          covered.add(slot);
          continue;
        }
        if (!assignment.isExoticSlot) continue;
        if (!EquipmentSlot.armorSlots.contains(slot)) continue;
        final hash = _exoticArmorHash(
              inventory: inventory,
              guardianClass: guardianClass,
              name: assignment.pieceName,
            ) ??
            preferredExoticArmorHash;
        slots.add(
          FillInSlotRequirement(
            slot: slot,
            isExotic: true,
            exoticItemHash: hash,
          ),
        );
        covered.add(slot);
      }
    } else {
      for (final assignment in enriched.slots) {
        final slot = _slotFromWire(assignment.slot);
        if (slot == null) continue;
        if (_isWeaponSlot(slot)) {
          final hash = _weaponHash(
            inventory: inventory,
            name: assignment.pieceName,
          );
          slots.add(
            FillInSlotRequirement(
              slot: slot,
              isExotic: assignment.isExoticSlot,
              exoticItemHash: hash,
            ),
          );
          covered.add(slot);
          continue;
        }
        if (!EquipmentSlot.armorSlots.contains(slot)) continue;
        if (assignment.isExoticSlot) {
          final hash = _exoticArmorHash(
                inventory: inventory,
                guardianClass: guardianClass,
                name: assignment.pieceName,
              ) ??
              preferredExoticArmorHash;
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
        covered.add(slot);
      }
    }
    _ensureNamedExoticArmorNeed(
      slots: slots,
      covered: covered,
      inventory: inventory,
      guardianClass: guardianClass,
      exoticName: exoticArmorName,
      preferredSlot: preferredExoticArmorSlot,
      preferredHash: preferredExoticArmorHash,
    );
    _addExoticWeaponNeed(
      slots: slots,
      inventory: inventory,
      exoticWeaponName: enriched.exoticWeapon,
      preferredSlot: enriched.exoticWeaponSlot,
      covered: covered,
    );
  }

  _ensureTotalFillSlots(
    slots: slots,
    covered: covered,
  );

  return FillInMappedBuild(
    requirement: FillInBuildRequirement(
      buildId: enriched.id,
      guardianClass: guardianClass,
      subclassKey: subclassKey,
      exoticArmorName: exoticArmorName,
      slots: List<FillInSlotRequirement>.unmodifiable(slots),
    ),
    inventory: List<FillInInventoryItem>.unmodifiable(stampedById.values),
  );
}

/// Pad to all 5 armor + 3 weapon combat slots so Fill In is always a total fill.
///
/// Named exotic armor is handled by [_ensureNamedExoticArmorNeed] — never invent
/// a class_item exotic here, and never treat a legendary pad as covering it.
void _ensureTotalFillSlots({
  required List<FillInSlotRequirement> slots,
  required Set<EquipmentSlot> covered,
}) {
  for (final slot in kFillInTotalArmorSlots) {
    if (covered.contains(slot)) continue;
    slots.add(
      FillInSlotRequirement(
        slot: slot,
        isExotic: false,
      ),
    );
    covered.add(slot);
  }

  for (final slot in kFillInTotalWeaponSlots) {
    if (covered.contains(slot)) continue;
    slots.add(
      FillInSlotRequirement(
        slot: slot,
        isExotic: false,
      ),
    );
    covered.add(slot);
  }
}

bool _slotsContainExoticArmor(List<FillInSlotRequirement> slots) {
  for (final s in slots) {
    if (!s.isExotic) continue;
    if (EquipmentSlot.armorSlots.contains(s.slot)) return true;
    if (s.slot == EquipmentSlot.exoticArmor) return true;
  }
  return false;
}

/// Always keep a named exotic armor need visible.
///
/// - Known bucket (inventory or DIM item row) → that combat slot.
/// - Summary-only / unknown slot → [EquipmentSlot.exoticArmor] (never class_item).
/// - Unowned still emits a missing exotic need (hash from DIM when available).
void _ensureNamedExoticArmorNeed({
  required List<FillInSlotRequirement> slots,
  required Set<EquipmentSlot> covered,
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required String? exoticName,
  EquipmentSlot? preferredSlot,
  int? preferredHash,
}) {
  if (exoticName == null || exoticName.isEmpty) return;
  if (_slotsContainExoticArmor(slots)) {
    // Upgrade a null hash from DIM when the exotic row already exists.
    if (preferredHash == null) return;
    for (var i = 0; i < slots.length; i++) {
      final need = slots[i];
      if (!need.isExotic) continue;
      if (!EquipmentSlot.armorSlots.contains(need.slot) &&
          need.slot != EquipmentSlot.exoticArmor) {
        continue;
      }
      if (need.exoticItemHash != null) return;
      slots[i] = FillInSlotRequirement(
        slot: need.slot,
        isExotic: true,
        exoticItemHash: preferredHash,
      );
      return;
    }
    return;
  }

  final match = _findExoticArmor(
    inventory: inventory,
    guardianClass: guardianClass,
    name: exoticName,
  );
  final preferred =
      preferredSlot != null && EquipmentSlot.armorSlots.contains(preferredSlot)
          ? preferredSlot
          : null;
  // Known bucket when possible; otherwise exoticArmor — never invent class_item.
  final slot = match?.slot ?? preferred ?? EquipmentSlot.exoticArmor;
  if (covered.contains(slot) && slot != EquipmentSlot.exoticArmor) {
    // Combat slot already has a legendary need — replace with exotic need.
    slots.removeWhere((s) => s.slot == slot);
    covered.remove(slot);
  }
  if (covered.contains(slot)) return;
  slots.add(
    FillInSlotRequirement(
      slot: slot,
      isExotic: true,
      exoticItemHash: match?.itemHash ?? preferredHash,
    ),
  );
  covered.add(slot);
}

void _addExoticWeaponNeed({
  required List<FillInSlotRequirement> slots,
  required List<FillInInventoryItem> inventory,
  required String exoticWeaponName,
  String? preferredSlot,
  required Set<EquipmentSlot> covered,
}) {
  final name = exoticWeaponName.trim();
  if (name.isEmpty) return;
  final match = _findExoticWeapon(inventory: inventory, name: name);
  final preferred = preferredSlot == null
      ? null
      : EquipmentSlot.tryParse(preferredSlot);
  final EquipmentSlot? slot = match?.slot ??
      (preferred != null && _isWeaponSlot(preferred) ? preferred : null);
  // No known combat bucket — leave the row to total-fill padding (not Energy).
  if (slot == null) return;
  if (covered.contains(slot)) return;
  slots.add(
    FillInSlotRequirement(
      slot: slot,
      isExotic: true,
      exoticItemHash: match?.itemHash,
    ),
  );
  covered.add(slot);
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
      if (!s.isExoticSlot && EquipmentSlot.armorSlots.contains(
            _slotFromWire(s.slot) ?? EquipmentSlot.helmet,
          ))
        s,
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

int? _weaponHash({
  required List<FillInInventoryItem> inventory,
  required String name,
}) {
  final want = name.trim().toLowerCase();
  for (final item in inventory) {
    if (!_isWeaponSlot(item.slot)) continue;
    if ((item.name ?? '').trim().toLowerCase() == want) return item.itemHash;
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
