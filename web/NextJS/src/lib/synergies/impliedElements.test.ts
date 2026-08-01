import { describe, expect, it } from "vitest";

import {
  expandDesignationsWithImpliedElements,
  impliedElementDesignations,
} from "./impliedElements";

describe("impliedElementDesignations", () => {
  it("implies Arc from Ionic Trace", () => {
    const implied = impliedElementDesignations([
      { type: "verb", subType: "Ionic Trace" },
    ]);
    expect(implied).toEqual([{ type: "element", subType: "Arc" }]);
  });

  it("dedupes when Element Arc is already explicit", () => {
    const implied = impliedElementDesignations([
      { type: "verb", subType: "Ionic Trace" },
      { type: "element", subType: "Arc" },
    ]);
    expect(implied).toEqual([]);
  });

  it("dedupes multiple Arc verbs to one element", () => {
    const implied = impliedElementDesignations([
      { type: "verb", subType: "Ionic Trace" },
      { type: "verb", subType: "Jolt" },
    ]);
    expect(implied).toEqual([{ type: "element", subType: "Arc" }]);
  });

  it("implies multiple elements from mixed verbs", () => {
    const implied = impliedElementDesignations([
      { type: "verb", subType: "Scorch" },
      { type: "verb", subType: "Volatile" },
    ]);
    expect(implied).toEqual(
      expect.arrayContaining([
        { type: "element", subType: "Solar" },
        { type: "element", subType: "Void" },
      ]),
    );
    expect(implied).toHaveLength(2);
  });

  it("skips agnostic verbs", () => {
    expect(
      impliedElementDesignations([{ type: "verb", subType: "Sliding" }]),
    ).toEqual([]);
  });
});

describe("expandDesignationsWithImpliedElements", () => {
  it("appends implied elements after explicit list", () => {
    const expanded = expandDesignationsWithImpliedElements([
      { type: "verb", subType: "Ionic Trace" },
      { type: "melee", subType: "Base" },
    ]);
    expect(expanded).toEqual([
      { type: "verb", subType: "Ionic Trace" },
      { type: "melee", subType: "Base" },
      { type: "element", subType: "Arc" },
    ]);
  });
});
