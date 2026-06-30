import type { ConceptTagId } from "@/data/conceptTags";
import type { SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";

const SYNERGY_TYPE_TAGS: Partial<Record<string, ConceptTagId[]>> = {
  melee: ["melee"],
  grenade: ["grenade"],
  super: ["super"],
  healing: ["healing"],
  dps: ["dps"],
  damage: ["dps"],
  solo: ["solo"],
  damage_resist: ["survival"],
  team: ["support"],
  verb: ["ability"],
  element: ["ability"],
  primary_weapon: ["kinetic"],
  special_weapon: ["ability"],
  heavy_weapon: ["ability"],
  kinetic_weapon: ["kinetic"],
};

export type MergedRollContext = {
  synergies: Array<{ id: string; name: string; type: string }>;
  perkHashes: number[];
  originTraitHashes: number[];
  weaponHashes: number[];
  weaponArchetypeSubTypes: string[];
  tagIds: ConceptTagId[];
};

/** Equal-weight merge: every designated synergy contributes types and links. */
export function mergeSynergyContext(
  synergies: SynergyWithLinks[],
  extra?: { setTagIds?: ConceptTagId[]; buildTagIds?: ConceptTagId[] },
): MergedRollContext {
  const perkHashes = new Set<number>();
  const originTraitHashes = new Set<number>();
  const weaponHashes = new Set<number>();
  const weaponArchetypeSubTypes: string[] = [];
  const tagIds = new Set<ConceptTagId>([...(extra?.setTagIds ?? []), ...(extra?.buildTagIds ?? [])]);

  for (const synergy of synergies) {
    for (const tag of SYNERGY_TYPE_TAGS[synergy.type] ?? []) {
      tagIds.add(tag);
    }

    if (synergy.type === "weapon_archetype" && synergy.subType) {
      weaponArchetypeSubTypes.push(synergy.subType);
    }

    for (const link of synergy.links) {
      if (link.kind === "weapon_perk" && link.perkHash) perkHashes.add(link.perkHash);
      if (link.kind === "weapon" && link.itemHash) weaponHashes.add(link.itemHash);
      if (link.kind === "origin_trait" && link.originTraitHash) {
        originTraitHashes.add(link.originTraitHash);
      }
    }
  }

  return {
    synergies: synergies.map((s) => ({ id: s.id, name: s.name, type: s.type })),
    perkHashes: [...perkHashes],
    originTraitHashes: [...originTraitHashes],
    weaponHashes: [...weaponHashes],
    weaponArchetypeSubTypes,
    tagIds: [...tagIds],
  };
}
