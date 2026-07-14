/**
 * Official Bungie icon paths + tints for dense filter/meta chips.
 * Icons are relative CDN paths (https://www.bungie.net + path).
 *
 * Element: DestinyDamageTypeDefinition.
 * Ammo: Ammo Finder mod glyphs (same family DIM uses).
 * Weapon frames: intrinsic plug icons (DIM “weapon archetype”).
 * Armor archetypes: inventory trait icons (Armor 3.0).
 */

import type { CSSProperties } from "react";

import {
  CATALOG_AMMO_TYPES,
  CATALOG_ARMOR_ARCHETYPES,
} from "@/lib/catalog/filterOptions";
import type { DestinyElement } from "@/lib/destiny/identityVisuals";

export type CatalogAmmoType = (typeof CATALOG_AMMO_TYPES)[number];

export type OfficialFilterVisual = {
  /** Relative Bungie icon path */
  icon: string;
  /** Official / game-UI tint (border + active ring) */
  color: string;
};

const MUTED = "rgb(180, 180, 190)";

/** From DestinyDamageTypeDefinition.color + displayProperties.icon */
export const ELEMENT_OFFICIAL: Record<DestinyElement, OfficialFilterVisual> = {
  Kinetic: {
    icon: "/common/destiny2_content/icons/DestinyDamageTypeDefinition_3385a924fd3ccb92c343ade19f19a370.png",
    color: "rgb(255, 255, 255)",
  },
  Arc: {
    icon: "/common/destiny2_content/icons/DestinyDamageTypeDefinition_092d066688b879c807c3b460afdd61e6.png",
    color: "rgb(133, 197, 236)",
  },
  Solar: {
    icon: "/common/destiny2_content/icons/DestinyDamageTypeDefinition_2a1773e10968f2d088b97c22b22bba9e.png",
    color: "rgb(242, 114, 27)",
  },
  Void: {
    icon: "/common/destiny2_content/icons/DestinyDamageTypeDefinition_ceb2f6197dccf3958bb31cc783eb97a0.png",
    color: "rgb(177, 132, 197)",
  },
  Stasis: {
    icon: "/common/destiny2_content/icons/DestinyDamageTypeDefinition_530c4c3e7981dc2aefd24fd3293482bf.png",
    color: "rgb(77, 136, 255)",
  },
  Strand: {
    icon: "/common/destiny2_content/icons/DestinyDamageTypeDefinition_b2fe51a94f3533f97079dfa0d27a4096.png",
    color: "rgb(53, 227, 102)",
  },
  Prismatic: {
    // No damage-type definition; Prismatic subclass glyph (Hunter) is standard UI art
    icon: "/common/destiny2_content/icons/fab506e62fa4f188bfe2fb6d56b39614.png",
    color: "rgb(214, 126, 226)",
  },
};

/**
 * Ammo type colors (game language). Catalog filter chips use destiny-icons
 * SVGs via AmmoTypeIcon; `icon` remains a Bungie Ammo Finder path for meta
 * chips / fallbacks that still go through OfficialFilterIcon.
 */
export const AMMO_OFFICIAL: Record<CatalogAmmoType, OfficialFilterVisual> = {
  Primary: {
    icon: "/common/destiny2_content/icons/56761c8361e33a367c6fa94f397d8692.png",
    color: "rgb(220, 220, 220)",
  },
  Special: {
    icon: "/common/destiny2_content/icons/35e9d5635599be5c0fc306732f881459.png",
    color: "rgb(122, 193, 67)",
  },
  Heavy: {
    icon: "/common/destiny2_content/icons/fdcbb78db8f38cec62ec7ca2dbab12cc.png",
    color: "rgb(177, 132, 197)",
  },
};

/**
 * Armor 3.0 archetype trait icons (inventory itemType 19; not shaders).
 * Keys match CATALOG_ARMOR_ARCHETYPES.
 */
export const ARMOR_ARCHETYPE_OFFICIAL: Record<
  (typeof CATALOG_ARMOR_ARCHETYPES)[number],
  OfficialFilterVisual
> = {
  Bulwark: {
    icon: "/common/destiny2_content/icons/cda905547dd9eac7a39e6e898f619bc5.png",
    color: MUTED,
  },
  Brawler: {
    icon: "/common/destiny2_content/icons/7bc3bc2bccdafc19dde31f867a06ee9f.png",
    color: MUTED,
  },
  Grenadier: {
    icon: "/common/destiny2_content/icons/cbf4f03459ab2818a3d37b7362b2aa93.png",
    color: MUTED,
  },
  Specialist: {
    icon: "/common/destiny2_content/icons/69731c603d7bcdd0a21b26c711d55f03.png",
    color: MUTED,
  },
  Gunner: {
    icon: "/common/destiny2_content/icons/15e3b3c25a6d4606dcb887cb67c915a1.png",
    color: MUTED,
  },
  Paragon: {
    icon: "/common/destiny2_content/icons/b5feb81f684d767d6212ca138f30b34c.png",
    color: MUTED,
  },
};

/**
 * Weapon frame / intrinsic “archetype” icons (DIM getWeaponArchetype).
 * Keys are full display names as stored on catalog `frame`.
 */
export const WEAPON_FRAME_OFFICIAL: Record<string, OfficialFilterVisual> = {
  "Adaptive Frame": {
    icon: "/common/destiny2_content/icons/967fb4abc6ab98f74639d6c08e5f56ee.png",
    color: MUTED,
  },
  "Aggressive Frame": {
    icon: "/common/destiny2_content/icons/64209c4fd20513b33109c374179d0958.png",
    color: MUTED,
  },
  "Area Denial Frame": {
    icon: "/common/destiny2_content/icons/d1c2cea4a7325962a493283c5615d260.png",
    color: MUTED,
  },
  "Caster Frame": {
    icon: "/common/destiny2_content/icons/21cba9f6f6b34dced5a3cd8a6fd53c52.png",
    color: MUTED,
  },
  "Command Frame": {
    icon: "/common/destiny2_content/icons/7e49ea5c8547243fbd5e5d8361bcacb4.png",
    color: MUTED,
  },
  "Compressed Wave Frame": {
    icon: "/common/destiny2_content/icons/00c13147258a00b339f472516328267f.png",
    color: MUTED,
  },
  "High-Impact Frame": {
    icon: "/common/destiny2_content/icons/34573143849cf910d2381554bb57a10d.png",
    color: MUTED,
  },
  "Legacy PR-55 Frame": {
    icon: "/common/destiny2_content/icons/a3402f39212e2996a198d4c3882ef15d.png",
    color: MUTED,
  },
  "Lightweight Frame": {
    icon: "/common/destiny2_content/icons/6db8cd21c2b3e6fffeb6f111d6c70dd2.png",
    color: MUTED,
  },
  "Micro-Missile Frame": {
    icon: "/common/destiny2_content/icons/0362f949c16fe72358a5c7bb93be3f60.png",
    color: MUTED,
  },
  "Pinpoint Slug Frame": {
    icon: "/common/destiny2_content/icons/e9dd736124e8ef94048901a279a5bb18.png",
    color: MUTED,
  },
  "Precision Frame": {
    icon: "/common/destiny2_content/icons/e9dd736124e8ef94048901a279a5bb18.png",
    color: MUTED,
  },
  "Rapid-Fire Frame": {
    icon: "/common/destiny2_content/icons/801d62d1f9783bee81d5700c54c24fda.png",
    color: MUTED,
  },
  "Support Frame": {
    icon: "/common/destiny2_content/icons/922b3354dd900848ecf72bcf9e1ae022.png",
    color: MUTED,
  },
  "Vortex Frame": {
    icon: "/common/destiny2_content/icons/23e50e126159f0f22983f73d6a246f0d.png",
    color: MUTED,
  },
  "Wave Frame": {
    icon: "/common/destiny2_content/icons/30428876335fdd1e164128b9e5a6e4ad.png",
    color: MUTED,
  },
  "Wave Sword Frame": {
    icon: "/common/destiny2_content/icons/a036d40aac06df275ffbb37ab370d7b7.png",
    color: MUTED,
  },
};

export function bungieIconUrl(relativePath: string): string {
  if (relativePath.startsWith("http")) return relativePath;
  return `https://www.bungie.net${relativePath}`;
}

function normalizeKey(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, " ");
}

/** Lookup weapon frame visual; tolerates missing "Frame" suffix. */
export function visualForWeaponFrame(
  frame: string | null | undefined,
): OfficialFilterVisual | null {
  if (!frame?.trim()) return null;
  const raw = frame.trim();
  const direct = WEAPON_FRAME_OFFICIAL[raw];
  if (direct) return direct;
  const withFrame = raw.endsWith("Frame") ? raw : `${raw} Frame`;
  if (WEAPON_FRAME_OFFICIAL[withFrame]) return WEAPON_FRAME_OFFICIAL[withFrame]!;
  const key = normalizeKey(raw);
  for (const [name, visual] of Object.entries(WEAPON_FRAME_OFFICIAL)) {
    if (normalizeKey(name) === key) return visual;
    if (normalizeKey(name.replace(/\s*frame$/i, "")) === key) return visual;
  }
  return null;
}

export function visualForArmorArchetype(
  name: string | null | undefined,
): OfficialFilterVisual | null {
  if (!name?.trim()) return null;
  const hit =
    ARMOR_ARCHETYPE_OFFICIAL[
      name.trim() as (typeof CATALOG_ARMOR_ARCHETYPES)[number]
    ];
  return hit ?? null;
}

export function visualForAmmo(
  ammo: string | null | undefined,
): OfficialFilterVisual | null {
  if (!ammo) return null;
  return AMMO_OFFICIAL[ammo as CatalogAmmoType] ?? null;
}

export function visualForElement(
  element: string | null | undefined,
): OfficialFilterVisual | null {
  if (!element) return null;
  return ELEMENT_OFFICIAL[element as DestinyElement] ?? null;
}

/** Active FilterChip style from an official visual. */
export function officialActiveStyle(
  visual: OfficialFilterVisual,
): CSSProperties {
  return {
    borderColor: visual.color,
    boxShadow: `0 0 0 1px ${visual.color}`,
    backgroundColor: `color-mix(in srgb, ${visual.color} 14%, transparent)`,
  };
}
