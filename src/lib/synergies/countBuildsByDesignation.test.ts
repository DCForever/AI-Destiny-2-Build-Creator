import { describe, expect, it } from "vitest";

import {
  buildCountByDesignationKey,
  countBuildsForDesignation,
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
