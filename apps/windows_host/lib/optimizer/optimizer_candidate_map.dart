import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Map inventory / catalog rows into optimizer [CandidatePiece] boards (DART-036).
///
/// MVP mapping only — full projection polish is out of scope.

/// Inventory bucket labels stored by sync (see bungie inventory_buckets).
const Set<String> kArmorInventoryBuckets = {
  'Helmet',
  'Gauntlets',
  'Chest',
  'Legs',
  'ClassItem',
};

/// Map a stored inventory bucket label to an [EquipmentSlot] armor slot.
EquipmentSlot? armorSlotFromInventoryBucket(String bucket) {
  switch (bucket.trim()) {
    case 'Helmet':
      return EquipmentSlot.helmet;
    case 'Gauntlets':
    case 'Arms':
      return EquipmentSlot.arms;
    case 'Chest':
    case 'Chest Armor':
      return EquipmentSlot.chest;
    case 'Legs':
    case 'Leg Armor':
      return EquipmentSlot.legs;
    case 'ClassItem':
    case 'Class Item':
    case 'Class Armor':
      return EquipmentSlot.classItem;
    default:
      return null;
  }
}

/// Parse inventory [statValues] JSON-ish map into Armor 3.0 stats when possible.
Map<ArmorStatName, int> parseArmorStatValues(Map<String, Object?>? raw) {
  if (raw == null || raw.isEmpty) return const {};
  final out = <ArmorStatName, int>{};
  for (final e in raw.entries) {
    final name = ArmorStatName.tryParse(e.key);
    if (name == null) continue;
    final v = e.value;
    if (v is int) {
      out[name] = v;
    } else if (v is num) {
      out[name] = v.toInt();
    } else if (v is String) {
      final n = int.tryParse(v);
      if (n != null) out[name] = n;
    }
  }
  return out;
}

/// Build candidates from inventory rows + optional catalog annotations.
///
/// Non-armor buckets are skipped. Missing catalog entry → non-exotic, hash name.
List<CandidatePiece> candidatesFromInventory({
  required List<InventoryItemRecord> items,
  Map<int, CatalogItem>? catalogByHash,
}) {
  final out = <CandidatePiece>[];
  for (final item in items) {
    final slot = armorSlotFromInventoryBucket(item.bucket);
    if (slot == null) continue;
    final cat = catalogByHash?[item.itemHash];
    out.add(
      CandidatePiece(
        slot: slot,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        itemName: cat?.name,
        isExotic: cat?.isExotic ?? false,
        statValues: parseArmorStatValues(item.statValues),
      ),
    );
  }
  return out;
}

/// Whether the inventory list has any armor-bucket rows.
bool inventoryHasArmorCandidates(List<InventoryItemRecord> items) {
  for (final item in items) {
    if (armorSlotFromInventoryBucket(item.bucket) != null) return true;
  }
  return false;
}
