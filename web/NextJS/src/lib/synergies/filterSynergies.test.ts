import { describe, expect, it } from "vitest";

import { filterSynergies } from "./filterSynergies";

const ROWS = [
  { id: "1", name: "Melee — Consecration", type: "melee", subType: "Consecration" },
  { id: "2", name: "Melee — Hammer Strike", type: "melee", subType: "Hammer Strike" },
  { id: "3", name: "Verb — Radiant", type: "verb", subType: "Radiant" },
  { id: "4", name: "DPS Kit", type: "dps", subType: null },
];

describe("filterSynergies", () => {
  it("filters by type chips", () => {
    expect(filterSynergies(ROWS, { types: ["melee"] }).map((r) => r.id)).toEqual([
      "1",
      "2",
    ]);
  });

  it("filters by subtype submenu selection", () => {
    expect(
      filterSynergies(ROWS, {
        types: ["melee"],
        subTypes: ["Consecration"],
      }).map((r) => r.id),
    ).toEqual(["1"]);
  });

  it("requires subtype match when subtypes are selected", () => {
    expect(
      filterSynergies(ROWS, { subTypes: ["Radiant"] }).map((r) => r.id),
    ).toEqual(["3"]);
    expect(filterSynergies(ROWS, { subTypes: ["Radiant"], types: ["dps"] })).toEqual(
      [],
    );
  });

  it("searches name type and subtype", () => {
    expect(filterSynergies(ROWS, { query: "hammer" }).map((r) => r.id)).toEqual([
      "2",
    ]);
  });
});
