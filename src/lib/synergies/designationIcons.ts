/**
 * Map synergy designations (type + subtype) to official Bungie icon paths.
 *
 * Resolution order:
 * 1. Curated overrides (known renames / preferred art)
 * 2. Exact name match in entity stores (abilities, perks, weapons, …)
 * 3. Inventory item table scan (verbs / frames / pickups)
 * 4. Damage-type icons for elements
 */

import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { resolveVerbSubType, SYNERGY_VERB_NAMES } from "@/data/synergyVerbs";
import { iterItems } from "@/lib/manifest/extractors/common";
import type { RawTable } from "@/lib/manifest/types/services";
import { getServices } from "@/lib/services";
import { normalizeDesignationKey } from "@/lib/synergies/existingDesignations";
import {
  isWeaponFrameName,
  isWeaponTypeName,
} from "@/lib/synergies/weaponArchetypeSubType";

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
 * Curated: designation key → icon path OR inventory item hash to resolve later.
 * Paths preferred when known; hashes resolved at index build time if present as numbers in code comments only.
 * Use name aliases that differ from in-game item names.
 */
export const DESIGNATION_ICON_NAME_ALIASES: Readonly<Record<string, string>> = {
  // Verb display name → inventory item / buff name commonly used in defs
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

function nameKeys(name: string): string[] {
  const raw = name.trim();
  if (!raw) return [];
  const keys = new Set<string>();
  keys.add(normalizeDesignationKey(raw));
  keys.add(raw.toLowerCase().replace(/\s+/g, " "));
  const alias = DESIGNATION_ICON_NAME_ALIASES[normalizeDesignationKey(raw)];
  if (alias) keys.add(normalizeDesignationKey(alias));
  // Verb canonical
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
 * Prefer items that have an icon; first match wins per name key.
 */
export function indexInventoryItemIcons(
  itemTable: RawTable,
  targetNames: readonly string[],
  byName: Map<string, { icon: string; source: string }>,
): void {
  const wanted = new Map<string, string>(); // key → original label
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

/**
 * Damage type icons for Element designations.
 */
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

  // Types without subtype: no icon
  if (!subType?.trim()) {
    return base;
  }

  let label = subType.trim();
  if (type === "verb") {
    label = resolveVerbSubType(label) ?? label;
  }

  // Weapon types (Pulse Rifle) often lack a single icon — try frame-like perks first then name
  const hit = lookupIconByName(byName, label);
  if (hit) {
    return { ...base, icon: hit.icon, source: hit.source };
  }

  // Element fallback names
  if (type === "element") {
    const elHit = lookupIconByName(byName, label);
    if (elHit) return { ...base, icon: elHit.icon, source: elHit.source };
  }

  return base;
}

/**
 * Build a full name→icon index from entity cache + optional raw tables.
 */
export async function buildDesignationNameIconIndex(opts?: {
  /** Extra names to hunt in inventory item table (verbs, frames). */
  inventoryHuntNames?: readonly string[];
}): Promise<Map<string, { icon: string; source: string }>> {
  const { entityCache, manifest } = await getServices();
  const byName = new Map<string, { icon: string; source: string }>();

  const [
    abilities,
    perks,
    traits,
    weapons,
    exoticWeapons,
    exoticArmor,
    aspects,
    fragments,
    mods,
    setBonuses,
  ] = await Promise.all([
    entityCache.getStore("abilities"),
    entityCache.getStore("weapon-perks"),
    entityCache.getStore("origin-traits"),
    entityCache.getStore("weapons"),
    entityCache.getStore("exotic-weapons"),
    entityCache.getStore("exotic-armor"),
    entityCache.getStore("aspects"),
    entityCache.getStore("fragments"),
    entityCache.getStore("mods"),
    entityCache.getStore("set-bonuses"),
  ]);

  indexEntityIcons(abilities, "abilities", byName);
  indexEntityIcons(perks, "weapon-perks", byName);
  indexEntityIcons(traits, "origin-traits", byName);
  indexEntityIcons(weapons, "weapons", byName);
  indexEntityIcons(exoticWeapons, "exotic-weapons", byName);
  indexEntityIcons(exoticArmor, "exotic-armor", byName);
  indexEntityIcons(aspects, "aspects", byName);
  indexEntityIcons(fragments, "fragments", byName);
  indexEntityIcons(mods, "mods", byName);
  indexEntityIcons(setBonuses, "set-bonuses", byName);

  // Also index weapon frame names from legendary weapons' frame field + first weapon with that frame as icon
  for (const w of weapons) {
    if (w.frame) {
      // Prefer a frame plug icon if already in byName; else use a weapon that uses the frame
      if (!lookupIconByName(byName, w.frame) && w.icon) {
        putNameIcon(byName, w.frame, w.icon, "weapon-frame");
      }
    }
    if (w.itemTypeName && w.icon) {
      if (!lookupIconByName(byName, w.itemTypeName)) {
        putNameIcon(byName, w.itemTypeName, w.icon, "weapon-type");
      }
    }
  }

  const status = await manifest.getStatus();
  if (status.cachedVersion) {
    const version = status.cachedVersion;
    try {
      const damageTable = await manifest.loadRawTable(
        version,
        "DestinyDamageTypeDefinition",
      );
      indexDamageTypeIcons(damageTable, byName);
    } catch {
      /* optional */
    }

    const hunt = new Set<string>([
      ...SYNERGY_VERB_NAMES,
      ...(opts?.inventoryHuntNames ?? []),
    ]);
    // Prefer inventory scan for any still-missing hunt names
    const missingHunt = [...hunt].filter((n) => !lookupIconByName(byName, n));
    if (missingHunt.length > 0) {
      try {
        const itemTable = await manifest.loadRawTable(
          version,
          "DestinyInventoryItemDefinition",
        );
        indexInventoryItemIcons(itemTable, missingHunt, byName);

        // Frames: collect frame plug icons from inventory (intrinsics)
        const frameNames = missingHunt.filter((n) => isWeaponFrameName(n));
        if (frameNames.length) {
          indexInventoryItemIcons(itemTable, frameNames, byName);
        }
        // Weapon types less reliable — already filled from weapons store
        void isWeaponTypeName;
      } catch {
        /* inventory table missing */
      }
    }
  }

  return byName;
}

/** Resolve many designations to icons (single index build). */
export async function resolveDesignationIcons(
  refs: DesignationRef[],
): Promise<DesignationIconResult[]> {
  const byName = await buildDesignationNameIconIndex({
    inventoryHuntNames: refs
      .map((r) => r.subType)
      .filter((s): s is string => Boolean(s?.trim())),
  });

  return refs.map((r) =>
    resolveDesignationFromIndex(r.type, r.subType, byName),
  );
}

/** Map of designationIconKey → icon path for a set of refs. */
export async function designationIconMap(
  refs: DesignationRef[],
): Promise<DesignationIconMap> {
  const results = await resolveDesignationIcons(refs);
  const map: DesignationIconMap = {};
  for (const r of results) {
    map[designationIconKey(r.type, r.subType)] = r.icon;
  }
  return map;
}

/** Preload icons for all curated verbs + elements (common UI). */
export async function curatedDesignationIconMap(): Promise<DesignationIconMap> {
  const refs: DesignationRef[] = [
    ...SYNERGY_VERB_NAMES.map((name) => ({ type: "verb", subType: name })),
    ...SYNERGY_ELEMENTS.map((name) => ({ type: "element", subType: name })),
  ];
  return designationIconMap(refs);
}
