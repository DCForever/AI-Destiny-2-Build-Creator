/**
 * Server-only: map synergy designations to official Bungie icon paths.
 * Client code must use designationIconShared + /api/catalog/designation-icons
 * (never import this module from "use client" graphs).
 */

import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { SYNERGY_VERB_NAMES } from "@/data/synergyVerbs";
import { getServices } from "@/lib/services";
import {
  designationIconKey,
  indexDamageTypeIcons,
  indexEntityIcons,
  indexInventoryItemIcons,
  lookupIconByName,
  putDesignationNameIcon,
  resolveDesignationFromIndex,
  type DesignationIconMap,
  type DesignationIconResult,
  type DesignationRef,
} from "@/lib/synergies/designationIconShared";
import {
  isWeaponFrameName,
  isWeaponTypeName,
} from "@/lib/synergies/weaponArchetypeSubType";

export type {
  DesignationIconMap,
  DesignationIconResult,
  DesignationRef,
} from "@/lib/synergies/designationIconShared";
export {
  DESIGNATION_ICON_NAME_ALIASES,
  designationIconKey,
  indexDamageTypeIcons,
  indexEntityIcons,
  indexInventoryItemIcons,
  lookupIconByName,
  resolveDesignationFromIndex,
} from "@/lib/synergies/designationIconShared";

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

  for (const w of weapons) {
    if (w.frame) {
      if (!lookupIconByName(byName, w.frame) && w.icon) {
        putDesignationNameIcon(byName, w.frame, w.icon, "weapon-frame");
      }
    }
    if (w.itemTypeName && w.icon) {
      if (!lookupIconByName(byName, w.itemTypeName)) {
        putDesignationNameIcon(byName, w.itemTypeName, w.icon, "weapon-type");
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
    const missingHunt = [...hunt].filter((n) => !lookupIconByName(byName, n));
    if (missingHunt.length > 0) {
      try {
        const itemTable = await manifest.loadRawTable(
          version,
          "DestinyInventoryItemDefinition",
        );
        indexInventoryItemIcons(itemTable, missingHunt, byName);

        const frameNames = missingHunt.filter((n) => isWeaponFrameName(n));
        if (frameNames.length) {
          indexInventoryItemIcons(itemTable, frameNames, byName);
        }
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
