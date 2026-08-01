import { coverageKeyFromLink } from "@/lib/synergies/coverageKeys";
import type { SynergyLinkInput } from "@/lib/synergies/schemas";
import { normalizedTypeCoverageKey } from "@/lib/synergies/typeCoverage";

export type MergeableLink = {
  kind: string;
  displayName: string;
  itemHash?: number | null;
  perkHash?: number | null;
  parentItemHash?: number | null;
  originTraitName?: string | null;
  originTraitHash?: number | null;
  armorSetName?: string | null;
  bonusPieces?: number | null;
  bonusName?: string | null;
  armorSetHash?: number | null;
};

/** Stable identity for unioning links across library rows. */
export function linkDedupeKey(link: MergeableLink): string {
  const key = coverageKeyFromLink(link);
  if (key) return key;
  return `fallback:${link.kind}:${link.displayName.trim().toLowerCase()}`;
}

export function linkRecordToInput(link: MergeableLink): SynergyLinkInput {
  const kind = link.kind as SynergyLinkInput["kind"];
  const base: SynergyLinkInput = {
    kind,
    displayName: link.displayName,
  };
  if (link.itemHash != null) base.itemHash = link.itemHash;
  if (link.perkHash != null) base.perkHash = link.perkHash;
  if (link.parentItemHash != null) base.parentItemHash = link.parentItemHash;
  if (link.originTraitName != null) base.originTraitName = link.originTraitName;
  if (link.originTraitHash != null) base.originTraitHash = link.originTraitHash;
  if (link.armorSetName != null) base.armorSetName = link.armorSetName;
  if (link.bonusPieces === 2 || link.bonusPieces === 4) {
    base.bonusPieces = link.bonusPieces;
  }
  if (link.bonusName != null) base.bonusName = link.bonusName;
  if (link.armorSetHash != null) base.armorSetHash = link.armorSetHash;
  return base;
}

/**
 * Union links in order (survivor first), dropping duplicates by coverage key.
 */
export function unionSynergyLinks(
  linkLists: MergeableLink[][],
): SynergyLinkInput[] {
  const seen = new Set<string>();
  const out: SynergyLinkInput[] = [];
  for (const list of linkLists) {
    for (const link of list) {
      const key = linkDedupeKey(link);
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(linkRecordToInput(link));
    }
  }
  return out;
}

/** Join unique non-empty descriptions; survivor text first. Cap at maxLen. */
export function mergeSynergyDescriptions(
  descriptions: string[],
  maxLen = 2000,
): string {
  const parts: string[] = [];
  const seen = new Set<string>();
  for (const raw of descriptions) {
    const t = raw.trim();
    if (!t) continue;
    const key = t.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    parts.push(t);
  }
  let joined = parts.join("\n\n");
  if (joined.length > maxLen) {
    joined = joined.slice(0, maxLen - 1).trimEnd() + "…";
  }
  return joined;
}

export function sameSynergyDesignation(
  a: { type: string; subType: string | null },
  b: { type: string; subType: string | null },
): boolean {
  return (
    normalizedTypeCoverageKey(a.type, a.subType) ===
    normalizedTypeCoverageKey(b.type, b.subType)
  );
}
