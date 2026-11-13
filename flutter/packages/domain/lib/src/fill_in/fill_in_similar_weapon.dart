import '../models/equipment.dart';
import 'fill_in_inventory.dart';

/// Rank of a similar-weapon suggestion (lower is better).
enum FillInSimilarWeaponTier {
  /// Same slot + same damage type + same weapon type.
  slotDamageType,

  /// Same slot + same damage type (weapon type may differ).
  slotDamage,

  /// Same combat bucket only (no known damage/type profile on the need).
  slotOnly,

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
  /// Empty when the build has no known profile (e.g. empty DIM weapon row).
  final String damageType;

  /// Desired weapon type (DIM `Type`), compared case-insensitively.
  /// Empty when the build has no known profile.
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
/// 3. Same slot only — when the need has no damage/type profile (empty row)
///
/// Tie-break within a tier: lower [FillInInventoryItem.itemHash], then
/// [FillInInventoryItem.instanceId].
///
/// When [excludeExotic] is true, exotic held copies are skipped (build already
/// has a different exotic weapon). Returns null when no candidate qualifies.
FillInSimilarWeapon? suggestSimilarWeapon({
  required FillInWeaponNeed need,
  required Iterable<FillInInventoryItem> heldWeapons,
  bool excludeExotic = false,
}) {
  if (!_isWeaponSlot(need.slot)) return null;

  final wantDamage = _norm(need.damageType);
  final wantType = _norm(need.weaponType);
  final hasProfile = wantDamage.isNotEmpty && wantType.isNotEmpty;
  final hasDamageOnly = wantDamage.isNotEmpty;

  FillInInventoryItem? bestTier1;
  FillInInventoryItem? bestTier2;
  FillInInventoryItem? bestTier3;

  for (final item in heldWeapons) {
    if (!_isWeaponSlot(item.slot)) continue;
    if (item.slot != need.slot) continue;
    if (excludeExotic && item.isExotic) continue;

    final damage = _norm(item.damageType ?? '');
    final type = _norm(item.weaponType ?? '');

    if (hasProfile) {
      if (damage.isEmpty || damage != wantDamage) continue;
      if (type.isNotEmpty && type == wantType) {
        bestTier1 = _better(bestTier1, item);
      } else {
        bestTier2 = _better(bestTier2, item);
      }
      continue;
    }

    if (hasDamageOnly) {
      if (damage.isEmpty || damage != wantDamage) continue;
      bestTier2 = _better(bestTier2, item);
      continue;
    }

    // No damage/type on the need — any held copy in this bucket.
    bestTier3 = _better(bestTier3, item);
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
  if (bestTier3 != null) {
    return FillInSimilarWeapon(
      item: bestTier3,
      tier: FillInSimilarWeaponTier.slotOnly,
    );
  }
  return null;
}

FillInInventoryItem? _better(
  FillInInventoryItem? current,
  FillInInventoryItem next,
) {
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
