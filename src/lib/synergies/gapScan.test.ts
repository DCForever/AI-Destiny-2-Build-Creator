import { describe, expect, it } from "vitest";

import {
  defaultTypeForCandidate,
  filterCandidatesByScope,
  findMissingGaps,
  gapsFromSynergiesAndCandidates,
  mergeCandidates,
  proposalsFromGaps,
} from "./gapScan";
import type { GapCandidate } from "./gapScanTypes";

const CANDIDATES: GapCandidate[] = [
  {
    coverageKey: "weapon:1",
    kind: "weapon",
    displayName: "Sunshot",
    itemHash: 1,
    ammo: "Primary",
    sources: ["owned", "manifest"],
  },
  {
    coverageKey: "weapon:2",
    kind: "weapon",
    displayName: "Edge Transit",
    itemHash: 2,
    ammo: "Special",
    sources: ["manifest"],
  },
  {
    coverageKey: "origin_trait:hash:9",
    kind: "origin_trait",
    displayName: "Wild Card",
    originTraitHash: 9,
    originTraitName: "Wild Card",
    sources: ["manifest"],
  },
];

describe("defaultTypeForCandidate", () => {
  it("maps weapon ammo to weapon synergy types", () => {
    expect(defaultTypeForCandidate(CANDIDATES[0]!)).toBe("primary_weapon");
    expect(defaultTypeForCandidate(CANDIDATES[1]!)).toBe("special_weapon");
  });
});

describe("filterCandidatesByScope", () => {
  it("both keeps owned and manifest-only rows", () => {
    expect(filterCandidatesByScope(CANDIDATES, "both")).toHaveLength(3);
    expect(
      filterCandidatesByScope(CANDIDATES, "owned").map((c) => c.coverageKey),
    ).toEqual(["weapon:1"]);
    expect(filterCandidatesByScope(CANDIDATES, "manifest")).toHaveLength(3);
  });
});

describe("findMissingGaps / gapsFromSynergiesAndCandidates", () => {
  it("reports candidates not covered by existing links for scope both", () => {
    const gaps = gapsFromSynergiesAndCandidates(
      [
        {
          links: [{ kind: "weapon", itemHash: 1 }],
        },
      ],
      CANDIDATES,
      "both",
    );
    expect(gaps.map((g) => g.coverageKey).sort()).toEqual([
      "origin_trait:hash:9",
      "weapon:2",
    ]);
    expect(gaps.find((g) => g.coverageKey === "weapon:2")?.suggestedType).toBe(
      "special_weapon",
    );
    expect(gaps.every((g) => g.gapKind === "link")).toBe(true);
  });

  it("respects limit", () => {
    const gaps = findMissingGaps(CANDIDATES, new Set(), { limit: 1 });
    expect(gaps).toHaveLength(1);
  });
});

describe("proposalsFromGaps", () => {
  it("builds confirmable synergy proposals", () => {
    const gaps = findMissingGaps([CANDIDATES[0]!], new Set());
    const proposals = proposalsFromGaps(gaps);
    expect(proposals).toHaveLength(1);
    expect(proposals[0]?.kind).toBe("synergy");
    expect(proposals[0]?.synergy?.type).toBe("primary_weapon");
    expect(proposals[0]?.synergy?.links?.[0]).toMatchObject({
      kind: "weapon",
      itemHash: 1,
    });
  });
});

describe("mergeCandidates", () => {
  it("unions sources for the same coverage key", () => {
    const merged = mergeCandidates(
      [
        {
          coverageKey: "weapon:1",
          kind: "weapon",
          displayName: "Sunshot",
          itemHash: 1,
          sources: ["manifest"],
        },
      ],
      [
        {
          coverageKey: "weapon:1",
          kind: "weapon",
          displayName: "Sunshot",
          itemHash: 1,
          sources: ["owned"],
        },
      ],
    );
    expect(merged).toHaveLength(1);
    expect(merged[0]?.sources.sort()).toEqual(["manifest", "owned"]);
  });
});
