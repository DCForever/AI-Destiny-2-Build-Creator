import { describe, expect, it } from "vitest";

import { filterGapsAndProposals, filterIgnoredTypeGaps } from "./ignoredTypeGaps";
import type { MissingSynergyGap } from "./gapScanTypes";
import type { Proposal } from "@/lib/llm/propose/proposalSchemas";

const gaps: MissingSynergyGap[] = [
  {
    gapKind: "type",
    coverageKey: "verb::Sliding",
    displayName: "Verb: Sliding",
    sources: ["object_text"],
    suggestedType: "verb",
    suggestedSubType: "Sliding",
    rationale: "x",
  },
  {
    gapKind: "type",
    coverageKey: "verb::Radiant",
    displayName: "Verb: Radiant",
    sources: ["vocab"],
    suggestedType: "verb",
    suggestedSubType: "Radiant",
    rationale: "y",
  },
];

const proposals: Proposal[] = [
  {
    id: "gap-1",
    kind: "synergy",
    synergy: { type: "verb", subType: "Sliding", links: [] },
  },
  {
    id: "gap-2",
    kind: "synergy",
    synergy: { type: "verb", subType: "Radiant", links: [] },
  },
];

describe("filterIgnoredTypeGaps", () => {
  it("removes ignored coverage keys", () => {
    expect(
      filterIgnoredTypeGaps(gaps, ["verb::Sliding"]).map((g) => g.coverageKey),
    ).toEqual(["verb::Radiant"]);
  });
});

describe("filterGapsAndProposals", () => {
  it("keeps gaps and proposals aligned after ignore", () => {
    const { gaps: g, proposals: p } = filterGapsAndProposals(gaps, proposals, [
      "verb::Sliding",
    ]);
    expect(g).toHaveLength(1);
    expect(g[0]?.coverageKey).toBe("verb::Radiant");
    expect(p).toHaveLength(1);
    expect(p[0]?.synergy?.subType).toBe("Radiant");
    expect(p[0]?.id).toBe("gap-1");
  });
});
