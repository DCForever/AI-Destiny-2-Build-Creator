import '../dim_loadouts/cached_dim_loadout.dart';
import '../models/equipment.dart';

/// Named piece extracted from a compiled DIM loadout for Fill In.
class FillInDimNamedPiece {
  const FillInDimNamedPiece({
    required this.name,
    required this.hash,
    required this.slot,
    required this.isExotic,
  });

  final String name;
  final int hash;
  final EquipmentSlot slot;
  final bool isExotic;
}

/// Armor / weapon pieces + exotic summary from a [CachedDimLoadout].
///
/// Pure mapping — does not match inventory or mutate stores. Used by the host
/// Fill In mapper to populate exotic armor and total-fill slot needs that the
/// matrix→MockBuild path previously dropped.
class FillInDimLoadoutPieces {
  const FillInDimLoadoutPieces({
    this.exoticArmorName,
    this.exoticArmorHash,
    this.exoticArmorSlot,
    this.armorBySlot = const {},
    this.weaponsBySlot = const {},
  });

  final String? exoticArmorName;
  final int? exoticArmorHash;
  final EquipmentSlot? exoticArmorSlot;
  final Map<EquipmentSlot, FillInDimNamedPiece> armorBySlot;
  final Map<EquipmentSlot, FillInDimNamedPiece> weaponsBySlot;
}

/// Extract Fill In slot pieces from a compiled DIM loadout.
///
/// [CachedDimLoadout.exotic] is treated as exotic **armor** (same source the
/// details panel labels "EXOTIC"). Armor `itemType` values map to equipment
/// slots; weapon buckets use Kinetic/Energy/Power (and aliases). Weapon-type
/// labels (e.g. "Hand Cannon") alone do not assign a combat slot.
FillInDimLoadoutPieces extractFillInPiecesFromDimLoadout(
  CachedDimLoadout loadout,
) {
  final armorBySlot = <EquipmentSlot, FillInDimNamedPiece>{};
  final weaponsBySlot = <EquipmentSlot, FillInDimNamedPiece>{};

  for (final item in loadout.items) {
    final slot = equipmentSlotFromDimItemType(item.itemType);
    if (slot == null) continue;
    final name = item.name.trim();
    if (name.isEmpty) continue;
    final isExotic = item.tier.trim().toLowerCase() == 'exotic';
    final piece = FillInDimNamedPiece(
      name: name,
      hash: item.hash,
      slot: slot,
      isExotic: isExotic,
    );
    if (EquipmentSlot.armorSlots.contains(slot)) {
      armorBySlot.putIfAbsent(slot, () => piece);
    } else if (EquipmentSlot.weaponSlots.contains(slot)) {
      weaponsBySlot.putIfAbsent(slot, () => piece);
    }
  }

  final exotic = loadout.exotic;
  String? exoticArmorName;
  int? exoticArmorHash;
  EquipmentSlot? exoticArmorSlot;

  if (exotic != null && exotic.name.trim().isNotEmpty) {
    exoticArmorName = exotic.name.trim();
    exoticArmorHash = exotic.hash;
    for (final entry in armorBySlot.entries) {
      if (entry.value.hash == exotic.hash ||
          entry.value.name.toLowerCase() == exoticArmorName.toLowerCase()) {
        exoticArmorSlot = entry.key;
        break;
      }
    }
    // Never invent a class-item (or any) slot for an unknown exotic — Swarmers
    // legs must not appear as Class Item when the item row is missing/unmapped.
    final knownExoticSlot = exoticArmorSlot;
    if (knownExoticSlot != null) {
      armorBySlot.putIfAbsent(
        knownExoticSlot,
        () => FillInDimNamedPiece(
          name: exoticArmorName!,
          hash: exotic.hash,
          slot: knownExoticSlot,
          isExotic: true,
        ),
      );
    }
  }

  return FillInDimLoadoutPieces(
    exoticArmorName: exoticArmorName,
    exoticArmorHash: exoticArmorHash,
    exoticArmorSlot: exoticArmorSlot,
    armorBySlot: Map<EquipmentSlot, FillInDimNamedPiece>.unmodifiable(
      armorBySlot,
    ),
    weaponsBySlot: Map<EquipmentSlot, FillInDimNamedPiece>.unmodifiable(
      weaponsBySlot,
    ),
  );
}

/// Map a DIM cache `itemType` string to an [EquipmentSlot], or null.
EquipmentSlot? equipmentSlotFromDimItemType(String itemType) {
  final key = itemType.trim().toLowerCase();
  if (key.isEmpty) return null;
  final compact = key.replaceAll(RegExp(r'[\s_-]+'), '');

  switch (compact) {
    case 'helmet':
      return EquipmentSlot.helmet;
    case 'gauntlets':
    case 'arms':
      return EquipmentSlot.arms;
    case 'chest':
    case 'chestarmor':
      return EquipmentSlot.chest;
    case 'legs':
    case 'legarmor':
      return EquipmentSlot.legs;
    case 'classitem':
    case 'classarmor':
      return EquipmentSlot.classItem;
    case 'kinetic':
    case 'kineticslot':
    case 'kineticweapon':
    case 'kineticweapons':
    case 'primary':
    case 'primaryweapon':
      return EquipmentSlot.primary;
    case 'energy':
    case 'energyweapon':
    case 'energyweapons':
    case 'special':
    case 'specialweapon':
      return EquipmentSlot.special;
    case 'power':
    case 'powerweapon':
    case 'powerweapons':
    case 'heavy':
    case 'heavyweapon':
      return EquipmentSlot.heavy;
    default:
      return null;
  }
}
