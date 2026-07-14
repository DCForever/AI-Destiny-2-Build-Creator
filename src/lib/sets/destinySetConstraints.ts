/**
 * Pure Destiny constraints for Set composition (UI + server).
 * Slot legality uses schemas; item↔slot fitness uses caller-supplied meta.
 * Set-wide exotic exclusivity keeps kits attachable without dual-exotic surprises.
 */

import {
  isModLegalForArmorSlot,
} from "@/lib/builds/modEnergy";
import { setSlotToCatalogBucket } from "@/lib/sets/catalogSlotMap";
import {
  isLegacyModSetSlot,
  isSlotValidForSetType,
  modSetArmorSlotOf,
  type SetType,
} from "@/lib/sets/schemas";

export type SetItemKind =
  | "weapon"
  | "armor"
  | "mod"
  | "exotic_weapon"
  | "exotic_armor"
  | "unknown";

/** Minimal item identity for constraint checks (catalog or entity cache). */
export type SetItemMeta = {
  kind: SetItemKind;
  /**
   * Equipment bucket from catalog/manifest:
   * Kinetic | Energy | Power | Helmet | Gauntlets | Chest | Legs | ClassItem
   */
  equipmentSlot?: string | null;
  /** True when rarity is Exotic (weapons/armor). */
  isExotic?: boolean;
  /** Optional display name for error messages. */
  name?: string | null;
  /** Mods: helmet | arms | chest | legs | classItem | general | tuning */
  slotCategory?: string | null;
  /** Mods: armor energy cost. */
  energyCost?: number | null;
};

export type SetConstraintResult =
  | { ok: true }
  | { ok: false; reasons: string[] };

export type SetOccupant = {
  slot: string;
  meta: SetItemMeta;
};

/**
 * Hard rules: legal set slot + item kind/bucket/exotic fit for that slot.
 * Fashion is intentionally permissive (manual cosmetics).
 */
export function assertSetItemAllowed(
  setType: SetType,
  slot: string,
  meta: SetItemMeta,
): SetConstraintResult {
  const reasons: string[] = [];

  if (!isSlotValidForSetType(setType, slot)) {
    reasons.push(`Slot "${slot}" is not valid for a ${setType} set`);
    return { ok: false, reasons };
  }

  if (setType === "fashion") {
    return { ok: true };
  }

  if (setType === "weapon") {
    if (
      meta.kind === "armor" ||
      meta.kind === "exotic_armor" ||
      meta.kind === "mod"
    ) {
      reasons.push("Weapon sets only accept weapons");
    } else {
      // weapon | exotic_weapon | unknown (unknown allowed when store miss)
      const expected = setSlotToCatalogBucket(slot);
      if (expected && meta.equipmentSlot && meta.equipmentSlot !== expected) {
        reasons.push(
          `This slot requires a ${expected} weapon (got ${meta.equipmentSlot})`,
        );
      }
    }
  } else if (setType === "armor") {
    if (
      meta.kind === "weapon" ||
      meta.kind === "exotic_weapon" ||
      meta.kind === "mod"
    ) {
      reasons.push("Armor sets only accept armor");
    } else {
      // armor | exotic_armor | unknown (legendary armor not always in entity cache)
      const expected = setSlotToCatalogBucket(slot);
      if (expected && meta.equipmentSlot && meta.equipmentSlot !== expected) {
        reasons.push(
          `This slot requires ${expected} armor (got ${meta.equipmentSlot})`,
        );
      }
    }
  } else if (setType === "pair") {
    if (slot === "exotic_weapon" || slot.includes("weapon")) {
      if (!isExoticWeaponMeta(meta)) {
        reasons.push("Pair exotic weapon slot requires an exotic weapon");
      }
    } else if (!isExoticArmorMeta(meta)) {
      reasons.push("Pair exotic armor slot requires exotic armor");
    }
  } else if (setType === "mod") {
    if (meta.kind !== "mod" && meta.kind !== "unknown") {
      reasons.push("Mod sets only accept armor / combat mods");
    } else if (meta.kind === "mod" || meta.slotCategory) {
      const armorSlot = modSetArmorSlotOf(slot);
      if (armorSlot && meta.slotCategory) {
        if (!isModLegalForArmorSlot(armorSlot, meta.slotCategory)) {
          reasons.push(
            `This mod (${meta.slotCategory}) is not legal for ${armorSlot}`,
          );
        }
      } else if (!armorSlot && !isLegacyModSetSlot(slot)) {
        reasons.push(
          "Mod sets require an armor piece slot (helmet, arms, chest, legs, class item)",
        );
      }
    }
  }

  if (reasons.length > 0) return { ok: false, reasons };
  return { ok: true };
}

/**
 * Set-wide exotic exclusivity so attaching a set to a build does not
 * immediately dual-exotic (DBR-CMP-007-aligned kit hygiene).
 *
 * - **Weapon sets**: at most one exotic weapon across all slots
 * - **Armor sets**: at most one exotic armor (incl. class item) across slots
 * - **Pair**: already 0–1 exotic weapon + 0–1 exotic armor by slot model
 * - Replace of the slot that already holds the exotic is allowed
 */
export function assertSetExoticExclusivity(input: {
  setType: SetType;
  /** Other active occupants (exclude the slot being filled/replaced). */
  otherItems: SetOccupant[];
  candidate: { slot: string; meta: SetItemMeta };
}): SetConstraintResult {
  const { setType, otherItems, candidate } = input;

  if (setType === "weapon") {
    if (!isExoticWeaponMeta(candidate.meta)) return { ok: true };
    const existing = otherItems.find((o) => isExoticWeaponMeta(o.meta));
    if (!existing) return { ok: true };
    const label = existing.meta.name?.trim() || existing.slot;
    return {
      ok: false,
      reasons: [
        `This weapon set already has an exotic (${label}). Destiny allows only one exotic weapon — remove or replace that piece first.`,
      ],
    };
  }

  if (setType === "armor") {
    if (!isExoticArmorMeta(candidate.meta)) return { ok: true };
    const existing = otherItems.find((o) => isExoticArmorMeta(o.meta));
    if (!existing) return { ok: true };
    const label = existing.meta.name?.trim() || existing.slot;
    return {
      ok: false,
      reasons: [
        `This armor set already has an exotic (${label}). Destiny allows only one exotic armor — remove or replace that piece first.`,
      ],
    };
  }

  return { ok: true };
}

/** Slot fit + set-wide exotic exclusivity. */
export function assertSetCompositionAllowed(
  setType: SetType,
  slot: string,
  meta: SetItemMeta,
  otherItems: SetOccupant[] = [],
): SetConstraintResult {
  const fit = assertSetItemAllowed(setType, slot, meta);
  if (!fit.ok) return fit;
  return assertSetExoticExclusivity({
    setType,
    otherItems,
    candidate: { slot, meta },
  });
}

/** Whether this set already holds an exotic of the given kind (for catalog filters). */
export function setAlreadyHasExotic(
  setType: SetType,
  otherItems: SetOccupant[],
  kind: "weapon" | "armor",
): SetOccupant | null {
  if (kind === "weapon" && setType === "weapon") {
    return otherItems.find((o) => isExoticWeaponMeta(o.meta)) ?? null;
  }
  if (kind === "armor" && setType === "armor") {
    return otherItems.find((o) => isExoticArmorMeta(o.meta)) ?? null;
  }
  return null;
}

export function isExoticWeaponMeta(meta: SetItemMeta): boolean {
  if (meta.kind === "exotic_weapon") return true;
  if (meta.kind === "weapon" || meta.kind === "unknown") {
    return meta.isExotic === true;
  }
  return false;
}

export function isExoticArmorMeta(meta: SetItemMeta): boolean {
  if (meta.kind === "exotic_armor") return true;
  if (meta.kind === "armor" || meta.kind === "unknown") {
    return meta.isExotic === true;
  }
  return false;
}

/** Map entity-cache store names to set item kind. */
export function kindFromEntityStore(
  store:
    | "weapons"
    | "exotic-weapons"
    | "exotic-armor"
    | "mods"
    | string
    | null
    | undefined,
): SetItemKind {
  switch (store) {
    case "weapons":
      return "weapon";
    case "exotic-weapons":
      return "exotic_weapon";
    case "exotic-armor":
      return "exotic_armor";
    case "mods":
      return "mod";
    default:
      return "unknown";
  }
}

/** Build meta from a catalog pick (client fill path). */
export function setItemMetaFromCatalog(item: {
  slot?: string;
  isExotic: boolean;
  kind?: "weapons" | "armor";
}): SetItemMeta {
  if (item.kind === "armor") {
    return {
      kind: item.isExotic ? "exotic_armor" : "armor",
      equipmentSlot: item.slot ?? null,
      isExotic: item.isExotic,
    };
  }
  // weapons default
  return {
    kind: item.isExotic ? "exotic_weapon" : "weapon",
    equipmentSlot: item.slot ?? null,
    isExotic: item.isExotic,
  };
}

/** Meta for manifest exotic / mod pickers. */
export function setItemMetaFromManifestCategory(
  category: "exotic-weapons" | "exotic-armor" | "mods",
  extras?: { slotCategory?: string | null; energyCost?: number | null; name?: string },
): SetItemMeta {
  if (category === "exotic-weapons") {
    return { kind: "exotic_weapon", isExotic: true, name: extras?.name };
  }
  if (category === "exotic-armor") {
    return { kind: "exotic_armor", isExotic: true, name: extras?.name };
  }
  return {
    kind: "mod",
    slotCategory: extras?.slotCategory ?? null,
    energyCost: extras?.energyCost ?? null,
    name: extras?.name,
  };
}
