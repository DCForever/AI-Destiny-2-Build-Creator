/**
 * Compact entity records projected from raw Bungie manifest tables.
 * These are the shapes stored in the derived entity stores under
 * `.cache/entities/<version>/` and served to the resolver, validator,
 * LLM tools, and UI. Display strings come from the manifest, never hardcoded.
 */

/** Bungie definition hash (uint32). */
export type Hash = number;

export type DestinyClassName = "Titan" | "Hunter" | "Warlock";

export type ElementName =
  | "Kinetic"
  | "Arc"
  | "Solar"
  | "Void"
  | "Stasis"
  | "Strand"
  | "Prismatic";

export type WeaponSlotName = "Kinetic" | "Energy" | "Power";

export type AmmoTypeName = "Primary" | "Special" | "Heavy";

export type ArmorSlotName =
  | "Helmet"
  | "Gauntlets"
  | "Chest"
  | "Legs"
  | "ClassItem";

export type AbilityKind =
  | "super"
  | "grenade"
  | "melee"
  | "classAbility"
  | "movement";

export type ModSlotCategory =
  | "helmet"
  | "arms"
  | "chest"
  | "legs"
  | "classItem"
  | "general"
  | "tuning";

export interface EntityRecordBase {
  hash: Hash;
  name: string;
  /** Normalized for lookup: lowercase, diacritics stripped, collapsed spaces. */
  searchName: string;
  /** Bungie CDN path (e.g. "/common/destiny2_content/icons/..."), if any. */
  icon: string | null;
}

export interface PerkRecord extends EntityRecordBase {
  description: string;
}

export interface ExoticArmorRecord extends EntityRecordBase {
  classType: DestinyClassName;
  slot: ArmorSlotName;
  intrinsic: { name: string; description: string };
  /** Armor 3.0 archetype display name, null for legacy Armor 2.0 pieces. */
  archetype: string | null;
  flavorText: string;
}

export interface ExoticWeaponRecord extends EntityRecordBase {
  slot: WeaponSlotName;
  element: ElementName;
  ammo: AmmoTypeName;
  /** Frame / intrinsic archetype display name (e.g. "Adaptive Frame"). */
  frame: string;
  intrinsic: { name: string; description: string };
  catalyst: { name: string; description: string } | null;
  flavorText: string;
}

export interface WeaponPerkColumn {
  /** 0-based perk column index (barrels, magazines, trait 1, trait 2...). */
  column: number;
  curated: Hash[];
  randomized: Hash[];
}

/** Legendary weapon with pre-computed perk pools (hashes into weapon-perks). */
export interface WeaponRecord extends EntityRecordBase {
  slot: WeaponSlotName;
  element: ElementName;
  ammo: AmmoTypeName;
  frame: string;
  /** Weapon type display name (e.g. "Auto Rifle", "Sword"). */
  itemTypeName: string;
  originTraitHashes: Hash[];
  perkColumns: WeaponPerkColumn[];
}

export interface OriginTraitRecord extends PerkRecord {}

export interface ArtifactPerkRecord extends PerkRecord {
  /** 0-based column within the artifact grid. */
  column: number;
  /** 0-based row within the column. */
  row: number;
}

/** One of the seven permanent Artifacts 2.0 artifacts. */
export interface ArtifactRecord extends EntityRecordBase {
  description: string;
  perks: ArtifactPerkRecord[];
}

export interface AspectRecord extends EntityRecordBase {
  description: string;
  classType: DestinyClassName | null;
  element: ElementName;
  fragmentCapacity: number;
}

export interface FragmentRecord extends EntityRecordBase {
  description: string;
  element: ElementName;
  /** Stat adjustments granted, by stat display name (e.g. { Melee: 10 }). */
  statModifiers: Record<string, number>;
}

export interface AbilityRecord extends EntityRecordBase {
  description: string;
  kind: AbilityKind;
  classType: DestinyClassName | null;
  element: ElementName;
}

export interface ModRecord extends EntityRecordBase {
  description: string;
  slotCategory: ModSlotCategory;
  energyCost: number | null;
}

/** Armor 3.0 set bonus (DestinyEquipableItemSetDefinition). */
export interface SetBonusRecord extends EntityRecordBase {
  perks: { requiredCount: number; name: string; description: string }[];
  itemHashes: Hash[];
}
