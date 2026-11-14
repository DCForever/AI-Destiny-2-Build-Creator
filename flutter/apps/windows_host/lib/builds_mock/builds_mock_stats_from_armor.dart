import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import '../optimize/builds_optimize_apply.dart';
import 'builds_mock_models.dart';

/// Outcome of summing Armor 3.0 stats from the DIM Armor CSV for a build.
class BuildsMockStatsResolution {
  const BuildsMockStatsResolution({
    required this.stats,
    this.unavailableReason,
  });

  final List<MockStatTotal> stats;

  /// Set when [stats] is empty — specific reason, never a blank.
  final String? unavailableReason;

  bool get isAvailable => stats.isNotEmpty;
}

/// Sum six Armor 3.0 stats from imported DIM Armor CSV rows matched to the
/// build's applied armor (Fill In plan instance ids, then name+slot).
///
/// Prefer existing [MockBuild.stats] when already populated (e.g. Optimize
/// apply). Otherwise look up pieces in [armorItems].
BuildsMockStatsResolution resolveBuildsMockStats({
  required MockBuild build,
  List<FillInInventoryItem> armorItems = const [],
  FillInSavedBuildPlan? fillInPlan,
}) {
  if (build.stats.isNotEmpty) {
    return BuildsMockStatsResolution(
      stats: List<MockStatTotal>.unmodifiable(build.stats),
    );
  }

  final armorSlots = [
    for (final s in build.slots)
      if (EquipmentSlot.armorSlots.any((a) => a.wireName == s.slot) &&
          s.pieceName.trim().isNotEmpty)
        s,
  ];
  if (armorSlots.isEmpty) {
    return const BuildsMockStatsResolution(
      stats: [],
      unavailableReason: 'No applied armor on this build yet.',
    );
  }

  if (armorItems.isEmpty) {
    return const BuildsMockStatsResolution(
      stats: [],
      unavailableReason:
          'Import a DIM Armor CSV in Settings to see armor stats.',
    );
  }

  final appliedByWire = <String, FillInAppliedSlot>{
    if (fillInPlan != null)
      for (final a in fillInPlan.applied)
        if (a.slotWire.trim().isNotEmpty) a.slotWire: a,
  };

  final totals = <ArmorStatName, int>{
    for (final s in ArmorStatName.all) s: 0,
  };
  var matched = 0;
  var missingStats = 0;

  for (final slot in armorSlots) {
    final item = _matchArmorItem(
      slot: slot,
      applied: appliedByWire[slot.slot],
      armorItems: armorItems,
    );
    if (item == null) continue;
    matched++;
    if (item.statValues.isEmpty) {
      missingStats++;
      continue;
    }
    for (final e in item.statValues.entries) {
      totals[e.key] = (totals[e.key] ?? 0) + e.value;
    }
  }

  if (matched == 0) {
    return const BuildsMockStatsResolution(
      stats: [],
      unavailableReason:
          'Applied armor not found in the imported DIM Armor CSV.',
    );
  }
  if (matched == missingStats) {
    return const BuildsMockStatsResolution(
      stats: [],
      unavailableReason:
          'DIM Armor CSV rows for this build have no Weapons/Health/Class/'
          'Grenade/Super/Melee values.',
    );
  }

  final stats = <MockStatTotal>[
    for (final name in ArmorStatName.all)
      if (mockStatIdFromArmorStat(name) case final id?)
        MockStatTotal(id: id, value: totals[name] ?? 0),
  ];
  return BuildsMockStatsResolution(
    stats: List<MockStatTotal>.unmodifiable(stats),
  );
}

FillInInventoryItem? _matchArmorItem({
  required MockSlotAssignment slot,
  required FillInAppliedSlot? applied,
  required List<FillInInventoryItem> armorItems,
}) {
  final instanceId = applied?.instanceId?.trim() ?? '';
  if (instanceId.isNotEmpty) {
    for (final item in armorItems) {
      if (item.instanceId == instanceId) return item;
    }
  }
  final hash = applied?.itemHash;
  if (hash != null && hash > 0) {
    for (final item in armorItems) {
      if (item.itemHash == hash && item.slot.wireName == slot.slot) {
        return item;
      }
    }
  }
  final want = slot.pieceName.trim().toLowerCase();
  if (want.isEmpty) return null;
  for (final item in armorItems) {
    if (item.slot.wireName != slot.slot) continue;
    if ((item.name ?? '').trim().toLowerCase() == want) return item;
  }
  return null;
}
