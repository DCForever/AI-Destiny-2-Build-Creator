/**
 * Shapes of the derived entity stores persisted as JSON under
 * `.cache/entities/<manifestVersion>/`. One file per store. Each store is the
 * output of exactly one extractor and is rebuilt only when the manifest
 * version changes.
 */

import type {
  AbilityRecord,
  ArtifactRecord,
  AspectRecord,
  ExoticArmorRecord,
  ExoticWeaponRecord,
  FragmentRecord,
  Hash,
  ModRecord,
  OriginTraitRecord,
  PerkRecord,
  SetBonusRecord,
  WeaponRecord,
} from "./records";

export interface EntityStores {
  "exotic-armor": ExoticArmorRecord[];
  "exotic-weapons": ExoticWeaponRecord[];
  weapons: WeaponRecord[];
  /** All perks referenced by weapon perk columns, keyed for joins. */
  "weapon-perks": PerkRecord[];
  "origin-traits": OriginTraitRecord[];
  artifacts: ArtifactRecord[];
  aspects: AspectRecord[];
  fragments: FragmentRecord[];
  abilities: AbilityRecord[];
  mods: ModRecord[];
  "set-bonuses": SetBonusRecord[];
  /** Stat display names from DestinyStatDefinition, keyed by hash. */
  stats: { hash: Hash; name: string; description: string }[];
}

export type StoreName = keyof EntityStores;

export const STORE_NAMES: readonly StoreName[] = [
  "exotic-armor",
  "exotic-weapons",
  "weapons",
  "weapon-perks",
  "origin-traits",
  "artifacts",
  "aspects",
  "fragments",
  "abilities",
  "mods",
  "set-bonuses",
  "stats",
] as const;

/** Metadata sidecar written alongside the stores. */
export interface EntityCacheMeta {
  manifestVersion: string;
  builtAt: string;
  counts: Record<StoreName, number>;
}
