import { describe, expect, it } from "vitest";

import {
  buildTypeDesignationCandidates,
  collectCoveredTypeKeys,
  findMissingTypeGaps,
  proposalsFromTypeGaps,
  typeCoverageKey,
} from "./typeCoverage";

describe("typeCoverageKey", () => {
  it("formats type and subtype", () => {
    expect(typeCoverageKey("verb", "Sliding")).toBe("verb::Sliding");
    expect(typeCoverageKey("dps", null)).toBe("dps::");
  });
});

describe("buildTypeDesignationCandidates", () => {
  it("includes Sliding as a verb designation in full vocab mode", () => {
    const all = buildTypeDesignationCandidates();
    expect(all.some((c) => c.type === "verb" && c.subType === "Sliding")).toBe(
      true,
    );
  });

  it("includes type-only creatable categories in full vocab mode", () => {
    const all = buildTypeDesignationCandidates();
    expect(all.some((c) => c.type === "dps" && c.subType === null)).toBe(true);
  });

  it("objectDrivenOnly emits only object-backed keywords", () => {
    const all = buildTypeDesignationCandidates({
      objectDrivenOnly: true,
      objectKeywords: [
        {
          keyword: "Sliding",
          kind: "verb",
          origin: "object_text",
          mentionCount: 4,
          sampleObjectNames: ["Slideways"],
        },
      ],
    });
    expect(all).toHaveLength(1);
    expect(all[0]).toMatchObject({
      type: "verb",
      subType: "Sliding",
      mentionCount: 4,
    });
  });
});


describe("findMissingTypeGaps", () => {
  it("reports curated Sliding when onlyNovel is false and library lacks it", () => {
    const candidates = buildTypeDesignationCandidates();
    const covered = collectCoveredTypeKeys([
      { type: "verb", subType: "Scorch" },
      { type: "melee", subType: "Base" },
    ]);
    const gaps = findMissingTypeGaps(candidates, covered, {
      limit: 500,
      onlyNovel: false,
    });
    expect(gaps.some((g) => g.suggestedSubType === "Sliding")).toBe(true);
    expect(gaps.some((g) => g.suggestedSubType === "Scorch")).toBe(false);
  });
});

describe("proposalsFromTypeGaps", () => {
  it("emits unlinked synergy proposals for type designations", () => {
    const gaps = findMissingTypeGaps(
      buildTypeDesignationCandidates().filter((c) => c.subType === "Sliding"),
      new Set(),
      { onlyNovel: false },
    );
    const proposals = proposalsFromTypeGaps(gaps);
    expect(proposals[0]?.synergy).toMatchObject({
      type: "verb",
      subType: "Sliding",
      links: [],
    });
  });
});


describe("query filter on missing types", () => {
  it("returns only Sliding when query is Sliding", () => {
    const candidates = buildTypeDesignationCandidates();
    const gaps = findMissingTypeGaps(candidates, new Set(), {
      query: "Sliding",
      limit: 50,
      onlyNovel: false,
    });
    expect(gaps.length).toBeGreaterThan(0);
    expect(gaps.every((g) => /sliding/i.test(g.displayName))).toBe(true);
  });
});

describe("known vocabulary vs novel missing types", () => {
  it("does not list curated Ionic Trace as missing when onlyNovel", () => {
    const candidates = buildTypeDesignationCandidates({
      objectDrivenOnly: true,
      objectKeywords: [
        {
          keyword: "Ionic Trace",
          kind: "verb",
          origin: "curated",
          mentionCount: 5,
          sampleObjectNames: ["Some Aspect"],
        },
        {
          keyword: "Weird Novel Keyword",
          kind: "verb",
          origin: "object_text",
          mentionCount: 3,
          sampleObjectNames: ["Perk A"],
        },
      ],
    });
    const gaps = findMissingTypeGaps(candidates, new Set(), {
      onlyNovel: true,
      limit: 50,
    });
    expect(gaps.some((g) => g.suggestedSubType === "Ionic Trace")).toBe(false);
    expect(gaps.some((g) => g.suggestedSubType === "Weird Novel Keyword")).toBe(
      true,
    );
  });

  it("treats Unlinked library rows as covering the designation", () => {
    const covered = collectCoveredTypeKeys([
      {
        type: "verb",
        subType: "Ionic Trace",
        name: "Verb: Ionic Trace — Unlinked",
      },
    ]);
    const candidates = buildTypeDesignationCandidates({
      objectDrivenOnly: true,
      objectKeywords: [
        {
          keyword: "Ionic Trace",
          kind: "verb",
          origin: "object_text",
          mentionCount: 4,
        },
      ],
    });
    const gaps = findMissingTypeGaps(candidates, covered, {
      onlyNovel: false,
      limit: 20,
    });
    expect(gaps.some((g) => g.suggestedSubType === "Ionic Trace")).toBe(false);
  });
});


