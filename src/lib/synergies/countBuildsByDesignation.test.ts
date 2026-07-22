import { describe, expect, it } from "vitest";

import {
  buildCountByDesignationKey,
  countBuildsForDesignation,
  listBuildsForDesignation,
} from "@/lib/synergies/countBuildsByDesignation";

describe("countBuildsForDesignation", () => {
  const builds = [
    {
      synergyTypes: [
        { type: "verb", subType: "Devour" },
        { type: "melee", subType: "Base" },
      ],
    },
    { synergyTypes: [{ type: "verb", subType: "Devour" }] },
    { synergyTypes: [{ type: "verb", subType: "Scorch" }] },
  ];

  it("counts builds matching designation", () => {
    expect(
      countBuildsForDesignation(builds, { type: "verb", subType: "Devour" }),
    ).toBe(2);
    expect(
      countBuildsForDesignation(builds, { type: "melee", subType: "Base" }),
    ).toBe(1);
    expect(
      countBuildsForDesignation(builds, { type: "verb", subType: "Ionic Trace" }),
    ).toBe(0);
  });
});

describe("buildCountByDesignationKey", () => {
  it("maps keys to counts without double-counting a build", () => {
    const map = buildCountByDesignationKey([
      {
        synergyTypes: [
          { type: "verb", subType: "Devour" },
          { type: "verb", subType: "Devour" },
        ],
      },
    ]);
    expect(map.get("verb::Devour")).toBe(1);
  });
});

describe("listBuildsForDesignation", () => {
  it("returns named builds sorted by name", () => {
    const builds = [
      {
        id: "b2",
        name: "Zebra",
        className: "Hunter",
        synergyTypes: [{ type: "verb", subType: "Scorch" }],
      },
      {
        id: "b1",
        name: "Alpha",
        className: "Warlock",
        synergyTypes: [{ type: "verb", subType: "Scorch" }],
      },
      {
        id: "b3",
        name: "Other",
        className: "Titan",
        synergyTypes: [{ type: "verb", subType: "Jolt" }],
      },
    ];
    expect(
      listBuildsForDesignation(builds, { type: "verb", subType: "Scorch" }),
    ).toEqual([
      { id: "b1", name: "Alpha", className: "Warlock" },
      { id: "b2", name: "Zebra", className: "Hunter" },
    ]);
  });
});
