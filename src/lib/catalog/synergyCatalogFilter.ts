import type { PerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import type {
  OriginTraitRecord,
  SetBonusRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";

export type SynergyCatalogLink = {
  kind: string;
  itemHash?: number | null;
  perkHash?: number | null;
  originTraitHash?: number | null;
  originTraitName?: string | null;
  armorSetName?: string | null;
  armorSetHash?: number | null;
  bonusPieces?: number | null;
  bonusName?: string | null;
};

export type SynergyCatalogRow = {
  links: SynergyCatalogLink[];
};

export type SynergyCatalogFilterDeps = {
  perkIndex: PerkWeaponIndex | null;
  weapons: WeaponRecord[];
  setBonuses: SetBonusRecord[];
  originTraits?: OriginTraitRecord[];
};

export type SynergyCatalogAllowlists = {
  weaponHashes: Set<number>;
  armorHashes: Set<number>;
  /** True when selected synergies produced no catalog-resolvable links. */
  empty: boolean;
};

function addWeaponFromPerk(
  perkHash: number,
  index: PerkWeaponIndex | null,
  out: Set<number>,
): void {
  if (!index) return;
  for (const entry of index.byPerk[String(perkHash)] ?? []) {
    out.add(entry.weaponHash);
  }
}

function addWeaponsFromOriginTrait(
  link: SynergyCatalogLink,
  weapons: WeaponRecord[],
  originTraits: OriginTraitRecord[] | undefined,
  out: Set<number>,
): void {
  const hashes = new Set<number>();
  if (link.originTraitHash != null) hashes.add(link.originTraitHash);
  const name = link.originTraitName?.trim().toLowerCase();
  if (name && originTraits) {
    for (const t of originTraits) {
      if (t.name.trim().toLowerCase() === name || t.searchName === name) {
        hashes.add(t.hash);
      }
    }
  }
  if (hashes.size === 0) return;
  for (const weapon of weapons) {
    if (weapon.originTraitHashes.some((h) => hashes.has(h))) {
      out.add(weapon.hash);
    }
  }
}

function addArmorFromSetBonus(
  link: SynergyCatalogLink,
  sets: SetBonusRecord[],
  out: Set<number>,
): void {
  const byHash =
    link.armorSetHash != null
      ? sets.find((s) => s.hash === link.armorSetHash)
      : undefined;
  const setName = link.armorSetName?.trim().toLowerCase() ?? "";
  const byName = setName
    ? sets.find((s) => s.name.trim().toLowerCase() === setName)
    : undefined;
  const set = byHash ?? byName;
  if (!set) return;
  for (const h of set.itemHashes) out.add(h);
}

/**
 * Map library synergy object links to Catalog weapon/armor hash allowlists.
 * OR across all links and all provided synergies. Ignores artifact_perk (not catalog).
 */
export function resolveSynergyCatalogAllowlists(
  synergies: SynergyCatalogRow[],
  deps: SynergyCatalogFilterDeps,
): SynergyCatalogAllowlists {
  const weaponHashes = new Set<number>();
  const armorHashes = new Set<number>();
  let sawCatalogLink = false;

  for (const synergy of synergies) {
    for (const link of synergy.links) {
      switch (link.kind) {
        case "weapon": {
          if (link.itemHash != null) {
            sawCatalogLink = true;
            weaponHashes.add(link.itemHash);
          }
          break;
        }
        case "weapon_perk": {
          if (link.perkHash != null) {
            sawCatalogLink = true;
            addWeaponFromPerk(link.perkHash, deps.perkIndex, weaponHashes);
          }
          break;
        }
        case "origin_trait": {
          if (link.originTraitHash != null || link.originTraitName) {
            sawCatalogLink = true;
            addWeaponsFromOriginTrait(
              link,
              deps.weapons,
              deps.originTraits,
              weaponHashes,
            );
          }
          break;
        }
        case "exotic_armor": {
          if (link.itemHash != null) {
            sawCatalogLink = true;
            armorHashes.add(link.itemHash);
          }
          break;
        }
        case "armor_set_bonus": {
          sawCatalogLink = true;
          addArmorFromSetBonus(link, deps.setBonuses, armorHashes);
          break;
        }
        default:
          // artifact_perk and unknown kinds: not catalog weapons/armor
          break;
      }
    }
  }

  const empty =
    !sawCatalogLink || (weaponHashes.size === 0 && armorHashes.size === 0);

  return { weaponHashes, armorHashes, empty };
}

/** Intersect two optional allowlists (AND). Undefined means “no constraint”. */
export function intersectAllowlists(
  a: Set<number> | undefined,
  b: Set<number> | undefined,
): Set<number> | undefined {
  if (!a && !b) return undefined;
  if (!a) return b;
  if (!b) return a;
  const out = new Set<number>();
  for (const h of a) {
    if (b.has(h)) out.add(h);
  }
  return out;
}
