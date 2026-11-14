import '../models/equipment.dart';
import 'fill_in_inventory.dart';

/// One armor slot's set-coverage row for the Armor pool tab.
///
/// Counts **sets**, not raw owned pieces: for each set in [setUniverse], how
/// many copies of that set exist in [slot] for the class (2+, 1, or 0).
class ArmorPoolSlotCoverage {
  const ArmorPoolSlotCoverage({
    required this.slot,
    required this.setsWithTwoPlus,
    required this.setsWithOne,
    required this.setsWithNone,
    required this.setUniverseCount,
  });

  final EquipmentSlot slot;

  /// Sets that have at least 2 pieces in this slot (goal cell).
  final int setsWithTwoPlus;

  /// Sets that have exactly 1 piece in this slot.
  final int setsWithOne;

  /// Sets that have 0 pieces in this slot.
  final int setsWithNone;

  /// Denominator for "X of N" (derived set universe size).
  final int setUniverseCount;

  /// True when this slot meets the 2-copies goal for every set in the universe.
  bool get slotGoalMet =>
      setUniverseCount > 0 && setsWithTwoPlus == setUniverseCount;
}

/// Aggregate Armor pool coverage for one guardian class.
class ArmorPoolCoverageReport {
  const ArmorPoolCoverageReport({
    required this.guardianClass,
    required this.setUniverseCount,
    required this.slotRows,
    required this.slotGoalsMet,
    required this.slotGoalsTotal,
  });

  final GuardianClass guardianClass;

  /// Distinct legendary set keys considered (derived; may differ from 28).
  final int setUniverseCount;

  final List<ArmorPoolSlotCoverage> slotRows;

  /// How many (set × slot) goals are met (2+ pieces).
  final int slotGoalsMet;

  /// [setUniverseCount] × armor slot count (5).
  final int slotGoalsTotal;
}

/// Resolve a stable set key for coverage counting.
///
/// Prefers [FillInInventoryItem.armorSetHash] as a string; when absent and
/// [setKeyByItemHash] supplies a label, uses that. Exotics are skipped.
String? armorPoolSetKeyForItem(
  FillInInventoryItem item, {
  Map<int, String> setKeyByItemHash = const <int, String>{},
}) {
  if (item.isExotic) return null;
  if (!EquipmentSlot.armorSlots.contains(item.slot)) return null;
  final hash = item.armorSetHash;
  if (hash != null && hash > 0) return 'set:$hash';
  final mapped = setKeyByItemHash[item.itemHash]?.trim();
  if (mapped != null && mapped.isNotEmpty) return mapped;
  return null;
}

/// Build the set-coverage report for [guardianClass] from DIM armor rows.
///
/// [knownSetKeys] seeds the universe (e.g. catalog / matrix set ids). Keys
/// observed on inventory for this class are always included. When both are
/// empty, [setUniverseCount] is 0 and every row is zeros.
ArmorPoolCoverageReport computeArmorPoolSetCoverage({
  required List<FillInInventoryItem> items,
  required GuardianClass guardianClass,
  Set<String> knownSetKeys = const <String>{},
  Map<int, String> setKeyByItemHash = const <int, String>{},
}) {
  final universe = <String>{
    for (final k in knownSetKeys)
      if (k.trim().isNotEmpty) k.trim(),
  };

  // setKey → slot → piece count
  final counts = <String, Map<EquipmentSlot, int>>{};

  for (final item in items) {
    if (item.guardianClass != guardianClass) continue;
    final key = armorPoolSetKeyForItem(
      item,
      setKeyByItemHash: setKeyByItemHash,
    );
    if (key == null) continue;
    universe.add(key);
    final bySlot = counts.putIfAbsent(
      key,
      () => <EquipmentSlot, int>{},
    );
    bySlot[item.slot] = (bySlot[item.slot] ?? 0) + 1;
  }

  final setCount = universe.length;
  final rows = <ArmorPoolSlotCoverage>[];
  var goalsMet = 0;
  for (final slot in EquipmentSlot.armorSlots) {
    var twoPlus = 0;
    var one = 0;
    var none = 0;
    for (final setKey in universe) {
      final n = counts[setKey]?[slot] ?? 0;
      if (n >= 2) {
        twoPlus += 1;
        goalsMet += 1;
      } else if (n == 1) {
        one += 1;
      } else {
        none += 1;
      }
    }
    rows.add(
      ArmorPoolSlotCoverage(
        slot: slot,
        setsWithTwoPlus: twoPlus,
        setsWithOne: one,
        setsWithNone: none,
        setUniverseCount: setCount,
      ),
    );
  }

  return ArmorPoolCoverageReport(
    guardianClass: guardianClass,
    setUniverseCount: setCount,
    slotRows: List<ArmorPoolSlotCoverage>.unmodifiable(rows),
    slotGoalsMet: goalsMet,
    slotGoalsTotal: setCount * EquipmentSlot.armorSlots.length,
  );
}

/// Map DIM `Owner` cell to vault / character / postmaster (display).
String? armorLocationFromDimOwner(String? ownerRaw) {
  final raw = ownerRaw?.trim() ?? '';
  if (raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  if (lower == 'vault' || lower.startsWith('vault')) return 'vault';
  if (lower.contains('postmaster')) return 'postmaster';
  return 'character';
}

/// Human label for [armorLocationFromDimOwner] wire values.
String formatArmorLocationLabel(String? location) {
  switch (location) {
    case 'vault':
      return 'Vault';
    case 'postmaster':
      return 'Postmaster';
    case 'character':
      return 'Character';
    default:
      return 'Unknown';
  }
}

/// One-line set-bonus box: `4pc A` or `2pc A + 2pc B`.
String formatOptimizerSetBonusBox(
  List<({String setBonusKey, int pieceCount, bool active2pc, bool active4pc})>
      summary,
) {
  if (summary.isEmpty) return 'None';
  final four = summary.where((e) => e.active4pc).toList();
  if (four.isNotEmpty) {
    return '4pc ${four.first.setBonusKey}';
  }
  final twos = summary.where((e) => e.active2pc).toList();
  if (twos.length >= 2) {
    return '2pc ${twos[0].setBonusKey} + 2pc ${twos[1].setBonusKey}';
  }
  if (twos.length == 1) {
    return '2pc ${twos.first.setBonusKey}';
  }
  // Fallback: highest piece counts.
  final sorted = [...summary]
    ..sort((a, b) => b.pieceCount.compareTo(a.pieceCount));
  if (sorted.first.pieceCount >= 4) {
    return '4pc ${sorted.first.setBonusKey}';
  }
  if (sorted.length >= 2 &&
      sorted[0].pieceCount >= 2 &&
      sorted[1].pieceCount >= 2) {
    return '2pc ${sorted[0].setBonusKey} + 2pc ${sorted[1].setBonusKey}';
  }
  if (sorted.first.pieceCount >= 2) {
    return '2pc ${sorted.first.setBonusKey}';
  }
  return 'None';
}
