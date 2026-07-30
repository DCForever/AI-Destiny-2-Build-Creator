/**
 * Weapon detail roll model (DBR-UI-007).
 *
 * - Selected plugs (desired or equipped)
 * - Can-roll pool from catalog perk columns (when data exists)
 * - Craft flags only when known — never invent craftable options
 *
 * Set slot rows stay icon-only; this model is for detail surfaces.
 */

import { columnIndexToLabel } from "@/lib/manifest/perkWeaponIndex";
import type { WeaponPerkColumn } from "@/lib/manifest/types/records";
import {
  entityLabelParts,
  type EntityLabelParts,
} from "@/lib/presentation/displayName";

export type NamedPlugRef = {
  hash: number;
  name?: string | null;
  /** Catalog marks curated drops. */
  curated?: boolean;
  isEnhanced?: boolean;
};

export type WeaponRollPlug = EntityLabelParts & {
  hash: number;
  curated?: boolean;
  isEnhanced?: boolean;
};

export type WeaponRollColumn = {
  column: number;
  label: string;
  plugs: WeaponRollPlug[];
};

export type WeaponCraftSummary = {
  /** Instance is a crafted weapon (when known). */
  isCrafted?: boolean;
  /**
   * Weapon definition is craftable (when known from data).
   * Omitted when unknown — never invent.
   */
  isCraftable?: boolean;
};

export type WeaponRollDetail = {
  selectedPlugs: WeaponRollPlug[];
  canRollColumns: WeaponRollColumn[];
  craft: WeaponCraftSummary | null;
};

function toPlug(
  hash: number,
  name: string | null | undefined,
  extra?: { curated?: boolean; isEnhanced?: boolean },
): WeaponRollPlug {
  const label = entityLabelParts({ name, hash, kind: "plug" });
  return {
    hash,
    primary: label.primary,
    footer: label.footer,
    unknown: label.unknown,
    curated: extra?.curated,
    isEnhanced: extra?.isEnhanced,
  };
}

/**
 * Build a weapon detail roll model from catalog perk columns + selected hashes.
 * Does not invent craft options; only attaches craft flags when provided.
 */
export function buildWeaponRollDetail(input: {
  perkColumns?: WeaponPerkColumn[] | null;
  /** Hash → display name (weapon-perks / origin traits). */
  perkNames?: Map<number, string> | Record<number, string> | null;
  selectedPerkHashes?: number[] | null;
  craft?: WeaponCraftSummary | null;
}): WeaponRollDetail {
  const nameOf = (hash: number): string | null => {
    if (!input.perkNames) return null;
    if (input.perkNames instanceof Map) {
      return input.perkNames.get(hash) ?? null;
    }
    return input.perkNames[hash] ?? null;
  };

  const selected = [...new Set((input.selectedPerkHashes ?? []).filter((h) => h > 0))];
  const selectedPlugs = selected.map((h) => toPlug(h, nameOf(h)));

  const canRollColumns: WeaponRollColumn[] = [];
  for (const col of input.perkColumns ?? []) {
    const curatedSet = new Set(col.curated ?? []);
    const hashes = [...new Set([...(col.curated ?? []), ...(col.randomized ?? [])])];
    if (hashes.length === 0) continue;
    const plugs = hashes.map((h) =>
      toPlug(h, nameOf(h), { curated: curatedSet.has(h) }),
    );
    canRollColumns.push({
      column: col.column,
      label: columnIndexToLabel(col.column),
      plugs,
    });
  }

  const craft = normalizeCraft(input.craft);

  return {
    selectedPlugs,
    canRollColumns,
    craft,
  };
}

function normalizeCraft(
  craft: WeaponCraftSummary | null | undefined,
): WeaponCraftSummary | null {
  if (!craft) return null;
  const out: WeaponCraftSummary = {};
  if (craft.isCrafted === true) out.isCrafted = true;
  if (craft.isCrafted === false) out.isCrafted = false;
  if (craft.isCraftable === true) out.isCraftable = true;
  if (craft.isCraftable === false) out.isCraftable = false;
  // Drop empty craft bag — unknown means omit (do not invent).
  if (out.isCrafted === undefined && out.isCraftable === undefined) return null;
  return out;
}

/** Whether detail has anything product-meaningful to show. */
export function weaponRollDetailHasContent(detail: WeaponRollDetail): boolean {
  return (
    detail.selectedPlugs.length > 0 ||
    detail.canRollColumns.length > 0 ||
    detail.craft != null
  );
}
