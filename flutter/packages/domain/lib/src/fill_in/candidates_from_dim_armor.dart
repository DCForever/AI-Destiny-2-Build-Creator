import '../models/equipment.dart';
import '../models/optimizer.dart';
import 'armor_pool_set_coverage.dart';
import 'fill_in_inventory.dart';

/// Map DIM armor CSV rows into optimizer [CandidatePiece]s for one class.
///
/// Skips weapons and other-class armor. [setBonusKeyByItemHash] stamps legendary
/// set-bonus keys when [FillInInventoryItem.armorSetHash] alone is not enough
/// for display goals. No network; inventory is injected.
List<CandidatePiece> candidatesFromDimArmorItems({
  required List<FillInInventoryItem> items,
  required GuardianClass guardianClass,
  Map<int, String> setBonusKeyByItemHash = const <int, String>{},
}) {
  final out = <CandidatePiece>[];
  for (final item in items) {
    if (item.guardianClass != guardianClass) continue;
    if (!EquipmentSlot.armorSlots.contains(item.slot)) continue;
    final mapped = setBonusKeyByItemHash[item.itemHash]?.trim();
    final fromHash = item.armorSetHash;
    final String? setKey;
    if (mapped != null && mapped.isNotEmpty) {
      setKey = mapped;
    } else if (fromHash != null && fromHash > 0) {
      setKey = 'set:$fromHash';
    } else {
      setKey = null;
    }
    out.add(
      CandidatePiece(
        slot: item.slot,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        itemName: item.name,
        isExotic: item.isExotic,
        setBonusKey: item.isExotic ? null : setKey,
        statValues: item.statValues,
      ),
    );
  }
  return out;
}

/// Format [ArmorCombination.setBonusSummary] as one combined box label.
String formatCombinationSetBonusBox(ArmorCombination combo) {
  return formatOptimizerSetBonusBox([
    for (final e in combo.setBonusSummary)
      (
        setBonusKey: e.setBonusKey,
        pieceCount: e.pieceCount,
        active2pc: e.active2pc,
        active4pc: e.active4pc,
      ),
  ]);
}

/// Lookup location for an instance id from the CSV inventory board.
String? locationForInstanceId({
  required List<FillInInventoryItem> items,
  required String instanceId,
}) {
  final id = instanceId.trim();
  if (id.isEmpty) return null;
  for (final item in items) {
    if (item.instanceId == id) return item.location;
  }
  return null;
}
