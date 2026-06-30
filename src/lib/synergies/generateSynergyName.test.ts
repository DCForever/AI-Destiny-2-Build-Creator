import { describe, expect, it } from "vitest";

import { FIXTURE_AUTO_NAMES, FIXTURE_LINK_DISPLAY } from "@/lib/synergies/__fixtures__/synergyRefinementFixtures";
import { generateSynergyName } from "@/lib/synergies/generateSynergyName";

describe("generateSynergyName", () => {
  it("formats verb with sub-type and link", () => {
    expect(
      generateSynergyName({
        type: "verb",
        subType: "Scorch",
        linkDisplayName: FIXTURE_LINK_DISPLAY,
      }),
    ).toBe(FIXTURE_AUTO_NAMES.verbScorch);
  });

  it("formats melee Base sub-type", () => {
    expect(
      generateSynergyName({
        type: "melee",
        subType: "Base",
        linkDisplayName: FIXTURE_LINK_DISPLAY,
      }),
    ).toBe(FIXTURE_AUTO_NAMES.meleeBase);
  });

  it("formats element Kinetic sub-type", () => {
    expect(
      generateSynergyName({
        type: "element",
        subType: "Kinetic",
        linkDisplayName: FIXTURE_LINK_DISPLAY,
      }),
    ).toBe(FIXTURE_AUTO_NAMES.elementKinetic);
  });

  it("formats category without sub-type (DPS)", () => {
    expect(
      generateSynergyName({
        type: "dps",
        subType: null,
        linkDisplayName: FIXTURE_LINK_DISPLAY,
      }),
    ).toBe(FIXTURE_AUTO_NAMES.dps);
  });

  it.each([
    ["solo", FIXTURE_AUTO_NAMES.solo],
    ["damage_resist", FIXTURE_AUTO_NAMES.damageResist],
    ["general_weapon", FIXTURE_AUTO_NAMES.generalWeapon],
    ["team", FIXTURE_AUTO_NAMES.team],
  ] as const)("formats %s without sub-type", (type, expected) => {
    expect(
      generateSynergyName({
        type,
        subType: null,
        linkDisplayName: FIXTURE_LINK_DISPLAY,
      }),
    ).toBe(expected);
  });

  it("truncates long link names preserving category and sub-type", () => {
    const longLink = "A".repeat(200);
    const name = generateSynergyName({
      type: "verb",
      subType: "Scorch",
      linkDisplayName: longLink,
    });
    expect(name.length).toBeLessThanOrEqual(120);
    expect(name.startsWith("Verb: Scorch —")).toBe(true);
    expect(name.endsWith("…")).toBe(true);
  });
});
