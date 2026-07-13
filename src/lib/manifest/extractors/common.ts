/**
 * Shared projection helpers used across multiple extractors.
 */

import { normalizeName } from "../normalize";
import type { RawTable } from "../types/services";
import type {
  AmmoTypeName,
  ArmorSlotName,
  DestinyClassName,
  ElementName,
  Hash,
  WeaponSlotName,
} from "../types/records";
import {
  asRawInventoryItem,
  asRawPlugSet,
  asRawSandboxPerk,
  type RawInventoryItem,
  type RawSocketEntry,
} from "./rawTypes";

// ─── Base projection ──────────────────────────────────────────────────────

export interface BaseProjection {
  hash: Hash;
  name: string;
  searchName: string;
  icon: string | null;
}

export function projectBase(item: RawInventoryItem): BaseProjection {
  return {
    hash: item.hash,
    name: item.displayProperties.name,
    searchName: normalizeName(item.displayProperties.name),
    icon: item.displayProperties.icon ?? null,
  };
}

export function isUsable(item: RawInventoryItem): boolean {
  return !item.redacted && item.displayProperties.name.trim() !== "";
}

/** Iterate a raw table and return all entries that narrow to RawInventoryItem. */
export function iterItems(table: RawTable): RawInventoryItem[] {
  const result: RawInventoryItem[] = [];
  for (const v of Object.values(table)) {
    const item = asRawInventoryItem(v);
    if (item && isUsable(item)) result.push(item);
  }
  return result;
}

/** Look up a hash in a raw table (handles both string and numeric-coerced keys). */
export function getRaw(table: RawTable, hash: number): unknown {
  return table[String(hash)];
}

// ─── Enum mappers ─────────────────────────────────────────────────────────

const CLASS_MAP: Record<number, DestinyClassName> = {
  0: "Titan",
  1: "Hunter",
  2: "Warlock",
};

export function toClassName(classType: number | undefined): DestinyClassName | null {
  if (classType == null || classType === 3) return null;
  return CLASS_MAP[classType] ?? null;
}

const ARMOR_SLOT_MAP: Record<string, ArmorSlotName> = {
  Helmet: "Helmet",
  Gauntlets: "Gauntlets",
  "Chest Armor": "Chest",
  "Leg Armor": "Legs",
  "Class Armor": "ClassItem",
};

export function toArmorSlot(slotName: string): ArmorSlotName | null {
  return ARMOR_SLOT_MAP[slotName] ?? null;
}

const WEAPON_SLOT_MAP: Record<string, WeaponSlotName> = {
  "Kinetic Weapons": "Kinetic",
  "Energy Weapons": "Energy",
  "Power Weapons": "Power",
};

export function toWeaponSlot(slotName: string): WeaponSlotName | null {
  return WEAPON_SLOT_MAP[slotName] ?? null;
}

const AMMO_MAP: Record<number, AmmoTypeName> = { 1: "Primary", 2: "Special", 3: "Heavy" };

export function toAmmoType(n: number | undefined): AmmoTypeName | null {
  if (n == null) return null;
  return AMMO_MAP[n] ?? null;
}

const ELEMENT_MAP: Record<string, ElementName> = {
  Kinetic: "Kinetic",
  Arc: "Arc",
  Solar: "Solar",
  Void: "Void",
  Stasis: "Stasis",
  Strand: "Strand",
  Prismatic: "Prismatic",
};

export function toElementName(name: string): ElementName | null {
  return ELEMENT_MAP[name] ?? null;
}

/** Derive ElementName from an item-type display-name prefix or plugCategoryIdentifier segment. */
export function deriveElement(typeName: string, categoryId: string): ElementName {
  for (const el of ["Arc", "Solar", "Void", "Stasis", "Strand", "Prismatic"] as const) {
    if (typeName.startsWith(el)) return el;
  }
  if (categoryId.includes(".arc.") || categoryId.endsWith(".arc")) return "Arc";
  if (categoryId.includes(".solar.") || categoryId.endsWith(".solar")) return "Solar";
  if (categoryId.includes(".void.") || categoryId.endsWith(".void")) return "Void";
  if (categoryId.includes(".stasis.") || categoryId.endsWith(".stasis")) return "Stasis";
  if (categoryId.includes(".strand.") || categoryId.endsWith(".strand")) return "Strand";
  if (categoryId.includes(".prismatic.") || categoryId.endsWith(".prismatic")) return "Prismatic";
  return "Kinetic";
}

// ─── Socket helpers ───────────────────────────────────────────────────────

/** Find a socket's initial plug that passes `test`, returning the resolved plug item. */
export function findSocketPlug(
  item: RawInventoryItem,
  itemTable: RawTable,
  test: (plug: RawInventoryItem) => boolean,
): RawInventoryItem | undefined {
  for (const socket of item.sockets?.socketEntries ?? []) {
    const h = socket.singleInitialItemHash;
    if (!h) continue;
    const plug = asRawInventoryItem(getRaw(itemTable, h));
    if (plug && test(plug)) return plug;
  }
  return undefined;
}

/** Resolve plug item hashes from a DestinyPlugSetDefinition entry. */
export function plugSetHashes(plugSetHash: number | undefined, plugSets: RawTable): Hash[] {
  if (!plugSetHash) return [];
  const ps = asRawPlugSet(getRaw(plugSets, plugSetHash));
  return (ps?.reusablePlugItems ?? [])
    .map((e) => e.plugItemHash)
    .filter((h): h is number => typeof h === "number");
}

/** Collect curated and randomized plug hashes for a single socket. */
export function socketPlugHashes(
  socket: RawSocketEntry,
  plugSets: RawTable,
): { curated: Hash[]; randomized: Hash[] } {
  const curated: Hash[] = [];
  if (socket.reusablePlugSetHash) {
    curated.push(...plugSetHashes(socket.reusablePlugSetHash, plugSets));
  } else if (socket.singleInitialItemHash) {
    curated.push(socket.singleInitialItemHash);
  }
  const randomized = plugSetHashes(socket.randomizedPlugSetHash, plugSets);
  return { curated: [...new Set(curated)], randomized: [...new Set(randomized)] };
}

/** Return true if a socket's initial plug has a plugCategoryIdentifier containing "origins". */
export function isOriginSocket(socket: RawSocketEntry, itemTable: RawTable): boolean {
  const h = socket.singleInitialItemHash;
  if (!h) return false;
  const plug = asRawInventoryItem(getRaw(itemTable, h));
  return /origins/.test(plug?.plug?.plugCategoryIdentifier ?? "");
}

const EXCLUDED_CAT_PATTERNS = [
  /intrinsics/,
  /origins/,
  /masterwork/,
  /shader/,
  /^enhancements\./,
];

/**
 * Return true if a socket should be excluded from weapon perk columns.
 * Excludes intrinsic, origin, masterwork, shader, mod, and frame sockets.
 */
export function isExcludedPerkSocket(
  socket: RawSocketEntry,
  itemTable: RawTable,
): boolean {
  const h = socket.singleInitialItemHash;
  if (!h) {
    return socket.randomizedPlugSetHash == null && socket.reusablePlugSetHash == null;
  }
  const plug = asRawInventoryItem(getRaw(itemTable, h));
  const cat = plug?.plug?.plugCategoryIdentifier ?? "";
  return cat === "frames" || EXCLUDED_CAT_PATTERNS.some((p) => p.test(cat));
}

/** Return socket indexes for a named socket category on an item. */
export function getPerkSocketIndexes(item: RawInventoryItem, categoryHash: number): number[] {
  const cat = item.sockets?.socketCategories?.find(
    (c) => c.socketCategoryHash === categoryHash,
  );
  return cat?.socketIndexes ?? [];
}

/** Get perk description, falling back to the first DestinySandboxPerk description if blank. */
export function perkDescription(item: RawInventoryItem, sandboxPerks: RawTable): string {
  const desc = item.displayProperties.description?.trim() ?? "";
  if (desc !== "") return desc;
  const perkHash = item.perks?.[0]?.perkHash;
  if (!perkHash) return "";
  const sp = asRawSandboxPerk(getRaw(sandboxPerks, perkHash));
  return sp?.displayProperties.description?.trim() ?? "";
}
