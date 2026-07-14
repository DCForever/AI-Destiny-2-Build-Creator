/**
 * Reverse index: perk hash → weapons that can roll it (with slot, column, curated).
 * Built during entityCache.rebuild() and stored as a derived artifact.
 */

import { readFile, writeFile, mkdir } from "node:fs/promises";
import path from "node:path";

import type {
  ExoticWeaponRecord,
  Hash,
  WeaponRecord,
  WeaponSlotName,
} from "./types/records";
import type { EntityStores } from "./types/stores";
import { perkWeaponIndexPath } from "./cachePaths";

export interface PerkWeaponIndexEntry {
  weaponHash: Hash;
  weaponName: string;
  slot: WeaponSlotName;
  itemTypeName: string;
  frame: string;
  column: number;
  curated: boolean;
}

export interface PerkWeaponIndex {
  manifestVersion: string;
  builtAt: string;
  /** perk hash → entries */
  byPerk: Record<string, PerkWeaponIndexEntry[]>;
}

const COLUMN_LABELS = ["Barrel", "Magazine", "Trait 1", "Trait 2", "Trait 3", "Trait 4"];

export function columnIndexToLabel(column: number): string {
  if (column < 0) return "Intrinsic";
  if (column < COLUMN_LABELS.length) return COLUMN_LABELS[column] ?? `Trait ${column - 1}`;
  return `Trait ${column - 1}`;
}

function isNotFound(err: unknown): boolean {
  return typeof err === "object" && err !== null && (err as NodeJS.ErrnoException).code === "ENOENT";
}

export function buildPerkWeaponIndex(
  version: string,
  stores: Pick<EntityStores, "weapons" | "exotic-weapons" | "weapon-perks">,
): PerkWeaponIndex {
  const byPerk: Record<string, PerkWeaponIndexEntry[]> = {};

  const addEntry = (perkHash: Hash, entry: PerkWeaponIndexEntry) => {
    const key = String(perkHash);
    const list = byPerk[key] ?? [];
    const dup = list.some(
      (e) => e.weaponHash === entry.weaponHash && e.column === entry.column && e.curated === entry.curated,
    );
    if (!dup) list.push(entry);
    byPerk[key] = list;
  };

  for (const weapon of stores.weapons) {
    indexWeapon(weapon, addEntry);
  }

  for (const exo of stores["exotic-weapons"]) {
    indexExoticWeapon(exo, addEntry);
  }

  return {
    manifestVersion: version,
    builtAt: new Date().toISOString(),
    byPerk,
  };
}

function indexWeapon(
  weapon: WeaponRecord,
  addEntry: (perkHash: Hash, entry: PerkWeaponIndexEntry) => void,
): void {
  for (const col of weapon.perkColumns) {
    const curatedSet = new Set(col.curated);
    for (const hash of [...col.curated, ...col.randomized]) {
      addEntry(hash, {
        weaponHash: weapon.hash,
        weaponName: weapon.name,
        slot: weapon.slot,
        itemTypeName: weapon.itemTypeName,
        frame: weapon.frame,
        column: col.column,
        curated: curatedSet.has(hash),
      });
    }
  }
}

function indexExoticWeapon(
  weapon: ExoticWeaponRecord,
  addEntry: (perkHash: Hash, entry: PerkWeaponIndexEntry) => void,
): void {
  for (const col of weapon.perkColumns ?? []) {
    const curatedSet = new Set(col.curated);
    for (const hash of [...col.curated, ...col.randomized]) {
      addEntry(hash, {
        weaponHash: weapon.hash,
        weaponName: weapon.name,
        slot: weapon.slot,
        itemTypeName: weapon.frame || "Exotic",
        frame: weapon.frame,
        column: col.column,
        curated: curatedSet.has(hash),
      });
    }
  }
}

export async function writePerkWeaponIndex(version: string, index: PerkWeaponIndex): Promise<void> {
  const filePath = perkWeaponIndexPath(version);
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(index), "utf8");
}

export async function loadPerkWeaponIndex(version: string): Promise<PerkWeaponIndex | null> {
  try {
    const text = await readFile(perkWeaponIndexPath(version), "utf8");
    return JSON.parse(text) as PerkWeaponIndex;
  } catch (err) {
    if (isNotFound(err)) return null;
    throw err;
  }
}
