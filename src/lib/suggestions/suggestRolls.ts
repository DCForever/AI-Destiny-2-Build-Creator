import type { ConceptTagId } from "@/data/conceptTags";
import type { UserInventoryItem } from "@/lib/db/types";
import {
  columnIndexToLabel,
  type PerkWeaponIndex,
} from "@/lib/manifest/perkWeaponIndex";
import type { WeaponRecord, WeaponSlotName } from "@/lib/manifest/types/records";

import type { MergedRollContext } from "./mergeSynergyContext";

export type RollPerkChoice = {
  column: number;
  label: string;
  perkHash: number;
  perkName: string;
};

export type RollSuggestion = {
  weaponHash: number;
  weaponName: string;
  slot: WeaponSlotName;
  perks: RollPerkChoice[];
  score: number;
  reasons: string[];
  owned: boolean;
  ownedInstanceIds: string[];
};

const ELEMENT_TAG_MAP: Partial<Record<ConceptTagId, string>> = {
  solar: "Solar",
  arc: "Arc",
  void: "Void",
  stasis: "Stasis",
  strand: "Strand",
  kinetic: "Kinetic",
};

type SuggestRollsDeps = {
  context: MergedRollContext;
  perkIndex: PerkWeaponIndex;
  perkNames: Map<number, string>;
  weapons: WeaponRecord[];
  setItemPerks?: number[];
  setWeaponHashes?: number[];
  ownedItems: UserInventoryItem[];
  limit?: number;
};

function perkName(perkNames: Map<number, string>, hash: number): string {
  return perkNames.get(hash) ?? `Perk (${hash})`;
}

function matchesElement(tagIds: ConceptTagId[], weapon: WeaponRecord): boolean {
  for (const tag of tagIds) {
    const element = ELEMENT_TAG_MAP[tag];
    if (element && weapon.element === element) return true;
  }
  return false;
}

function hasOriginTrait(weapon: WeaponRecord, traitHashes: number[]): boolean {
  if (traitHashes.length === 0) return false;
  return traitHashes.some((h) => weapon.originTraitHashes.includes(h));
}

function isRollOwned(
  weaponHash: number,
  perkHashes: number[],
  ownedItems: UserInventoryItem[],
): { owned: boolean; instanceIds: string[] } {
  const matches = ownedItems.filter((item) => {
    if (item.itemHash !== weaponHash) return false;
    if (perkHashes.length === 0) return true;
    return perkHashes.every((p) => item.plugHashes.includes(p));
  });
  return { owned: matches.length > 0, instanceIds: matches.map((m) => m.instanceId) };
}

function buildRollForWeapon(
  weapon: WeaponRecord,
  targetPerks: Set<number>,
  perkNames: Map<number, string>,
  context: MergedRollContext,
): RollSuggestion | null {
  const perks: RollPerkChoice[] = [];
  let matchCount = 0;

  for (const col of weapon.perkColumns) {
    const pool = [...col.curated, ...col.randomized];
    const match = pool.find((h) => targetPerks.has(h));
    const chosen = match ?? col.curated[0] ?? col.randomized[0];
    if (!chosen) continue;
    if (match) matchCount++;
    perks.push({
      column: col.column,
      label: columnIndexToLabel(col.column),
      perkHash: chosen,
      perkName: perkName(perkNames, chosen),
    });
  }

  if (perks.length === 0) return null;

  let score = matchCount * 3;
  const reasons: string[] = [];
  if (matchCount) reasons.push(`${matchCount} synergy perk(s) on weapon`);
  if (context.weaponHashes.includes(weapon.hash)) {
    score += 4;
    reasons.push("Linked weapon hash");
  }
  if (hasOriginTrait(weapon, context.originTraitHashes)) {
    score += 2;
    reasons.push("Origin trait match");
  }
  if (matchesElement(context.tagIds, weapon)) {
    score += 2;
    reasons.push(`Element match (${weapon.element})`);
  }

  const perkHashes = perks.map((p) => p.perkHash);
  const owned = isRollOwned(weapon.hash, perkHashes, []);

  return {
    weaponHash: weapon.hash,
    weaponName: weapon.name,
    slot: weapon.slot,
    perks,
    score,
    reasons,
    owned: owned.owned,
    ownedInstanceIds: owned.instanceIds,
  };
}

export function suggestRolls(deps: SuggestRollsDeps): RollSuggestion[] {
  const limit = deps.limit ?? 5;
  const targetPerks = new Set<number>([
    ...deps.context.perkHashes,
    ...(deps.setItemPerks ?? []),
  ]);

  const weaponByHash = new Map(deps.weapons.map((w) => [w.hash, w]));
  const candidates = new Map<number, RollSuggestion>();

  const considerWeapon = (weaponHash: number, bonus: number, reason: string) => {
    const weapon = weaponByHash.get(weaponHash);
    if (!weapon) return;
    const roll = buildRollForWeapon(weapon, targetPerks, deps.perkNames, deps.context);
    if (!roll) return;
    roll.score += bonus;
    if (reason) roll.reasons.push(reason);
    const existing = candidates.get(weaponHash);
    if (!existing || roll.score > existing.score) {
      candidates.set(weaponHash, roll);
    }
  };

  for (const hash of deps.context.weaponHashes) {
    considerWeapon(hash, 2, "Direct weapon link");
  }
  for (const hash of deps.setWeaponHashes ?? []) {
    considerWeapon(hash, 1, "Set weapon");
  }

  for (const perkHash of targetPerks) {
    const entries = deps.perkIndex.byPerk[String(perkHash)] ?? [];
    for (const entry of entries) {
      considerWeapon(entry.weaponHash, entry.curated ? 1 : 0, "Perk pool match");
    }
  }

  if (candidates.size < 2) {
    for (const weapon of deps.weapons) {
      considerWeapon(weapon.hash, 0, "Catalog fallback");
      if (candidates.size >= Math.max(limit, 2)) break;
    }
  }

  const results = [...candidates.values()]
    .map((roll) => {
      const owned = isRollOwned(roll.weaponHash, roll.perks.map((p) => p.perkHash), deps.ownedItems);
      return { ...roll, owned: owned.owned, ownedInstanceIds: owned.instanceIds };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, Math.max(limit, 2));

  return results;
}

export function collectSetRollHints(
  items: Array<{ itemHash: number; selectedPerks: number[] }>,
): { weaponHashes: number[]; perkHashes: number[] } {
  const weaponHashes: number[] = [];
  const perkHashes: number[] = [];
  for (const item of items) {
    weaponHashes.push(item.itemHash);
    perkHashes.push(...item.selectedPerks);
  }
  return { weaponHashes, perkHashes };
}
