import { describe, expect, it } from "vitest";

import {
  pickMergeSurvivor,
  planDesignationConsolidations,
} from "@/lib/synergies/consolidateDesignations";

describe("pickMergeSurvivor", () => {
  it("picks earliest createdAt then lowest id", () => {
    const survivor = pickMergeSurvivor([
      { id: "b", type: "verb", subType: "Devour", createdAt: "2026-02-01" },
      { id: "a", type: "verb", subType: "Devour", createdAt: "2026-01-01" },
      { id: "c", type: "verb", subType: "Devour", createdAt: "2026-01-01" },
    ]);
    expect(survivor.id).toBe("a");
  });
});

describe("planDesignationConsolidations", () => {
  it("returns empty when all designations unique", () => {
    expect(
      planDesignationConsolidations([
        { id: "1", type: "verb", subType: "Devour", createdAt: "2026-01-01" },
        { id: "2", type: "verb", subType: "Scorch", createdAt: "2026-01-02" },
      ]),
    ).toEqual([]);
  });

  it("plans merge for same type+subtype", () => {
    const plans = planDesignationConsolidations([
      { id: "new", type: "verb", subType: "Devour", createdAt: "2026-02-01" },
      { id: "old", type: "verb", subType: "Devour", createdAt: "2026-01-01" },
      { id: "other", type: "melee", subType: "Base", createdAt: "2026-01-01" },
    ]);
    expect(plans).toHaveLength(1);
    expect(plans[0]!.survivorId).toBe("old");
    expect(plans[0]!.sourceIds).toEqual(["new"]);
    expect(plans[0]!.key).toBe("verb::Devour");
  });
});
