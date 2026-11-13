import '../models/equipment.dart';
import 'fill_in_inventory.dart';

/// Rank of a similar-weapon suggestion (lower is better).
enum FillInSimilarWeaponTier {
  /// Same slot + same damage type + same weapon type.
  slotDamageType,

  /// Same slot + same damage type (weapon type may differ).
  slotDamage,

  /// No qualifying held candidate.
  none,
}

/// Target profile for a missing build weapon need.
class FillInWeaponNeed {
  const FillInWeaponNeed({
    required this.slot,
    required this.damageType,
    required this.weaponType,
    this.name,
  });

  /// Combat weapon slot the build wants filled.
  final EquipmentSlot slot;

  /// Desired damage element (DIM `Element`), compared case-insensitively.
  final String damageType;

  /// Desired weapon type (DIM `Type`), compared case-insensitively.
  final String weaponType;

  /// Optional display name of the missing weapon (for UI only).
  final String? name;
}

/// One similar held weapon suggestion (plan-only; never moves in-game items).
class FillInSimilarWeapon {
  const FillInSimilarWeapon({
    required this.item,
    required this.tier,
  });

  final FillInInventoryItem item;
  final FillInSimilarWeaponTier tier;
}

/// Pick the closest held weapon for a missing need.
///
/// Ranking (deterministic):
/// 1. Same [FillInWeaponNeed.slot] + damage type + weapon type
/// 2. Same slot + damage type
///
/// Tie-break within a tier: lower [FillInInventoryItem.itemHash], then
/// [FillInInventoryItem.instanceId]. Legendary and exotic held copies both
/// qualify. Returns null when no candidate meets tier 1 or 2.
FillInSimilarWeapon? suggestSimilarWeapon({
  required FillInWeaponNeed need,
  required Iterable<FillInInventoryItem> heldWeapons,
}) {
  final wantDamage = _norm(need.damageType);
  final wantType = _norm(need.weaponType);
  if (wantDamage.isEmpty || wantType.isEmpty) return null;
  if (!_isWeaponSlot(need.slot)) return null;

  FillInInventoryItem? bestTier1;
  FillInInventoryItem? bestTier2;

  for (final item in heldWeapons) {
    if (!_isWeaponSlot(item.slot)) continue;
    if (item.slot != need.slot) continue;
    final damage = _norm(item.damageType ?? '');
    if (damage.isEmpty || damage != wantDamage) continue;

    final type = _norm(item.weaponType ?? '');
    if (type.isNotEmpty && type == wantType) {
      bestTier1 = _better(bestTier1, item);
    } else {
      bestTier2 = _better(bestTier2, item);
    }
  }

  if (bestTier1 != null) {
    return FillInSimilarWeapon(
      item: bestTier1,
      tier: FillInSimilarWeaponTier.slotDamageType,
    );
  }
  if (bestTier2 != null) {
    return FillInSimilarWeapon(
      item: bestTier2,
      tier: FillInSimilarWeaponTier.slotDamage,
    );
  }
  return null;
}

FillInInventoryItem? _better(FillInInventoryItem? current, FillInInventoryItem next) {
  if (current == null) return next;
  final byHash = current.itemHash.compareTo(next.itemHash);
  if (byHash != 0) return byHash < 0 ? current : next;
  return current.instanceId.compareTo(next.instanceId) <= 0 ? current : next;
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

String _norm(String raw) => raw.trim().toLowerCase();
