import { getServices } from "@/lib/services";
import type { SynergyLinkRecord, SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";

export type SynergyLinkWithDescription = SynergyLinkRecord & {
  /** Catalog / manifest description of the linked object, when found. */
  description: string;
  /** Bungie relative icon path when found on the linked entity. */
  icon: string | null;
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

  const [weapons, exoticWeapons, perks, traits, setBonuses, exoticArmor, artifacts] =
    await Promise.all([
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
      kinds.has("exotic_armor")
        ? entityCache.getStore("exotic-armor")
        : Promise.resolve([]),
      kinds.has("artifact_perk")
        ? entityCache.getStore("artifacts")
        : Promise.resolve([]),
    ]);

  const legendaryByHash = new Map(weapons.map((w) => [w.hash, w] as const));
  const exoticByHash = new Map(exoticWeapons.map((w) => [w.hash, w] as const));
  const perkByHash = new Map(perks.map((p) => [p.hash, p] as const));
  const traitByHash = new Map(traits.map((t) => [t.hash, t] as const));
  const traitByName = new Map(
    traits.map((t) => [t.name.trim().toLowerCase(), t] as const),
  );
  const exoticArmorByHash = new Map(exoticArmor.map((a) => [a.hash, a] as const));
  const artifactPerkByHash = new Map(
    artifacts.flatMap((art) =>
      (art.perks ?? []).map((p) => [p.hash, { perk: p, art }] as const),
    ),
  );

  return links.map((link) => {
    let description = "";
    let icon: string | null = null;
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
            icon = exotic.icon ?? null;
          } else {
            const legendary = legendaryByHash.get(link.itemHash);
            // Legendary compact records have no long description; show frame.
            description = legendary?.frame?.trim()
              ? `${legendary.itemTypeName} · ${legendary.frame}`
              : "";
            icon = legendary?.icon ?? null;
          }
        }
        break;
      }
      case "weapon_perk": {
        if (link.perkHash != null) {
          const perk = perkByHash.get(link.perkHash);
          description = perk?.description?.trim() ?? "";
          icon = perk?.icon ?? null;
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
        icon = trait?.icon ?? null;
        break;
      }
      case "armor_set_bonus": {
        const setName = (link.armorSetName ?? "").trim().toLowerCase();
        const set =
          (link.armorSetHash != null
            ? setBonuses.find((s) => s.hash === link.armorSetHash)
            : undefined) ??
          setBonuses.find((s) => s.name.trim().toLowerCase() === setName);
        if (set) {
          icon = set.icon ?? null;
          if (link.bonusPieces != null) {
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
        }
        break;
      }
      case "exotic_armor": {
        if (link.itemHash != null) {
          const armor = exoticArmorByHash.get(link.itemHash);
          description = armor?.intrinsic?.description?.trim() ?? "";
          icon = armor?.icon ?? null;
        }
        break;
      }
      case "artifact_perk": {
        if (link.perkHash != null) {
          const hit = artifactPerkByHash.get(link.perkHash);
          const body = hit?.perk.description?.trim() ?? "";
          const from =
            hit?.perk.artifactName?.trim() ||
            hit?.art.name?.trim() ||
            "";
          description = from
            ? body
              ? `${from} — ${body}`
              : from
            : body;
          icon = hit?.perk.icon ?? hit?.art.icon ?? null;
        }
        break;
      }
      default:
        break;
    }
    return { ...link, description, icon };
  });
}

export async function enrichSynergyWithLinkDescriptions(
  synergy: SynergyWithLinks,
): Promise<SynergyWithLinkDescriptions> {
  const links = await enrichSynergyLinks(synergy.links);
  return { ...synergy, links };
}
