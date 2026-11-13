import '../models/equipment.dart';
import 'fill_in_inventory.dart';

/// Coarse range band for Fill In weapon substitutes (Daniel, Nov 13 2026).
enum FillInWeaponRangeClass {
  /// Shotgun, SMG, sidearm, fusion, sword, glaive, trace, grenade launcher…
  short,

  /// Scout, pulse, hand cannon, auto, sniper, linear fusion, bow, rocket…
  long,

  /// Unknown / unmapped type — never preferred by the opposite-range rule.
  unknown,
}

/// Explicit DIM `Type` → range-class table (lowercase keys).
const Map<String, FillInWeaponRangeClass> kFillInWeaponRangeByType =
    <String, FillInWeaponRangeClass>{
  // Short range
  'shotgun': FillInWeaponRangeClass.short,
  'submachine gun': FillInWeaponRangeClass.short,
  'smg': FillInWeaponRangeClass.short,
  'sidearm': FillInWeaponRangeClass.short,
  'fusion rifle': FillInWeaponRangeClass.short,
  'sword': FillInWeaponRangeClass.short,
  'glaive': FillInWeaponRangeClass.short,
  'trace rifle': FillInWeaponRangeClass.short,
  'grenade launcher': FillInWeaponRangeClass.short,
  // Long range
  'scout rifle': FillInWeaponRangeClass.long,
  'pulse rifle': FillInWeaponRangeClass.long,
  'hand cannon': FillInWeaponRangeClass.long,
  'auto rifle': FillInWeaponRangeClass.long,
  'sniper rifle': FillInWeaponRangeClass.long,
  'linear fusion rifle': FillInWeaponRangeClass.long,
  'bow': FillInWeaponRangeClass.long,
  'rocket launcher': FillInWeaponRangeClass.long,
  'machine gun': FillInWeaponRangeClass.long,
};

/// Resolve [weaponType] (DIM `Type`) to a range class.
FillInWeaponRangeClass fillInWeaponRangeClass(String? weaponType) {
  final key = (weaponType ?? '').trim().toLowerCase();
  if (key.isEmpty) return FillInWeaponRangeClass.unknown;
  return kFillInWeaponRangeByType[key] ?? FillInWeaponRangeClass.unknown;
}

/// Opposite range class, or null when [band] is unknown.
FillInWeaponRangeClass? fillInOppositeWeaponRange(
  FillInWeaponRangeClass band,
) {
  switch (band) {
    case FillInWeaponRangeClass.short:
      return FillInWeaponRangeClass.long;
    case FillInWeaponRangeClass.long:
      return FillInWeaponRangeClass.short;
    case FillInWeaponRangeClass.unknown:
      return null;
  }
}

/// Subclass key → damage element for Fill In weapon filtering.
///
/// Prismatic and unknown subclasses return null (= any element).
String? fillInDamageTypeForSubclass(String subclassKey) {
  switch (subclassKey.trim().toLowerCase()) {
    case 'arc':
      return 'Arc';
    case 'solar':
      return 'Solar';
    case 'void':
      return 'Void';
    case 'stasis':
      return 'Stasis';
    case 'strand':
      return 'Strand';
    case 'prismatic':
    default:
      return null;
  }
}

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
