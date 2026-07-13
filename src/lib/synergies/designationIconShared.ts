/**
 * Client-safe designation icon helpers (no Node/fs, no getServices).
 * Server resolution lives in designationIcons.ts.
 */

import { resolveVerbSubType } from "@/data/synergyVerbs";
import { iterItems } from "@/lib/manifest/extractors/common";
import type { RawTable } from "@/lib/manifest/types/services";
import { normalizeDesignationKey } from "@/lib/synergies/existingDesignations";

export type DesignationRef = {
  type: string;
  subType: string | null | undefined;
};

export type DesignationIconResult = DesignationRef & {
  /** Relative Bungie path, e.g. /common/destiny2_content/icons/... */
  icon: string | null;
  /** Where the icon was found (for debugging / UI hints). */
  source: string | null;
};

/** designationKey → relative icon path */
export type DesignationIconMap = Record<string, string | null>;

/**
 * Curated name aliases when designation label ≠ inventory item name.
 */
export const DESIGNATION_ICON_NAME_ALIASES: Readonly<Record<string, string>> = {
  suppress: "suppression",
  "stasis shards": "stasis shard",
  "solar firesprite": "firesprite",
  "void overshield": "overshield",
};

/** type::subtype key for maps and API. */
export function designationIconKey(
  type: string,
  subType: string | null | undefined,
): string {
  const t = type.trim().toLowerCase();
  const sub = subType?.trim() ? normalizeDesignationKey(subType) : "";
  return `${t}::${sub}`;
}

export function nameKeys(name: string): string[] {
  const raw = name.trim();
  if (!raw) return [];
  const keys = new Set<string>();
  keys.add(normalizeDesignationKey(raw));
  keys.add(raw.toLowerCase().replace(/\s+/g, " "));
  const alias = DESIGNATION_ICON_NAME_ALIASES[normalizeDesignationKey(raw)];
  if (alias) keys.add(normalizeDesignationKey(alias));
  const verb = resolveVerbSubType(raw);
  if (verb) keys.add(normalizeDesignationKey(verb));
  return [...keys];
}

function putNameIcon(
  byName: Map<string, { icon: string; source: string }>,
  name: string,
  icon: string | null | undefined,
  source: string,
): void {
  if (!icon?.trim()) return;
  for (const key of nameKeys(name)) {
    if (!byName.has(key)) {
      byName.set(key, { icon, source });
    }
  }
}

/** @internal exported for server index builders */
export function putDesignationNameIcon(
  byName: Map<string, { icon: string; source: string }>,
  name: string,
  icon: string | null | undefined,
  source: string,
): void {
  putNameIcon(byName, name, icon, source);
}

/**
 * Index entity-store records by normalized name → icon.
 */
export function indexEntityIcons(
  records: Array<{ name: string; icon?: string | null }>,
  source: string,
  byName: Map<string, { icon: string; source: string }>,
): void {
  for (const r of records) {
    putNameIcon(byName, r.name, r.icon, source);
  }
}

/**
 * Scan DestinyInventoryItemDefinition for icons matching target names.
 */
export function indexInventoryItemIcons(
  itemTable: RawTable,
  targetNames: readonly string[],
  byName: Map<string, { icon: string; source: string }>,
): void {
  const wanted = new Map<string, string>();
  for (const name of targetNames) {
    for (const key of nameKeys(name)) {
      if (!byName.has(key) && !wanted.has(key)) wanted.set(key, name);
    }
  }
  if (wanted.size === 0) return;

  for (const item of iterItems(itemTable)) {
    const icon = item.displayProperties.icon ?? null;
    if (!icon) continue;
    const itemName = item.displayProperties.name ?? "";
    for (const key of nameKeys(itemName)) {
      if (wanted.has(key) && !byName.has(key)) {
        byName.set(key, { icon, source: "inventory-item" });
        wanted.delete(key);
      }
    }
    if (wanted.size === 0) break;
  }
}

export function indexDamageTypeIcons(
  damageTable: RawTable,
  byName: Map<string, { icon: string; source: string }>,
): void {
  for (const value of Object.values(damageTable)) {
    if (typeof value !== "object" || value === null) continue;
    const def = value as {
      displayProperties?: { name?: string; icon?: string };
    };
    const name = def.displayProperties?.name;
    const icon = def.displayProperties?.icon;
    if (name && icon) {
      putNameIcon(byName, name, icon, "damage-type");
    }
  }
}

export function lookupIconByName(
  byName: Map<string, { icon: string; source: string }>,
  name: string | null | undefined,
): { icon: string; source: string } | null {
  if (!name?.trim()) return null;
  for (const key of nameKeys(name)) {
    const hit = byName.get(key);
    if (hit) return hit;
  }
  return null;
}

export function resolveDesignationFromIndex(
  type: string,
  subType: string | null | undefined,
  byName: Map<string, { icon: string; source: string }>,
): DesignationIconResult {
  const base: DesignationIconResult = {
    type,
    subType: subType?.trim() || null,
    icon: null,
    source: null,
  };

  if (!subType?.trim()) {
    return base;
  }

  let label = subType.trim();
  if (type === "verb") {
    label = resolveVerbSubType(label) ?? label;
  }

  const hit = lookupIconByName(byName, label);
  if (hit) {
    return { ...base, icon: hit.icon, source: hit.source };
  }

  if (type === "element") {
    const elHit = lookupIconByName(byName, label);
    if (elHit) return { ...base, icon: elHit.icon, source: elHit.source };
  }

  return base;
}
