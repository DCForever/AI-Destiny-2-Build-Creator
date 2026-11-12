import '../models/equipment.dart';
import '../warlock_matrix/solipsism_flag.dart';
import 'fill_in_cap.dart';
import 'fill_in_inventory.dart';
import 'fill_in_requirement.dart';
import 'fill_in_result.dart';

/// Match build armor needs against a held inventory snapshot.
///
/// Read-only: never mutates Bungie inventory or local store state.
/// Builds share the same physical copies (no exclusive reservation).
/// Each [FillInInventoryItem.instanceId] counts toward at most one pool cell.
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
  final flagged = isSolipsismNotPrismatic(
    exoticName: build.exoticArmorName ?? '',
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

FillInSlotMatch _matchSlot(
  GuardianClass guardianClass,
  FillInSlotRequirement need,
  _HeldPools pools,
  int cap,
) {
  final count = pools.countFor(guardianClass, need);
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
  _HeldPools(this._exoticByHash, this._legendaryByKey);

  final Map<int, int> _exoticByHash;
  final Map<_LegendaryKey, int> _legendaryByKey;

  int countFor(GuardianClass guardianClass, FillInSlotRequirement need) {
    if (need.isExotic) {
      final hash = need.exoticItemHash;
      if (hash == null) return 0;
      return _exoticByHash[hash] ?? 0;
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

_HeldPools _buildPools(Iterable<FillInInventoryItem> inventory) {
  final seenIds = <String>{};
  final exoticByHash = <int, int>{};
  final legendaryByKey = <_LegendaryKey, int>{};

  for (final item in inventory) {
    if (!EquipmentSlot.armorSlots.contains(item.slot)) continue;
    if (!seenIds.add(item.instanceId)) continue;
    if (item.isExotic) {
      exoticByHash[item.itemHash] = (exoticByHash[item.itemHash] ?? 0) + 1;
      continue;
    }
    final setHash = item.armorSetHash;
    if (setHash == null) continue;
    final key = _LegendaryKey(
      guardianClass: item.guardianClass,
      armorSetHash: setHash,
      slot: item.slot,
    );
    legendaryByKey[key] = (legendaryByKey[key] ?? 0) + 1;
  }

  return _HeldPools(exoticByHash, legendaryByKey);
}
