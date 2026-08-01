/// Pure loadout soft-stat estimate helpers (TS `statEstimate.ts`).
///
/// Soft guidance only — never a hard block.
library;

import '../models/equipment.dart';
import '../models/slot_claim.dart';
import '../models/soft_stats.dart';

/// Sum armor instance stats across claims.
///
/// [inventoryStatsByInstanceId] maps instance id → Armor 3.0 stat values.
/// Missing instance, missing map entry, or missing armor slots mark [StatEstimate.incomplete].
StatEstimate estimateLoadoutStats(
  List<SlotClaim> claims,
  Map<String, Map<ArmorStatName, int>> inventoryStatsByInstanceId,
) {
  final totals = <ArmorStatName, int>{
    for (final name in ArmorStatName.all) name: 0,
  };

  var incomplete = false;
  var armorClaims = 0;

  for (final claim in claims) {
    if (!EquipmentSlot.armorSlots.contains(claim.slot)) continue;
    armorClaims += 1;
    final instanceId = claim.instanceId;
    if (instanceId == null || instanceId.isEmpty) {
      incomplete = true;
      continue;
    }
    final itemStats = inventoryStatsByInstanceId[instanceId];
    if (itemStats == null || itemStats.isEmpty) {
      incomplete = true;
      continue;
    }
    for (final name in ArmorStatName.all) {
      final v = itemStats[name];
      if (v != null) {
        totals[name] = (totals[name] ?? 0) + v;
      }
    }
  }

  if (armorClaims < EquipmentSlot.armorSlots.length) {
    incomplete = true;
  }

  return StatEstimate(values: totals, incomplete: incomplete);
}

/// Emit soft-stat warning rows for estimates below targets only.
List<SoftStatWarningRow> softStatWarnings(
  SoftStatTargets targets,
  StatEstimate estimate,
) {
  final rows = <SoftStatWarningRow>[];
  for (final name in ArmorStatName.all) {
    final target = targets[name];
    if (target == null) continue;
    final value = estimate[name] ?? 0;
    if (value < target) {
      rows.add(
        SoftStatWarningRow(
          stat: name,
          target: target,
          estimate: value,
          hint:
              '${name.wireName} estimate $value is below target $target.',
        ),
      );
    }
  }
  return rows;
}
