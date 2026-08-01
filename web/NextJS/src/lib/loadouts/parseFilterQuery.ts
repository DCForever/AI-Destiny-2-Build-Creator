import type { ArmorSlotName, WeaponSlotName } from "@/lib/manifest/types/records";

import { armorSlotSchema, filterModeSchema, weaponSlotSchema } from "./schemas";
import type { ExoticFilterCriteria } from "./types";

export class InvalidLoadoutFilterError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidLoadoutFilterError";
  }
}

function parsePositiveInt(raw: string | null): number | undefined {
  if (!raw) return undefined;
  const n = Number(raw);
  if (!Number.isInteger(n) || n <= 0) {
    throw new InvalidLoadoutFilterError("INVALID_FILTER");
  }
  return n;
}

function parseArmorFilter(params: URLSearchParams): ExoticFilterCriteria["armor"] {
  const modeRaw = params.get("armorMode");
  if (!modeRaw) return undefined;

  const mode = filterModeSchema.safeParse(modeRaw);
  if (!mode.success) throw new InvalidLoadoutFilterError("INVALID_FILTER");

  if (mode.data === "exact") {
    const hash = parsePositiveInt(params.get("armorHash"));
    const name = params.get("armorName")?.trim() || undefined;
    if (hash === undefined && !name) {
      throw new InvalidLoadoutFilterError("INVALID_FILTER");
    }
    return { mode: "exact", hash, name };
  }

  const slotRaw = params.get("armorSlot");
  const slot = armorSlotSchema.safeParse(slotRaw);
  if (!slot.success) throw new InvalidLoadoutFilterError("INVALID_FILTER");
  return { mode: "slot", slot: slot.data as ArmorSlotName };
}

function parseWeaponFilter(params: URLSearchParams): ExoticFilterCriteria["weapon"] {
  const modeRaw = params.get("weaponMode");
  if (!modeRaw) return undefined;

  const mode = filterModeSchema.safeParse(modeRaw);
  if (!mode.success) throw new InvalidLoadoutFilterError("INVALID_FILTER");

  if (mode.data === "exact") {
    const hash = parsePositiveInt(params.get("weaponHash"));
    const name = params.get("weaponName")?.trim() || undefined;
    if (hash === undefined && !name) {
      throw new InvalidLoadoutFilterError("INVALID_FILTER");
    }
    return { mode: "exact", hash, name };
  }

  const slotRaw = params.get("weaponSlot");
  const slot = weaponSlotSchema.safeParse(slotRaw);
  if (!slot.success) throw new InvalidLoadoutFilterError("INVALID_FILTER");
  return { mode: "slot", slot: slot.data as WeaponSlotName };
}

export function parseLoadoutFilterQuery(params: URLSearchParams): ExoticFilterCriteria {
  const armor = parseArmorFilter(params);
  const weapon = parseWeaponFilter(params);
  return { armor, weapon };
}

export function hasActiveFilter(criteria: ExoticFilterCriteria): boolean {
  return criteria.armor != null || criteria.weapon != null;
}
