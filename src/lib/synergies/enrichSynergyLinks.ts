import { getServices } from "@/lib/services";
import type { SynergyLinkRecord, SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";

export type SynergyLinkWithDescription = SynergyLinkRecord & {
  /** Catalog / manifest description of the linked object, when found. */
  description: string;
};

export type SynergyWithLinkDescriptions = Omit<SynergyWithLinks, "links"> & {
  links: SynergyLinkWithDescription[];
};

/**
 * Resolve display descriptions for each library link from the entity cache.
 * Missing catalog rows get an empty description (link still shown by name).
 */
export async function enrichSynergyLinks(
  links: SynergyLinkRecord[],
): Promise<SynergyLinkWithDescription[]> {
  if (links.length === 0) return [];

  const kinds = new Set(links.map((l) => l.kind));
  const { entityCache } = await getServices();

  const [weapons, exoticWeapons, perks, traits, setBonuses] = await Promise.all([
    kinds.has("weapon") ? entityCache.getStore("weapons") : Promise.resolve([]),
    kinds.has("weapon")
      ? entityCache.getStore("exotic-weapons")
      : Promise.resolve([]),
    kinds.has("weapon_perk")
      ? entityCache.getStore("weapon-perks")
      : Promise.resolve([]),
    kinds.has("origin_trait")
      ? entityCache.getStore("origin-traits")
      : Promise.resolve([]),
    kinds.has("armor_set_bonus")
      ? entityCache.getStore("set-bonuses")
      : Promise.resolve([]),
  ]);

  const legendaryByHash = new Map(weapons.map((w) => [w.hash, w] as const));
  const exoticByHash = new Map(exoticWeapons.map((w) => [w.hash, w] as const));
  const perkByHash = new Map(perks.map((p) => [p.hash, p] as const));
  const traitByHash = new Map(traits.map((t) => [t.hash, t] as const));
  const traitByName = new Map(
    traits.map((t) => [t.name.trim().toLowerCase(), t] as const),
  );

  return links.map((link) => {
    let description = "";
    switch (link.kind) {
      case "weapon": {
        if (link.itemHash != null) {
          const exotic = exoticByHash.get(link.itemHash);
          if (exotic) {
            // Exotic body text is the intrinsic; flavor is lore-only noise.
            description =
              exotic.intrinsic?.description?.trim() ||
              exotic.catalyst?.description?.trim() ||
              "";
          } else {
            const legendary = legendaryByHash.get(link.itemHash);
            // Legendary compact records have no long description; show frame.
            description = legendary?.frame?.trim()
              ? `${legendary.itemTypeName} · ${legendary.frame}`
              : "";
          }
        }
        break;
      }
      case "weapon_perk": {
        if (link.perkHash != null) {
          description = perkByHash.get(link.perkHash)?.description?.trim() ?? "";
        }
        break;
      }
      case "origin_trait": {
        const trait =
          (link.originTraitHash != null
            ? traitByHash.get(link.originTraitHash)
            : undefined) ??
          (link.originTraitName
            ? traitByName.get(link.originTraitName.trim().toLowerCase())
            : undefined) ??
          traitByName.get(link.displayName.trim().toLowerCase());
        description = trait?.description?.trim() ?? "";
        break;
      }
      case "armor_set_bonus": {
        const setName = (link.armorSetName ?? "").trim().toLowerCase();
        const set =
          (link.armorSetHash != null
            ? setBonuses.find((s) => s.hash === link.armorSetHash)
            : undefined) ??
          setBonuses.find((s) => s.name.trim().toLowerCase() === setName);
        if (set && link.bonusPieces != null) {
          const bonusName = (link.bonusName ?? "").trim().toLowerCase();
          const perk =
            set.perks.find(
              (p) =>
                p.requiredCount === link.bonusPieces &&
                p.name.trim().toLowerCase() === bonusName,
            ) ??
            set.perks.find((p) => p.requiredCount === link.bonusPieces);
          description = perk?.description?.trim() ?? "";
        }
        break;
      }
      default:
        break;
    }
    return { ...link, description };
  });
}

export async function enrichSynergyWithLinkDescriptions(
  synergy: SynergyWithLinks,
): Promise<SynergyWithLinkDescriptions> {
  const links = await enrichSynergyLinks(synergy.links);
  return { ...synergy, links };
}
