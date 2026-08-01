/**
 * Map universal catalog hits → Set placement defaults (027 T018).
 * Slot labels reuse catalog bucket strings (Kinetic/Energy/Power, Helmet/…).
 */

import type { CompositionKind, CompositionSetType } from "./compositionKinds";
import {
  ARMOR_SLOTS,
  PAIR_SLOTS,
  SLOTS_BY_SET_TYPE,
  WEAPON_SLOTS,
  type SetType,
} from "@/lib/sets/schemas";

const DEFAULT_SET_TYPE: Partial<Record<CompositionKind, CompositionSetType>> = {
  weapon: "weapon",
  exotic_weapon: "weapon",
  armor: "armor",
  exotic_armor: "armor",
  mod: "mod",
};

/** Preferred default set type for create wizard (exotics default to gear set, not pair). */
export function mapCompositionKindToDefaultSetType(
  kind: CompositionKind,
): CompositionSetType | null {
  return DEFAULT_SET_TYPE[kind] ?? null;
}

/**
 * Concrete slots offered for a set type.
 * Mod sets use ARMOR_SLOTS as piece pick targets (`mods_only` storage is dynamic keys).
 */
export function slotsForSetType(type: SetType | CompositionSetType): readonly string[] {
  const allowed = SLOTS_BY_SET_TYPE[type as SetType];
  if (allowed === "mods_only") return ARMOR_SLOTS;
  return allowed;
}

const WEAPON_BUCKET_TO_SLOT: Record<string, (typeof WEAPON_SLOTS)[number]> = {
  kinetic: "primary",
  energy: "special",
  power: "heavy",
  // already set-slot names
  primary: "primary",
  special: "special",
  heavy: "heavy",
};

const ARMOR_BUCKET_TO_SLOT: Record<string, (typeof ARMOR_SLOTS)[number]> = {
  helmet: "helmet",
  gauntlets: "arms",
  arms: "arms",
  chest: "chest",
  "chest armor": "chest",
  legs: "legs",
  "leg armor": "legs",
  classitem: "class_item",
  class_item: "class_item",
  "class item": "class_item",
  "class armor": "class_item",
};

function normalizeKey(raw: string): string {
  return raw.trim().toLowerCase().replace(/[\s_-]+/g, (m) => (m.includes("_") ? "_" : " "));
}

function weaponSlotFromMeta(meta: Record<string, unknown> | undefined): string | null {
  const slot = meta?.slot;
  if (typeof slot !== "string" || !slot.trim()) return null;
  const key = normalizeKey(slot).replace(/\s+/g, "");
  // kinetic / energy / power (with optional "weapons" suffix stripped)
  const bare = key.replace(/weapons?$/, "");
  return WEAPON_BUCKET_TO_SLOT[bare] ?? WEAPON_BUCKET_TO_SLOT[key] ?? null;
}

function armorSlotFromMeta(meta: Record<string, unknown> | undefined): string | null {
  const slot = meta?.slot;
  if (typeof slot !== "string" || !slot.trim()) return null;
  const key = normalizeKey(slot);
  const compact = key.replace(/\s+/g, "");
  return (
    ARMOR_BUCKET_TO_SLOT[key] ??
    ARMOR_BUCKET_TO_SLOT[compact] ??
    ARMOR_BUCKET_TO_SLOT[key.replace(/\s+/g, "_")] ??
    null
  );
}

/**
 * Preferred set slot(s) for a hit given composition kind + hit meta.
 * Returns empty when no slot can be inferred (caller offers full type slot list).
 */
export function suggestSlotsForHit(
  kind: CompositionKind,
  meta?: Record<string, unknown>,
): string[] {
  if (kind === "weapon") {
    const w = weaponSlotFromMeta(meta);
    return w ? [w] : [];
  }

  if (kind === "exotic_weapon") {
    const w = weaponSlotFromMeta(meta);
    // Pair targets always include exotic_weapon; weapon set uses bucket slot when known.
    return w ? [w, PAIR_SLOTS[0]] : [PAIR_SLOTS[0]];
  }

  if (kind === "armor") {
    const a = armorSlotFromMeta(meta);
    return a ? [a] : [];
  }

  if (kind === "exotic_armor") {
    const a = armorSlotFromMeta(meta);
    return a ? [a, PAIR_SLOTS[1]] : [PAIR_SLOTS[1]];
  }

  if (kind === "mod") {
    // Prefer piece from slotCategory when it is an armor piece; otherwise all armor slots.
    const cat = meta?.slotCategory;
    if (typeof cat === "string" && cat.trim()) {
      const mapped = armorSlotFromMeta({ slot: cat });
      if (mapped) return [mapped];
      const key = normalizeKey(cat);
      if (key === "classitem" || key === "class_item" || key === "class item") {
        return ["class_item"];
      }
    }
    return [...ARMOR_SLOTS];
  }

  return [];
}

export type InstancePinResolution =
  | { mode: "wishlist" }
  | { mode: "auto"; instanceId: string }
  | { mode: "pick" };

/**
 * FR-018 / Option C: 0 owned → wishlist catalog identity; 1 → auto-pin; many → pick.
 */
export function resolveInstancePin(
  ownedInstances: readonly { instanceId: string }[],
): InstancePinResolution {
  if (ownedInstances.length === 0) {
    return { mode: "wishlist" };
  }
  if (ownedInstances.length === 1) {
    return { mode: "auto", instanceId: ownedInstances[0]!.instanceId };
  }
  return { mode: "pick" };
}
