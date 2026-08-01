/**
 * Set package minimum occupancy (DBR-CMP-008–010, BR-SLOT-011–014).
 *
 * - Weapon / Armor: ≥2 occupied domain slots on save/attach (when not empty scaffold)
 * - Mod: mods on ≥2 distinct armor pieces
 * - Pair: both exotic weapon and exotic armor
 * - Fashion: no combat min (always ok)
 *
 * Empty sets are allowed for in-progress create/finish attach (scaffold).
 * Partial sets (non-empty but below min) fail hard checks.
 */

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  ARMOR_SLOTS,
  isLegacyModSetSlot,
  modSetArmorSlotOf,
  PAIR_SLOTS,
  type SetType,
  WEAPON_SLOTS,
} from "@/lib/sets/schemas";

export type OccupancyItem = {
  slot: string;
  /** Soft-removed rows are ignored when filtered by caller. */
  removedAt?: string | null;
};

export type SetOccupancyResult =
  | {
      ok: true;
      empty: boolean;
      count: number;
      required: number;
      setType: SetType;
    }
  | {
      ok: false;
      empty: boolean;
      count: number;
      required: number;
      setType: SetType;
      code:
        | typeof API_ERROR_CODES.SET_MIN_ITEMS
        | typeof API_ERROR_CODES.MOD_SET_MIN_SLOTS
        | typeof API_ERROR_CODES.PAIR_INCOMPLETE;
      message: string;
    };

function activeItems(items: OccupancyItem[]): OccupancyItem[] {
  return items.filter((i) => !i.removedAt);
}

/** Count filled domain slots for weapon/armor (one item per slot). */
export function countWeaponOrArmorItems(
  setType: "weapon" | "armor",
  items: OccupancyItem[],
): number {
  const domain = setType === "weapon" ? WEAPON_SLOTS : ARMOR_SLOTS;
  const occupied = new Set<string>();
  for (const item of activeItems(items)) {
    if ((domain as readonly string[]).includes(item.slot)) {
      occupied.add(item.slot);
    }
  }
  return occupied.size;
}

/**
 * Distinct armor pieces that have ≥1 mod plug.
 * Preferred keys `helmet:hash`; bare armor slots count; legacy `mod`/`mod:hash`
 * without piece map count as a single synthetic piece (still one piece).
 */
export function countModPieces(items: OccupancyItem[]): number {
  const pieces = new Set<string>();
  let hasLegacy = false;
  for (const item of activeItems(items)) {
    const armor = modSetArmorSlotOf(item.slot);
    if (armor) {
      pieces.add(armor);
      continue;
    }
    if (isLegacyModSetSlot(item.slot)) {
      hasLegacy = true;
    }
  }
  if (hasLegacy) pieces.add("__legacy_mod__");
  return pieces.size;
}

export function countPairSlots(items: OccupancyItem[]): {
  exoticWeapon: boolean;
  exoticArmor: boolean;
  count: number;
} {
  let exoticWeapon = false;
  let exoticArmor = false;
  for (const item of activeItems(items)) {
    if (item.slot === "exotic_weapon") exoticWeapon = true;
    if (item.slot === "exotic_armor") exoticArmor = true;
  }
  return {
    exoticWeapon,
    exoticArmor,
    count: (exoticWeapon ? 1 : 0) + (exoticArmor ? 1 : 0),
  };
}

/**
 * Evaluate whether a set meets package minimum occupancy.
 * Empty scaffold → ok (in-progress / finish attach).
 * Partial → not ok with code.
 */
export function evaluateSetMinimumOccupancy(
  setType: SetType,
  items: OccupancyItem[],
): SetOccupancyResult {
  if (setType === "fashion") {
    return {
      ok: true,
      empty: activeItems(items).length === 0,
      count: activeItems(items).length,
      required: 0,
      setType,
    };
  }

  if (setType === "weapon" || setType === "armor") {
    const count = countWeaponOrArmorItems(setType, items);
    const required = 2;
    if (count === 0) {
      return { ok: true, empty: true, count: 0, required, setType };
    }
    if (count < required) {
      return {
        ok: false,
        empty: false,
        count,
        required,
        setType,
        code: API_ERROR_CODES.SET_MIN_ITEMS,
        message: `${setType === "weapon" ? "Weapon" : "Armor"} set needs at least ${required} items (has ${count})`,
      };
    }
    return { ok: true, empty: false, count, required, setType };
  }

  if (setType === "mod") {
    const count = countModPieces(items);
    const required = 2;
    if (count === 0) {
      return { ok: true, empty: true, count: 0, required, setType };
    }
    if (count < required) {
      return {
        ok: false,
        empty: false,
        count,
        required,
        setType,
        code: API_ERROR_CODES.MOD_SET_MIN_SLOTS,
        message: `Mod set needs mods on at least ${required} armor pieces (has ${count})`,
      };
    }
    return { ok: true, empty: false, count, required, setType };
  }

  // pair
  const pair = countPairSlots(items);
  const required = 2;
  if (pair.count === 0) {
    return { ok: true, empty: true, count: 0, required, setType };
  }
  if (!pair.exoticWeapon || !pair.exoticArmor) {
    return {
      ok: false,
      empty: false,
      count: pair.count,
      required,
      setType,
      code: API_ERROR_CODES.PAIR_INCOMPLETE,
      message: "Pair set needs both an exotic weapon and an exotic armor",
    };
  }
  return { ok: true, empty: false, count: pair.count, required, setType };
}

/** Hard throw for attach / composition gates. */
export function assertSetMinimumOccupancy(
  setType: SetType,
  items: OccupancyItem[],
  opts?: { context?: string },
): void {
  const result = evaluateSetMinimumOccupancy(setType, items);
  if (result.ok) return;
  throw new ApiError(
    result.code,
    result.message,
    {
      setType,
      count: result.count,
      required: result.required,
      context: opts?.context,
    },
    400,
  );
}

/** True when empty scaffold (in-progress) or meets min. */
export function setOccupancyAllowsAttach(
  setType: SetType,
  items: OccupancyItem[],
): boolean {
  return evaluateSetMinimumOccupancy(setType, items).ok;
}

/** Used when removing items from an already-attached set: remaining must not be partial. */
export function setOccupancyAllowsAttachedMutation(
  setType: SetType,
  itemsAfterMutation: OccupancyItem[],
): SetOccupancyResult {
  return evaluateSetMinimumOccupancy(setType, itemsAfterMutation);
}

export { PAIR_SLOTS, WEAPON_SLOTS, ARMOR_SLOTS };
