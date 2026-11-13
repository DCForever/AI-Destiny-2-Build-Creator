import '../models/equipment.dart';
import '../warlock_matrix/solipsism_flag.dart';
import 'fill_in_cap.dart';
import 'fill_in_inventory.dart';
import 'fill_in_requirement.dart';
import 'fill_in_result.dart';

/// Match build armor/weapon needs against a held inventory snapshot.
///
/// Read-only: never mutates Bungie inventory or local store state.
/// Builds share the same physical copies (no exclusive reservation).
/// Each [FillInInventoryItem.instanceId] counts toward at most one pool cell.
///
/// Matching rules:
/// - Exotic **weapons** match by item hash only (weapons have no class).
/// - Exotic **armor** matches by item hash **and** guardian class (no
///   cross-class).
/// - Legendary armor matches by set + slot + class (no cross-class).
FillInMatchReport matchFillIn({
  required Iterable<FillInInventoryItem> inventory,
  required Iterable<FillInBuildRequirement> builds,
  int? inventoryCap,
}) {
  final cap = resolveFillInInventoryCap(inventoryCap);
  final pools = _buildPools(inventory);
  final results = <FillInBuildResult>[
    for (final build in builds) _matchBuild(build, pools, cap),
  ];
  return FillInMatchReport(
    cap: cap,
    builds: List<FillInBuildResult>.unmodifiable(results),
  );
}

FillInBuildResult _matchBuild(
  FillInBuildRequirement build,
  _HeldPools pools,
  int cap,
) {
  final flagged = _fillInSolipsismNotPrismatic(
    guardianClass: build.guardianClass,
    exoticName: build.exoticArmorName,
    subclassKey: build.subclassKey,
  );
  final slots = <FillInSlotMatch>[
    for (final need in build.slots)
      _matchSlot(build.guardianClass, need, pools, cap),
  ];
  return FillInBuildResult(
    buildId: build.buildId,
    solipsismNotPrismatic: flagged,
    slots: List<FillInSlotMatch>.unmodifiable(slots),
  );
}

/// Fill In Solipsism gate — fail closed vs silent OK.
///
/// Fail-closed (null exotic name / unknown subclass → flagged) applies only
/// to [GuardianClass.warlock]. Titan and Hunter never get a false Solipsism
/// flag from those missing fields; they still flag when the exotic name is
/// literally Solipsism on a known non-Prismatic subclass.
bool _fillInSolipsismNotPrismatic({
  required GuardianClass guardianClass,
  required String? exoticName,
  required String subclassKey,
}) {
  final failClosed = guardianClass == GuardianClass.warlock;
  if (exoticName == null) return failClosed;
  if (!isKnownWarlockSubclass(subclassKey)) return failClosed;
  return isSolipsismNotPrismatic(
    exoticName: exoticName,
    subclassKey: subclassKey,
  );
}

FillInSlotMatch _matchSlot(
  GuardianClass guardianClass,
  FillInSlotRequirement need,
  _HeldPools pools,
  int cap,
) {
  final count = pools.countFor(guardianClass, need);
  // Weapons: held count only — no 2-copy cap label (Daniel, Nov 12 2026).
  if (_isWeaponNeedSlot(need.slot)) {
    return FillInSlotMatch(
      slot: need.slot,
      isHeld: count > 0,
      poolHeldCount: count,
      cap: cap,
      exceedsCap: false,
      overCapLabel: null,
    );
  }
  final exceeds = count > cap;
  return FillInSlotMatch(
    slot: need.slot,
    isHeld: count > 0,
    poolHeldCount: count,
    cap: cap,
    exceedsCap: exceeds,
    overCapLabel: exceeds ? moreThanHeldLabel(cap) : null,
  );
}

class _HeldPools {
  _HeldPools(
    this._exoticArmorByKey,
    this._exoticWeaponByHash,
    this._legendaryByKey,
  );

  final Map<_ExoticArmorKey, int> _exoticArmorByKey;
  final Map<int, int> _exoticWeaponByHash;
  final Map<_LegendaryKey, int> _legendaryByKey;

  int countFor(GuardianClass guardianClass, FillInSlotRequirement need) {
    if (need.isExotic) {
      final hash = need.exoticItemHash;
      if (hash == null) return 0;
      if (_isWeaponNeedSlot(need.slot)) {
        return _exoticWeaponByHash[hash] ?? 0;
      }
      final key = _ExoticArmorKey(
        itemHash: hash,
        guardianClass: guardianClass,
      );
      return _exoticArmorByKey[key] ?? 0;
    }
    final setHash = need.armorSetHash;
    if (setHash == null) return 0;
    final key = _LegendaryKey(
      guardianClass: guardianClass,
      armorSetHash: setHash,
      slot: need.slot,
    );
    return _legendaryByKey[key] ?? 0;
  }
}

class _ExoticArmorKey {
  const _ExoticArmorKey({
    required this.itemHash,
    required this.guardianClass,
  });

  final int itemHash;
  final GuardianClass guardianClass;

  @override
  bool operator ==(Object other) {
    return other is _ExoticArmorKey &&
        other.itemHash == itemHash &&
        other.guardianClass == guardianClass;
  }

  @override
  int get hashCode => Object.hash(itemHash, guardianClass);
}

class _LegendaryKey {
  const _LegendaryKey({
    required this.guardianClass,
    required this.armorSetHash,
    required this.slot,
  });

  final GuardianClass guardianClass;
  final int armorSetHash;
  final EquipmentSlot slot;

  @override
  bool operator ==(Object other) {
    return other is _LegendaryKey &&
        other.guardianClass == guardianClass &&
        other.armorSetHash == armorSetHash &&
        other.slot == slot;
  }

  @override
  int get hashCode => Object.hash(guardianClass, armorSetHash, slot);
}

bool _isWeaponNeedSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

_HeldPools _buildPools(Iterable<FillInInventoryItem> inventory) {
  final seenIds = <String>{};
  final exoticArmorByKey = <_ExoticArmorKey, int>{};
  final exoticWeaponByHash = <int, int>{};
  final legendaryByKey = <_LegendaryKey, int>{};

  for (final item in inventory) {
    if (!seenIds.add(item.instanceId)) continue;

    if (EquipmentSlot.weaponSlots.contains(item.slot) ||
        item.slot == EquipmentSlot.exoticWeapon) {
      if (!item.isExotic) continue;
      exoticWeaponByHash[item.itemHash] =
          (exoticWeaponByHash[item.itemHash] ?? 0) + 1;
      continue;
    }

    if (!EquipmentSlot.armorSlots.contains(item.slot)) continue;
    final cls = item.guardianClass;
    if (cls == null) continue;

    if (item.isExotic) {
      final key = _ExoticArmorKey(
        itemHash: item.itemHash,
        guardianClass: cls,
      );
      exoticArmorByKey[key] = (exoticArmorByKey[key] ?? 0) + 1;
      continue;
    }
    final setHash = item.armorSetHash;
    if (setHash == null) continue;
    final key = _LegendaryKey(
      guardianClass: cls,
      armorSetHash: setHash,
      slot: item.slot,
    );
    legendaryByKey[key] = (legendaryByKey[key] ?? 0) + 1;
  }

  return _HeldPools(exoticArmorByKey, exoticWeaponByHash, legendaryByKey);
}
