/**
 * Function-based grouping + intelligent sort for armor mod search results.
 */

import {
  isModLegalForArmorSlot,
  modCategoryForArmorSlot,
} from "@/lib/builds/modEnergy";
import { compareDisplayName } from "@/lib/sortByName";

export type ModFunctionKey =
  | "ammo"
  | "orbs"
  | "armorCharge"
  | "weapons"
  | "abilities"
  | "defense"
  | "stats"
  | "siphon"
  | "finisher"
  | "other"
  | "deprecated";

export type ModSearchItem = {
  hash: number;
  name: string;
  description?: string | null;
  slotCategory?: string | null;
  energyCost?: number | null;
  icon?: string | null;
  [key: string]: unknown;
};

export type ModSearchGroup = {
  key: ModFunctionKey;
  label: string;
  items: ModSearchItem[];
};

const FUNCTION_ORDER: ModFunctionKey[] = [
  "ammo",
  "orbs",
  "armorCharge",
  "weapons",
  "abilities",
  "defense",
  "stats",
  "siphon",
  "finisher",
  "other",
  "deprecated",
];

const FUNCTION_LABEL: Record<ModFunctionKey, string> = {
  ammo: "Ammo & reserves",
  orbs: "Orbs of Power",
  armorCharge: "Armor Charge",
  weapons: "Weapons",
  abilities: "Abilities",
  defense: "Defense",
  stats: "Stats",
  siphon: "Siphon",
  finisher: "Finishers",
  other: "Other",
  deprecated: "Deprecated",
};

/** Ordered keyword rules — first match wins. */
export function classifyModFunction(
  name: string,
  description?: string | null,
): ModFunctionKey {
  const t = `${name} ${description ?? ""}`.toLowerCase();

  if (
    /deprecat|no longer function|empty mod socket|no mod currently selected/.test(
      t,
    )
  ) {
    return "deprecated";
  }
  if (/\b(ammo finder|scavenger|reserves)\b/.test(t)) return "ammo";
  // Armor Charge before orbs: many charge mods mention collecting Orbs of Power.
  if (
    /\barmor charge\b|\btemporary armor charge\b|\bweapon surge\b|\bempowering finish\b|\btime dilation\b|\bstack(?:s|ing)? of armor charge\b/.test(
      t,
    ) ||
    (/\bfont\b/.test(t) && /\b(health|melee|grenade|class|super|weapon)\b/.test(t))
  ) {
    return "armorCharge";
  }
  if (
    /\borbs? of restoration\b|\bcreate orbs?\b|\bgenerate orbs?\b|\borbs? of power on\b|\bpick(?:ing)? up orbs?\b/.test(
      t,
    ) ||
    (/\borbs? of power\b/.test(t) && !/\barmor charge\b/.test(t))
  ) {
    return "orbs";
  }
  if (/\bsiphon\b/.test(t)) return "siphon";
  if (/\bfinisher\b/.test(t)) return "finisher";
  if (
    /\b(loader|dexterity|targeting|unflinching|holster)\b/.test(t) ||
    (/\b(reload|handling|stability|range|airborne|target acquisition)\b/.test(t) &&
      /\b(weapon|kinetic|energy|power|primary|special|heavy|auto|hand cannon|shotgun|sniper|fusion|bow|sidearm|smg|machine gun|rocket|grenade launcher|sword|glaive|trace)\b/.test(
        t,
      ))
  ) {
    return "weapons";
  }
  if (
    /\b(kickstart|ability energy|grenade energy|melee energy|super energy|class ability)\b/.test(
      t,
    ) ||
    (/\b(grenade|melee|super)\b/.test(t) &&
      /\b(regen|recharge|energy|cooldown)\b/.test(t))
  ) {
    return "abilities";
  }
  if (
    /\b(damage resistance|resistance|incoming damage|flinch resistance|damage resist)\b/.test(
      t,
    )
  ) {
    return "defense";
  }
  if (
    /\b(\+\d+|mobility|recovery|discipline|intellect|strength)\b/.test(t) ||
    (/\bfont\b/.test(t) && !/\barmor charge\b/.test(t))
  ) {
    return "stats";
  }
  return "other";
}

function energySortKey(cost: number | null | undefined): number {
  if (typeof cost === "number" && Number.isFinite(cost)) return cost;
  return 999;
}

function isLegalForTarget(
  item: ModSearchItem,
  targetArmorSlot: string | null | undefined,
): boolean {
  if (!targetArmorSlot) return true;
  return isModLegalForArmorSlot(targetArmorSlot, item.slotCategory);
}

/**
 * DIM-style dedupe: same display name + slot category often has a cheap
 * artifact discount variant and a normal higher-cost plug. Keep the **higher
 * energy cost** as the canonical mod.
 */
export function dedupeModVariantsByNameAndSlot<
  T extends {
    hash: number;
    name: string;
    energyCost?: number | null;
    slotCategory?: string | null;
  },
>(items: T[]): T[] {
  const best = new Map<string, T>();
  for (const item of items) {
    const key = `${item.name.trim().toLowerCase()}\0${item.slotCategory ?? ""}`;
    const prev = best.get(key);
    if (!prev) {
      best.set(key, item);
      continue;
    }
    const cost = item.energyCost;
    const prevCost = prev.energyCost;
    const c = typeof cost === "number" ? cost : Number.NEGATIVE_INFINITY;
    const p = typeof prevCost === "number" ? prevCost : Number.NEGATIVE_INFINITY;
    if (c > p) {
      best.set(key, item);
    } else if (c === p && item.hash < prev.hash) {
      // Stable pick when costs match
      best.set(key, item);
    }
  }
  return [...best.values()];
}

/**
 * Group mods by function; sort within groups by energy, name.
 * When `targetArmorSlot` is set, **only** legal plugs for that piece are kept
 * (matching slot category, or general / tuning) — search respects the fill slot.
 */
export function groupAndSortModSearchResults(
  items: ModSearchItem[],
  opts?: {
    targetArmorSlot?: string | null;
    hideDeprecated?: boolean;
    /**
     * When true (default if targetArmorSlot set), drop plugs illegal for the piece.
     * Set false to only deprioritize illegal rows (legacy behavior).
     */
    onlyLegalForSlot?: boolean;
  },
): ModSearchGroup[] {
  const hideDeprecated = opts?.hideDeprecated !== false;
  const targetSlot = opts?.targetArmorSlot ?? null;
  const onlyLegal =
    opts?.onlyLegalForSlot ?? (targetSlot != null && targetSlot !== "");

  const deduped = dedupeModVariantsByNameAndSlot(items);

  const buckets = new Map<ModFunctionKey, ModSearchItem[]>();
  for (const key of FUNCTION_ORDER) buckets.set(key, []);

  for (const item of deduped) {
    if (onlyLegal && targetSlot && !isLegalForTarget(item, targetSlot)) {
      continue;
    }
    const key = classifyModFunction(item.name, item.description);
    if (hideDeprecated && key === "deprecated") continue;
    buckets.get(key)!.push(item);
  }

  for (const list of buckets.values()) {
    list.sort((a, b) => {
      if (targetSlot && !onlyLegal) {
        const la = isLegalForTarget(a, targetSlot) ? 0 : 1;
        const lb = isLegalForTarget(b, targetSlot) ? 0 : 1;
        if (la !== lb) return la - lb;
      }
      const ea = energySortKey(a.energyCost);
      const eb = energySortKey(b.energyCost);
      if (ea !== eb) return ea - eb;
      return compareDisplayName(a.name, b.name);
    });
  }

  const groups: ModSearchGroup[] = [];
  for (const key of FUNCTION_ORDER) {
    const list = buckets.get(key) ?? [];
    if (list.length === 0) continue;
    groups.push({
      key,
      label: FUNCTION_LABEL[key],
      items: list,
    });
  }
  return groups;
}

/** Human label for slotCategory on rows. */
export function modSlotCategoryLabel(
  slotCategory: string | null | undefined,
): string | null {
  if (!slotCategory) return null;
  switch (slotCategory) {
    case "helmet":
      return "Helmet";
    case "arms":
      return "Arms";
    case "chest":
      return "Chest";
    case "legs":
      return "Legs";
    case "classItem":
      return "Class item";
    case "general":
      return "Any armor";
    case "tuning":
      return "Tuning";
    default:
      return slotCategory;
  }
}

/** Map set armor slot → category for docs/tests. */
export function targetSlotToCategory(targetArmorSlot: string | null | undefined) {
  return targetArmorSlot ? modCategoryForArmorSlot(targetArmorSlot) : null;
}
