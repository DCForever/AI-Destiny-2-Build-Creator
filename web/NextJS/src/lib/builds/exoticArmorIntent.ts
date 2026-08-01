import type { ArmorSlotName, WeaponSlotName } from "@/lib/manifest/types/records";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import {
  armorManifestSlotToEquipment,
  weaponManifestSlotToEquipment,
} from "@/lib/builds/resolveVariant";
import { getServices } from "@/lib/services";

export type ExoticArmorIdentityMode = "classic" | "class_item_intent";

export function isExoticClassItemSlot(slot: ArmorSlotName | string | null | undefined): boolean {
  return slot === "ClassItem";
}

/** Derive identity mode from catalog slot + hash. Unset hash → classic. */
export function modeFromArmorSlot(
  slot: ArmorSlotName | string | null | undefined,
  hash: number | null | undefined,
): ExoticArmorIdentityMode {
  if (hash == null) return "classic";
  return isExoticClassItemSlot(slot) ? "class_item_intent" : "classic";
}

/**
 * Whether an exoticArmorHash change requires identity confirm/fork.
 * Class-item → class-item swaps do not; classic swaps and mode flips do.
 */
export function isIdentityExoticArmorChange(
  existingHash: number | null,
  nextHash: number | null,
  existingMode: ExoticArmorIdentityMode,
  nextMode: ExoticArmorIdentityMode,
): boolean {
  if (existingHash === nextHash) return false;
  if (existingMode === "class_item_intent" && nextMode === "class_item_intent") {
    return false;
  }
  return true;
}

export async function lookupExoticArmorSlot(
  exoticArmorHash: number | null,
): Promise<ArmorSlotName | null> {
  if (exoticArmorHash == null) return null;
  try {
    const { entityCache } = await getServices();
    const armor = await entityCache.getStore("exotic-armor");
    const match = armor.find((a) => a.hash === exoticArmorHash);
    return match?.slot ?? null;
  } catch {
    return null;
  }
}

export async function resolveExoticArmorIdentityMode(
  exoticArmorHash: number | null,
): Promise<ExoticArmorIdentityMode> {
  const slot = await lookupExoticArmorSlot(exoticArmorHash);
  return modeFromArmorSlot(slot, exoticArmorHash);
}

export async function lookupExoticSlots(
  exoticWeaponHash: number | null,
  exoticArmorHash: number | null,
): Promise<{ weaponSlot: EquipmentSlot | null; armorSlot: EquipmentSlot | null }> {
  const batch = await lookupExoticSlotsBatch(
    exoticWeaponHash != null ? [exoticWeaponHash] : [],
    exoticArmorHash,
  );
  return {
    weaponSlot:
      exoticWeaponHash != null
        ? (batch.weaponSlotByHash.get(exoticWeaponHash) ?? null)
        : null,
    armorSlot: batch.armorSlot,
  };
}

/**
 * Batch exotic slot resolution — load entity stores once for many weapon hashes.
 */
export async function lookupExoticSlotsBatch(
  exoticWeaponHashes: readonly (number | null | undefined)[],
  exoticArmorHash: number | null,
): Promise<{
  armorSlot: EquipmentSlot | null;
  weaponSlotByHash: Map<number, EquipmentSlot>;
}> {
  const weaponSlotByHash = new Map<number, EquipmentSlot>();
  const uniqueWeapons = [
    ...new Set(
      exoticWeaponHashes.filter(
        (h): h is number => h != null && Number.isFinite(h),
      ),
    ),
  ];

  try {
    const { entityCache } = await getServices();
    const needWeapons = uniqueWeapons.length > 0;
    const needArmor = exoticArmorHash != null;
    const [exotics, armor] = await Promise.all([
      needWeapons ? entityCache.getStore("exotic-weapons") : Promise.resolve([]),
      needArmor ? entityCache.getStore("exotic-armor") : Promise.resolve([]),
    ]);

    if (needWeapons) {
      const byHash = new Map(exotics.map((w) => [w.hash, w] as const));
      for (const hash of uniqueWeapons) {
        const match = byHash.get(hash);
        if (match) {
          weaponSlotByHash.set(
            hash,
            weaponManifestSlotToEquipment(match.slot as WeaponSlotName),
          );
        }
      }
    }

    let armorSlot: EquipmentSlot | null = null;
    if (needArmor && exoticArmorHash != null) {
      const armorMatch = armor.find((a) => a.hash === exoticArmorHash);
      if (armorMatch) {
        armorSlot = armorManifestSlotToEquipment(
          armorMatch.slot as ArmorSlotName,
        );
      }
    }

    return { armorSlot, weaponSlotByHash };
  } catch {
    for (const hash of uniqueWeapons) {
      weaponSlotByHash.set(hash, "primary");
    }
    return {
      armorSlot: exoticArmorHash != null ? "chest" : null,
      weaponSlotByHash,
    };
  }
}
