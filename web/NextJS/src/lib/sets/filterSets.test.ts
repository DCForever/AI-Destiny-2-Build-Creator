import { describe, expect, it } from "vitest";

import { filterSets, isSetType } from "./filterSets";

const SAMPLE = [
  { id: "1", name: "Solar Add Clear", type: "weapon", tagIds: ["solar", "pve"] },
  { id: "2", name: "Void Armor", type: "armor", tagIds: ["void", "pve"] },
  { id: "3", name: "Fashion Kit", type: "fashion", tagIds: [] },
];

describe("filterSets", () => {
  it("filters by query against name and type", () => {
    expect(filterSets(SAMPLE, { query: "void" }).map((s) => s.id)).toEqual(["2"]);
    expect(filterSets(SAMPLE, { query: "weapon" }).map((s) => s.id)).toEqual(["1"]);
  });

  it("filters by type chips", () => {
    expect(filterSets(SAMPLE, { types: ["armor", "fashion"] }).map((s) => s.id)).toEqual([
      "2",
      "3",
    ]);
  });

  it("requires all selected tags", () => {
    expect(filterSets(SAMPLE, { tags: ["pve"] }).map((s) => s.id)).toEqual(["1", "2"]);
    expect(filterSets(SAMPLE, { tags: ["solar", "pve"] }).map((s) => s.id)).toEqual(["1"]);
  });

  it("combines query and type", () => {
    expect(
      filterSets(SAMPLE, { query: "kit", types: ["fashion"] }).map((s) => s.id),
    ).toEqual(["3"]);
  });
});

describe("isSetType", () => {
  it("accepts known set types only", () => {
    expect(isSetType("weapon")).toBe(true);
    expect(isSetType("unknown")).toBe(false);
  });
});
