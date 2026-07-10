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
  try {
    const { entityCache } = await getServices();
    let weaponSlot: EquipmentSlot | null = null;
    let armorSlot: EquipmentSlot | null = null;

    if (exoticWeaponHash) {
      const exotics = await entityCache.getStore("exotic-weapons");
      const match = exotics.find((w) => w.hash === exoticWeaponHash);
      if (match) weaponSlot = weaponManifestSlotToEquipment(match.slot as WeaponSlotName);
    }

    if (exoticArmorHash) {
      const armor = await entityCache.getStore("exotic-armor");
      const armorMatch = armor.find((a) => a.hash === exoticArmorHash);
      if (armorMatch) {
        armorSlot = armorManifestSlotToEquipment(armorMatch.slot as ArmorSlotName);
      }
    }

    return { weaponSlot, armorSlot };
  } catch {
    return {
      weaponSlot: exoticWeaponHash ? "primary" : null,
      armorSlot: exoticArmorHash ? "chest" : null,
    };
  }
}
