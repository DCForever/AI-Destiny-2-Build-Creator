import { describe, expect, it } from "vitest";

import {
  compareMatchRank,
  matchByNameOrDescription,
  matchDescriptionQuery,
  normalizeSearchQuery,
} from "./descriptionMatch";

describe("normalizeSearchQuery", () => {
  it("lowercases and trims", () => {
    expect(normalizeSearchQuery("  Melee  ")).toBe("melee");
  });
});

describe("matchDescriptionQuery", () => {
  it("matches name via searchName", () => {
    const result = matchDescriptionQuery("inca", {
      name: "Incandescent",
      searchName: "incandescent",
      description: "Scorch on defeat.",
    });
    expect(result.matched).toBe(true);
    expect(result.matchField).toBe("name");
  });

  it("matches description when name does not", () => {
    const result = matchDescriptionQuery("melee", {
      name: "Adaptive Munitions",
      searchName: "adaptive munitions",
      description: "Melee final blows grant bonus melee damage.",
    });
    expect(result.matched).toBe(true);
    expect(result.matchField).toBe("description");
  });

  it("matches other text fields", () => {
    const result = matchDescriptionQuery("overshield", {
      name: "Osmium Council",
      searchName: "osmium council",
      otherTexts: ["Overshield on arc melee."],
    });
    expect(result.matched).toBe(true);
    expect(result.matchField).toBe("other");
  });

  it("returns matched for empty query", () => {
    expect(matchDescriptionQuery("", { name: "X" }).matched).toBe(true);
  });

  it("returns false when no field matches", () => {
    expect(
      matchDescriptionQuery("zzznomatch", {
        name: "Foo",
        searchName: "foo",
        description: "Bar",
      }).matched,
    ).toBe(false);
  });
});

describe("compareMatchRank", () => {
  it("ranks name before description", () => {
    expect(compareMatchRank("name", "description")).toBeLessThan(0);
    expect(compareMatchRank("description", "name")).toBeGreaterThan(0);
  });
});

describe("matchByNameOrDescription", () => {
  const records = [
    { name: "Rampage", searchName: "rampage", description: "Stacking buff." },
    { name: "Adaptive Munitions", searchName: "adaptive munitions", description: "Melee bonus." },
  ];

  it("returns records matching name or description", () => {
    const matches = matchByNameOrDescription("melee", records);
    expect(matches).toHaveLength(1);
    expect(matches[0]?.name).toBe("Adaptive Munitions");
  });
});
