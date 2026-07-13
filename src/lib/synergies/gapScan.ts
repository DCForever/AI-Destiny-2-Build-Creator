import {
  collectCoveredKeys,
  coverageKeyFromLink,
  linkInputFromCoverageCandidate,
} from "@/lib/synergies/coverageKeys";
import type {
  GapCandidate,
  GapScanScope,
  MissingSynergyGap,
} from "@/lib/synergies/gapScanTypes";
import type { CreatableSynergyType } from "@/lib/synergies/schemas";
import type { Proposal } from "@/lib/llm/propose/proposalSchemas";

/** Default library type for a gap when LLM has not assigned one. */
export function defaultTypeForCandidate(candidate: GapCandidate): CreatableSynergyType {
  if (candidate.kind === "weapon") {
    if (candidate.ammo === "Primary") return "primary_weapon";
    if (candidate.ammo === "Special") return "special_weapon";
    if (candidate.ammo === "Heavy") return "heavy_weapon";
    return "general_weapon";
  }
  // Perks / origin / set bonuses: keep creatable without subtype requirements.
  return "general_weapon";
}

export function filterCandidatesByScope(
  candidates: GapCandidate[],
  scope: GapScanScope,
): GapCandidate[] {
  if (scope === "both") return candidates;
  if (scope === "owned") {
    return candidates.filter((c) => c.sources.includes("owned"));
  }
  return candidates.filter((c) => c.sources.includes("manifest"));
}

export function findMissingGaps(
  candidates: GapCandidate[],
  coveredKeys: Set<string>,
  opts?: { limit?: number },
): MissingSynergyGap[] {
  const limit = opts?.limit ?? 200;
  const missing: MissingSynergyGap[] = [];

  for (const candidate of candidates) {
    if (coveredKeys.has(candidate.coverageKey)) continue;
    const suggestedType = defaultTypeForCandidate(candidate);
    missing.push({
      ...candidate,
      gapKind: "link",
      suggestedType,
      suggestedSubType: null,
      rationale: `No library synergy links to this ${candidate.kind.replace(/_/g, " ")} yet.`,
    });
    if (missing.length >= limit) break;
  }

  return missing;
}

export function gapsFromSynergiesAndCandidates(
  synergies: Array<{ links: Array<Parameters<typeof coverageKeyFromLink>[0]> }>,
  candidates: GapCandidate[],
  scope: GapScanScope,
  opts?: { limit?: number },
): MissingSynergyGap[] {
  const scoped = filterCandidatesByScope(candidates, scope);
  const covered = collectCoveredKeys(synergies);
  return findMissingGaps(scoped, covered, opts);
}

export function proposalsFromGaps(gaps: MissingSynergyGap[]): Proposal[] {
  return gaps.map((gap, index) => {
    if (gap.gapKind === "type") {
      return {
        id: `gap-${index + 1}`,
        kind: "synergy" as const,
        rationale: gap.rationale,
        synergy: {
          type: gap.suggestedType,
          subType: gap.suggestedSubType,
          description: `Auto-proposed type designation gap: ${gap.displayName}.`,
          links: [],
        },
      };
    }
    const link = linkInputFromCoverageCandidate(gap);
    return {
      id: `gap-${index + 1}`,
      kind: "synergy" as const,
      rationale: gap.rationale,
      synergy: {
        type: gap.suggestedType,
        subType: gap.suggestedSubType,
        description: `Auto-proposed from gap scan (${gap.sources.join("+")}).`,
        links: [link],
      },
    };
  });
}

/** Merge two candidate lists by coverage key, unioning sources. */
export function mergeCandidates(a: GapCandidate[], b: GapCandidate[]): GapCandidate[] {
  const map = new Map<string, GapCandidate>();
  for (const list of [a, b]) {
    for (const c of list) {
      const existing = map.get(c.coverageKey);
      if (!existing) {
        map.set(c.coverageKey, { ...c, sources: [...c.sources] });
        continue;
      }
      const sources = new Set([...existing.sources, ...c.sources]);
      map.set(c.coverageKey, {
        ...existing,
        ...c,
        sources: [...sources] as GapCandidate["sources"],
      });
    }
  }
  return [...map.values()].sort((x, y) =>
    x.displayName.localeCompare(y.displayName, undefined, { sensitivity: "base" }),
  );
}
