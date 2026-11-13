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
/// - **Weapons** match by item hash only (weapons have no class). Exotic and
///   legendary weapons share the same hash pool so total-fill can mark held
///   copies for every combat weapon slot.
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
  final flag = resolveFillInSolipsismFlag(
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
    solipsismFlag: flag,
    slots: List<FillInSlotMatch>.unmodifiable(slots),
  );
}

/// Fill In Solipsism gate — fail closed vs silent OK.
///
/// - [FillInSolipsismFlag.notPrismatic]: exotic name is literally Solipsism on
///   a known non-Prismatic subclass (any guardian class).
/// - [FillInSolipsismFlag.exoticArmorUnknown]: Warlock only — null exotic name
///   or unknown subclass, so Solipsism/Prismatic cannot be confirmed.
/// - Titan / Hunter: null exotic / unknown subclass → [FillInSolipsismFlag.none]
///   (never a false Solipsism warning from missing fields).
FillInSolipsismFlag resolveFillInSolipsismFlag({
  required GuardianClass guardianClass,
  required String? exoticName,
  required String subclassKey,
}) {
  final trimmed = exoticName?.trim();
  final hasExotic = trimmed != null && trimmed.isNotEmpty;
  final knownSubclass = isKnownWarlockSubclass(subclassKey);

  if (hasExotic && knownSubclass) {
    if (isSolipsismNotPrismatic(
      exoticName: trimmed,
      subclassKey: subclassKey,
    )) {
      return FillInSolipsismFlag.notPrismatic;
    }
    return FillInSolipsismFlag.none;
  }

  // Fail-closed unknown only for Warlock.
  if (guardianClass != GuardianClass.warlock) {
    return FillInSolipsismFlag.none;
  }
  if (!hasExotic || !knownSubclass) {
    return FillInSolipsismFlag.exoticArmorUnknown;
  }
  return FillInSolipsismFlag.none;
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
  // Exotic armor: held count only — the 2-copy cap is legendary-set farming.
  // Applying it to exotics falsely flags held Briarbinds / Vesper as over-cap
  // when duplicate legendary needs or multiple exotic copies inflate the pool.
  if (need.isExotic) {
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
    this._weaponByHash,
    this._legendaryByKey,
  );

  final Map<_ExoticArmorKey, int> _exoticArmorByKey;
  final Map<int, int> _weaponByHash;
  final Map<_LegendaryKey, int> _legendaryByKey;

  int countFor(GuardianClass guardianClass, FillInSlotRequirement need) {
    if (_isWeaponNeedSlot(need.slot)) {
      final hash = need.exoticItemHash;
      if (hash == null) return 0;
      return _weaponByHash[hash] ?? 0;
    }
    if (need.isExotic) {
      final hash = need.exoticItemHash;
      if (hash == null) return 0;
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
  final weaponByHash = <int, int>{};
  final legendaryByKey = <_LegendaryKey, int>{};

  for (final item in inventory) {
    if (!seenIds.add(item.instanceId)) continue;

    if (EquipmentSlot.weaponSlots.contains(item.slot) ||
        item.slot == EquipmentSlot.exoticWeapon) {
      weaponByHash[item.itemHash] = (weaponByHash[item.itemHash] ?? 0) + 1;
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

  return _HeldPools(exoticArmorByKey, weaponByHash, legendaryByKey);
}
