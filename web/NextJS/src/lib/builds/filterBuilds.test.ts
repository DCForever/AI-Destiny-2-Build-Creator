import { describe, expect, it } from "vitest";

import type { BuildSummary } from "@/components/build/types";

import {
  collectExoticArmorOptions,
  EXOTIC_ARMOR_NONE_KEY,
  exoticArmorFilterKey,
  filterBuilds,
} from "./filterBuilds";

function build(
  partial: Partial<BuildSummary> & Pick<BuildSummary, "id" | "name" | "className">,
): BuildSummary {
  return partial;
}

const sample: BuildSummary[] = [
  build({
    id: "1",
    name: "Synthoceps Punch",
    className: "Titan",
    exoticArmorHash: 10,
    exoticArmorName: "Synthoceps",
  }),
  build({
    id: "2",
    name: "Heart of Inmost Light",
    className: "Titan",
    exoticArmorHash: 20,
    exoticArmorName: "Heart of Inmost Light",
  }),
  build({
    id: "3",
    name: "Caliban",
    className: "Hunter",
    exoticArmorHash: 30,
    exoticArmorName: "Caliban's Hand",
  }),
  build({
    id: "4",
    name: "No Exotic Titan",
    className: "Titan",
  }),
  build({
    id: "5",
    name: "Name-only",
    className: "Warlock",
    exoticArmorName: "Necrotic Grip",
  }),
];

describe("exoticArmorFilterKey", () => {
  it("prefers hash over name", () => {
    expect(
      exoticArmorFilterKey({
        exoticArmorHash: 10,
        exoticArmorName: "Synthoceps",
      }),
    ).toBe("h:10");
  });

  it("falls back to normalized name", () => {
    expect(
      exoticArmorFilterKey({ exoticArmorName: "Necrotic Grip" }),
    ).toBe("n:necrotic grip");
  });

  it("uses none when missing", () => {
    expect(exoticArmorFilterKey({})).toBe(EXOTIC_ARMOR_NONE_KEY);
  });
});

describe("collectExoticArmorOptions", () => {
  it("dedupes and sorts; No exotic last", () => {
    const opts = collectExoticArmorOptions(sample);
    expect(opts.map((o) => o.label)).toEqual([
      "Caliban's Hand",
      "Heart of Inmost Light",
      "Necrotic Grip",
      "Synthoceps",
      "No exotic",
    ]);
  });
});

describe("filterBuilds", () => {
  it("filters by class only", () => {
    const out = filterBuilds(sample, { className: "Titan" });
    expect(out.map((b) => b.id).sort()).toEqual(["1", "2", "4"]);
  });

  it("filters by exotic multi-select (OR)", () => {
    const out = filterBuilds(sample, {
      exoticArmorKeys: ["h:10", "h:30"],
    });
    expect(out.map((b) => b.id).sort()).toEqual(["1", "3"]);
  });

  it("ANDs class with exotic", () => {
    const out = filterBuilds(sample, {
      className: "Titan",
      exoticArmorKeys: ["h:10", "h:30"],
    });
    expect(out.map((b) => b.id)).toEqual(["1"]);
  });

  it("can filter to no exotic", () => {
    const out = filterBuilds(sample, {
      exoticArmorKeys: [EXOTIC_ARMOR_NONE_KEY],
    });
    expect(out.map((b) => b.id)).toEqual(["4"]);
  });

  it("empty exotic keys means no exotic constraint", () => {
    expect(filterBuilds(sample, { exoticArmorKeys: [] })).toHaveLength(5);
  });
});
