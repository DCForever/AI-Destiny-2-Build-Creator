import type {
  ArtifactRecord,
  AspectRecord,
  ExoticArmorRecord,
  ExoticWeaponRecord,
  FragmentRecord,
  OriginTraitRecord,
  PerkRecord,
  SetBonusRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";
import {
  barrelMagazineHashesFromWeapons,
  shouldIgnoreWeaponPerkForKeywords,
} from "@/lib/synergies/ignoreWeaponStatPerks";
import type { ObjectTextRecord } from "@/lib/synergies/keywordScan";

/**
 * Stores used to discover missing synergy type keywords.
 * Deliberately limited to the user-specified sources — not legendary weapon
 * bodies, mods, or subclass abilities. Legendary weapons are only used to
 * identify barrel/magazine perk hashes to exclude.
 */
export type ObjectTextStores = {
  /** Origin traits / origin perks */
  originTraits: OriginTraitRecord[];
  /** Armor set bonuses (2pc/4pc perk text) */
  setBonuses: SetBonusRecord[];
  /** Legendary/exotic weapon trait perks (barrels/mags filtered out) */
  weaponPerks: PerkRecord[];
  aspects: AspectRecord[];
  fragments: FragmentRecord[];
  exoticArmor: ExoticArmorRecord[];
  exoticWeapons: ExoticWeaponRecord[];
  /** Seasonal / Artifact 2.0 trees and perks */
  artifacts: ArtifactRecord[];
  /**
   * Legendary weapons — not scanned for keyword text; used only to mark
   * barrel (col 0) and magazine (col 1) perk hashes to ignore.
   */
  weapons?: WeaponRecord[];
};

/**
 * Flatten text from the allowed object kinds only:
 * Origin perks, armor set bonuses, weapon perks, aspect/fragment descriptions,
 * exotic armor description, exotic weapon intrinsic + catalyst, artifacts.
 */
export function collectObjectTexts(stores: ObjectTextStores): ObjectTextRecord[] {
  const out: ObjectTextRecord[] = [];
  const barrelMagHashes = barrelMagazineHashesFromWeapons(stores.weapons ?? []);

  for (const t of stores.originTraits) {
    out.push({
      store: "origin-traits",
      hash: t.hash,
      name: t.name,
      description: t.description ?? "",
    });
  }

  for (const s of stores.setBonuses) {
    for (const perk of s.perks) {
      out.push({
        store: "set-bonuses",
        hash: s.hash,
        name: `${s.name} ${perk.requiredCount}pc — ${perk.name}`,
        description: perk.description ?? "",
      });
    }
  }

  for (const p of stores.weaponPerks) {
    if (shouldIgnoreWeaponPerkForKeywords(p, barrelMagHashes)) continue;
    out.push({
      store: "weapon-perks",
      hash: p.hash,
      name: p.name,
      description: p.description ?? "",
    });
  }

  for (const a of stores.aspects) {
    out.push({
      store: "aspects",
      hash: a.hash,
      name: a.name,
      description: a.description ?? "",
    });
  }

  for (const f of stores.fragments) {
    out.push({
      store: "fragments",
      hash: f.hash,
      name: f.name,
      description: f.description ?? "",
    });
  }

  for (const a of stores.exoticArmor) {
    out.push({
      store: "exotic-armor",
      hash: a.hash,
      name: a.name,
      // Description body only — intrinsic names are not keyword sources
      description: a.intrinsic?.description ?? "",
    });
  }

  for (const w of stores.exoticWeapons) {
    out.push({
      store: "exotic-weapons",
      hash: w.hash,
      name: w.name,
      // Intrinsic/catalyst description bodies only (not perk/item names or flavor)
      description: [w.intrinsic?.description, w.catalyst?.description]
        .filter(Boolean)
        .join("\n"),
    });
  }

  for (const art of stores.artifacts) {
    out.push({
      store: "artifacts",
      hash: art.hash,
      name: art.name,
      description: art.description ?? "",
    });
    for (const perk of art.perks ?? []) {
      out.push({
        store: "artifacts",
        hash: perk.hash,
        name: perk.name,
        description: perk.description ?? "",
      });
    }
  }

  return out;
}

export const KEYWORD_SCAN_STORE_LABELS = [
  "origin-traits",
  "set-bonuses",
  "weapon-perks",
  "aspects",
  "fragments",
  "exotic-armor",
  "exotic-weapons",
  "artifacts",
] as const;
