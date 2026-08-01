import type { MissingSynergyGap } from "@/lib/synergies/gapScanTypes";
import type { Proposal } from "@/lib/llm/propose/proposalSchemas";

/** Drop gaps (and aligned proposals) whose coverageKey is ignored. */
export function filterIgnoredTypeGaps<T extends { coverageKey: string }>(
  gaps: T[],
  ignoredKeys: ReadonlySet<string> | readonly string[],
): T[] {
  const ignored =
    ignoredKeys instanceof Set ? ignoredKeys : new Set(ignoredKeys);
  if (ignored.size === 0) return gaps;
  return gaps.filter((g) => !ignored.has(g.coverageKey));
}

/**
 * Gaps and proposals are index-aligned from proposalsFromGaps.
 * Filter both together by coverageKey on the gap side.
 */
export function filterGapsAndProposals(
  gaps: MissingSynergyGap[],
  proposals: Proposal[],
  ignoredKeys: ReadonlySet<string> | readonly string[],
): { gaps: MissingSynergyGap[]; proposals: Proposal[] } {
  const ignored =
    ignoredKeys instanceof Set ? ignoredKeys : new Set(ignoredKeys);
  if (ignored.size === 0) return { gaps, proposals };

  const nextGaps: MissingSynergyGap[] = [];
  const nextProposals: Proposal[] = [];
  for (let i = 0; i < gaps.length; i++) {
    const gap = gaps[i]!;
    if (ignored.has(gap.coverageKey)) continue;
    nextGaps.push(gap);
    if (proposals[i]) nextProposals.push(proposals[i]!);
  }
  // Re-id proposals for stable UI ids after filter
  return {
    gaps: nextGaps,
    proposals: nextProposals.map((p, index) => ({
      ...p,
      id: `gap-${index + 1}`,
    })),
  };
}
