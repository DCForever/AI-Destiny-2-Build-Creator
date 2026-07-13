import type { SynergyLinkInput } from "@/lib/synergies/schemas";

export type CoverageLinkKind =
  | "weapon"
  | "weapon_perk"
  | "origin_trait"
  | "armor_set_bonus";

/** Stable key for “is this synergizable object already linked in the library?” */
export function coverageKeyFromLink(link: {
  kind: string;
  itemHash?: number | null;
  perkHash?: number | null;
  originTraitHash?: number | null;
  originTraitName?: string | null;
  armorSetName?: string | null;
  bonusPieces?: number | null;
  bonusName?: string | null;
}): string | null {
  switch (link.kind) {
    case "weapon":
      if (link.itemHash == null) return null;
      return `weapon:${link.itemHash}`;
    case "weapon_perk":
      if (link.perkHash == null) return null;
      return `weapon_perk:${link.perkHash}`;
    case "origin_trait": {
      if (link.originTraitHash != null) {
        return `origin_trait:hash:${link.originTraitHash}`;
      }
      const name = link.originTraitName?.trim().toLowerCase();
      if (!name) return null;
      return `origin_trait:name:${name}`;
    }
    case "armor_set_bonus": {
      const set = link.armorSetName?.trim().toLowerCase();
      if (!set || link.bonusPieces == null) return null;
      const bonus = link.bonusName?.trim().toLowerCase() ?? "";
      return `armor_set_bonus:${set}:${link.bonusPieces}:${bonus}`;
    }
    default:
      return null;
  }
}

export function collectCoveredKeys(
  synergies: Array<{ links: Array<Parameters<typeof coverageKeyFromLink>[0]> }>,
): Set<string> {
  const keys = new Set<string>();
  for (const synergy of synergies) {
    for (const link of synergy.links) {
      const key = coverageKeyFromLink(link);
      if (key) keys.add(key);
    }
  }
  return keys;
}

export function linkInputFromCoverageCandidate(candidate: {
  kind: CoverageLinkKind;
  displayName: string;
  itemHash?: number;
  perkHash?: number;
  originTraitHash?: number;
  originTraitName?: string;
  armorSetName?: string;
  bonusPieces?: 2 | 4;
  bonusName?: string;
  armorSetHash?: number;
}): SynergyLinkInput {
  switch (candidate.kind) {
    case "weapon":
      return {
        kind: "weapon",
        displayName: candidate.displayName,
        itemHash: candidate.itemHash,
      };
    case "weapon_perk":
      return {
        kind: "weapon_perk",
        displayName: candidate.displayName,
        perkHash: candidate.perkHash,
      };
    case "origin_trait":
      return {
        kind: "origin_trait",
        displayName: candidate.displayName,
        originTraitName: candidate.originTraitName ?? candidate.displayName,
        originTraitHash: candidate.originTraitHash,
      };
    case "armor_set_bonus":
      return {
        kind: "armor_set_bonus",
        displayName: candidate.displayName,
        armorSetName: candidate.armorSetName,
        bonusPieces: candidate.bonusPieces,
        bonusName: candidate.bonusName,
        armorSetHash: candidate.armorSetHash,
      };
  }
}
